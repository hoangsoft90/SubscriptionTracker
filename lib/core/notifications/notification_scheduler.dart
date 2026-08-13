import 'dart:convert';

import '../../features/settings/data/settings_repository.dart';
import '../../features/subscriptions/domain/billing_cycle.dart';
import '../../features/subscriptions/domain/subscription.dart';
import '../../features/subscriptions/domain/subscription_status.dart';
import '../calendar/date_utils.dart';
import 'ids.dart';
import 'notification_platform.dart';

/// The 7-step reconciliation scheduler (spec §2.4).
///
/// 1. load active subscriptions
/// 2. generate reminder events for the next [horizon] (14 days)
/// 3. sort by trigger time, keeping same-time events as one group
/// 4. cap at [maxPending] (50 — iOS hard limit is 64)
/// 5. cancel the app's own previously scheduled IDs that are no longer wanted
/// 6. schedule the new event list (same IDs are replaced idempotently)
/// 7. persist scheduler state (the scheduled ID set) in `app_settings`
///
/// Delivery never relies on background refresh — the OS delivers scheduled
/// local notifications directly.
class NotificationScheduler {
  NotificationScheduler({
    required this.platform,
    required this.loadActive,
    required this.settings,
    this.horizon = const Duration(days: 14),
    this.maxPending = 50,
    this.reminderHour = 9,
    this.loadAll,
    this.updateSubscription,
  });

  final NotificationPlatform platform;
  final Future<List<Subscription>> Function() loadActive;
  final SettingsRepository settings;

  /// Loads *every* subscription (any status). Used only for the automatic
  /// PENDING_CANCELLATION → CANCELLED transition (plan2_final §5). When null,
  /// the lifecycle scan is skipped (e.g. tests that don't need it).
  final Future<List<Subscription>> Function()? loadAll;

  /// Persists a transitioned subscription. When null, transitions are
  /// computed but not persisted (must be wired to the repository in prod).
  final Future<void> Function(Subscription)? updateSubscription;

  /// How far ahead billing reminders are generated (spec §2.4: 7–14 days).
  final Duration horizon;

  /// Maximum pending notifications (iOS hard limit 64; we buffer at 50).
  final int maxPending;

  /// Local hour of day at which reminders fire (e.g. 09:00).
  final int reminderHour;

  static const _stateKey = 'notifScheduledIds';

  /// Runs one reconciliation pass and returns the events that were scheduled.
  Future<List<ReminderEvent>> reconcile({DateTime? now}) async {
    final current = now ?? DateTime.now();
    final anchor = DateUtils.localMidnight(current);
    await _transitionExpiredPendingCancellations(anchor, current);
    final subs = await loadActive();
    final events = <ReminderEvent>[];
    for (final sub in subs) {
      events.addAll(_billingEvents(sub, anchor, current));
      events.addAll(_trialEvents(sub, anchor, current));
    }

    // Sort by trigger time; same-time events keep a stable secondary order so
    // the cap never splits a same-time group (spec §2.4).
    events.sort((a, b) {
      final byTime = a.triggerAt.compareTo(b.triggerAt);
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });

    final scheduled = _capGroups(events, maxPending);
    final newIds = {for (final e in scheduled) e.id};
    final oldIds = await _loadScheduledIds();

    // Step 5: cancel stale own IDs.
    for (final id in oldIds) {
      if (!newIds.contains(id)) {
        await platform.cancel(id);
      }
    }
    // Step 6: (re-)schedule the new list — same IDs replace pending ones.
    for (final e in scheduled) {
      await platform.schedule(
        id: e.id,
        title: e.title,
        body: e.body,
        when: e.triggerAt,
      );
    }
    // Step 7: persist scheduler state.
    await settings.set(_stateKey, jsonEncode(newIds.toList()));
    return scheduled;
  }

  /// Billing reminders: every billing occurrence within the horizon, firing
  /// at [reminderHour] on the billing day.
  List<ReminderEvent> _billingEvents(
    Subscription sub,
    DateTime anchor,
    DateTime current,
  ) {
    final events = <ReminderEvent>[];
    if (sub.status != SubscriptionStatus.active) return events;
    final end = anchor.add(horizon);
    var date = DateUtils.localMidnight(sub.nextBillingDate);
    // Never remind for a billing date that has already passed.
    if (date.isBefore(anchor)) {
      date = _nextOccurrence(sub, anchor);
    }
    var guard = 0;
    while (!date.isAfter(end) && guard < 500) {
      final triggerAt = _atHour(date);
      if (!triggerAt.isBefore(current)) {
        events.add(ReminderEvent(
          subscriptionId: sub.id,
          triggerAt: triggerAt,
          type: ReminderType.billing,
          title: '${sub.name} renews soon',
          body: '${sub.name} — reminder before your next charge.',
        ));
      }
      date = _nextOccurrence(sub, date);
      guard++;
    }
    return events;
  }

  /// Trial Shield (spec §2.5): two reminders derived strictly from
  /// `trialEndDate` (+2 days, +0 days), independent of `nextBillingDate`; no
  /// reminders once the trial has ended. `cancellationUrl` is non-gating.
  List<ReminderEvent> _trialEvents(
    Subscription sub,
    DateTime anchor,
    DateTime current,
  ) {
    if (!sub.isTrial || sub.trialEndDate == null) return const [];
    final end = DateUtils.localMidnight(sub.trialEndDate!);
    if (!end.isAfter(anchor)) return const []; // expired → no reminders
    final events = <ReminderEvent>[];
    final twoDaysBefore = _atHour(end.subtract(const Duration(days: 2)));
    final onDay = _atHour(end);
    if (!twoDaysBefore.isBefore(current)) {
      events.add(ReminderEvent(
        subscriptionId: sub.id,
        triggerAt: twoDaysBefore,
        type: ReminderType.trialTwoDaysBefore,
        title: 'Your ${sub.name} trial ends in 2 days',
        body: 'Your ${sub.name} free trial ends soon. Review it before you '
            'are charged.',
      ));
    }
    if (!onDay.isBefore(current)) {
      events.add(ReminderEvent(
        subscriptionId: sub.id,
        triggerAt: onDay,
        type: ReminderType.trialEndDay,
        title: 'Your ${sub.name} trial ends today',
        body: 'Today is the last day of your ${sub.name} trial.',
      ));
    }
    return events;
  }

  /// Next billing occurrence strictly after [current] for [sub].
  DateTime _nextOccurrence(Subscription sub, DateTime current) {
    final cycle = sub.billingCycle;
    if (cycle == BillingCycle.custom) {
      final days = sub.customIntervalDays ?? 30;
      return DateTime(current.year, current.month, current.day + days);
    }
    // Weekly/interval cycles advance from the billing date itself. Monthly/
    // quarterly/yearly preserve the anchor day.
    switch (cycle) {
      case BillingCycle.weekly:
        return DateTime(current.year, current.month, current.day + 7);
      case BillingCycle.monthly:
        return DateUtils.addMonthsClamped(
          current,
          1,
          anchorDay: sub.billingAnchorDay > 0
              ? sub.billingAnchorDay
              : current.day,
        );
      case BillingCycle.quarterly:
        return DateUtils.addMonthsClamped(
          current,
          3,
          anchorDay: sub.billingAnchorDay > 0
              ? sub.billingAnchorDay
              : current.day,
        );
      case BillingCycle.yearly:
        return DateUtils.addMonthsClamped(
          current,
          12,
          anchorDay: sub.billingAnchorDay > 0
              ? sub.billingAnchorDay
              : current.day,
        );
      case BillingCycle.custom:
        return DateTime(current.year, current.month, current.day + 30);
    }
  }

  DateTime _atHour(DateTime date) =>
      DateTime(date.year, date.month, date.day, reminderHour);

  /// Caps [sorted] at [max] events without splitting a same-time group: if
  /// the event at the boundary shares a trigger time with the previous
  /// included event, it is kept too.
  List<ReminderEvent> _capGroups(List<ReminderEvent> sorted, int max) {
    if (sorted.length <= max) return sorted;
    final result = <ReminderEvent>[];
    for (final e in sorted) {
      if (result.length >= max) {
        if (result.last.triggerAt == e.triggerAt) {
          result.add(e); // keep the same-time group whole
        } else {
          break;
        }
      } else {
        result.add(e);
      }
    }
    return result;
  }

  /// Automatic lifecycle transition (plan2_final §5): any subscription in
  /// PENDING_CANCELLATION whose billing date has passed becomes CANCELLED,
  /// with `cancelledAt` = that billing date. Runs as part of every reconcile
  /// pass — no manual step, no separate background job.
  Future<void> _transitionExpiredPendingCancellations(
    DateTime anchor,
    DateTime current,
  ) async {
    final loadAll = this.loadAll;
    final persist = updateSubscription;
    if (loadAll == null || persist == null) return;
    final all = await loadAll();
    for (final sub in all) {
      if (sub.status != SubscriptionStatus.pendingCancellation) continue;
      if (!sub.nextBillingDate.isBefore(anchor)) continue; // still within cycle
      await persist(sub.copyWith(
        status: SubscriptionStatus.cancelled,
        cancelledAt: sub.nextBillingDate,
        updatedAt: current,
      ));
    }
  }

  Future<Set<int>> _loadScheduledIds() async {
    final raw = await settings.get(_stateKey);
    if (raw == null) return {};
    try {
      final list = jsonDecode(raw) as List;
      return {for (final e in list) e as int};
    } catch (_) {
      return {}; // corrupt state → full reschedule next time
    }
  }
}
