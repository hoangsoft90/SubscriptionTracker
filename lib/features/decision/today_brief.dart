import '../../../core/calendar/date_utils.dart';
import '../subscriptions/domain/subscription.dart';
import '../subscriptions/domain/subscription_status.dart';

/// Data backing the first Home card — the "Today" brief (plan2_final §2).
class TodayBrief {
  const TodayBrief({
    required this.clear,
    this.dueToday = const [],
    this.nextRenewal,
    this.nextRenewalInDays,
    this.trialEnding,
    this.trialEndingInDays,
    this.trialPriceLabel,
    this.hasEventToday = false,
  });

  /// True when nothing at all needs attention today ("You're clear").
  /// False as soon as any charge or trial event happens today.
  final bool clear;

  /// Active subscriptions billing today (rendered as "renews today" rows).
  final List<Subscription> dueToday;

  /// Earliest active renewal strictly after today (null → none).
  final Subscription? nextRenewal;

  /// Calendar-day distance of [nextRenewal] from today.
  final int? nextRenewalInDays;

  /// Active trial ending within 3 days (including today).
  final Subscription? trialEnding;

  /// Calendar-day distance of [trialEnding] from today.
  final int? trialEndingInDays;

  /// Post-trial price line ("$14.99/month after trial") — display-only text
  /// built by the caller; kept here so the card can be tested without widgets.
  final String? trialPriceLabel;

  /// Any charge or trial event happening today (drives "Nothing due today ✓").
  final bool hasEventToday;
}

/// Computes the Today brief from active subscriptions (plan2_final §2).
///
/// Calendar-local dates only — never UTC. Recomputes per app open, so a
/// timezone change is picked up on the next launch (same trigger as
/// `reconcile()`).
class TodayBriefService {
  const TodayBriefService();

  TodayBrief compute({
    required List<Subscription> subscriptions,
    required DateTime now,
  }) {
    final today = DateUtils.localMidnight(now);
    final active = subscriptions
        .where((s) => s.status == SubscriptionStatus.active)
        .toList();

    // Next renewal strictly after today.
    Subscription? nextRenewal;
    var nextRenewalInDays = 0;
    final dueToday = <Subscription>[];
    for (final sub in active) {
      final billing = DateUtils.localMidnight(sub.nextBillingDate);
      if (!billing.isBefore(today)) {
        if (billing == today) {
          dueToday.add(sub);
        } else {
          final days = billing.difference(today).inDays;
          if (nextRenewal == null || days < nextRenewalInDays) {
            nextRenewal = sub;
            nextRenewalInDays = days;
          }
        }
      }
    }

    // Trial ending within 3 days (including today).
    Subscription? trialEnding;
    var trialEndingInDays = 0;
    final trialEndsToday = <Subscription>[];
    for (final sub in active) {
      if (!sub.isTrial || sub.trialEndDate == null) continue;
      final end = DateUtils.localMidnight(sub.trialEndDate!);
      if (end.isBefore(today) || end.isAfter(today.add(const Duration(days: 3)))) {
        continue;
      }
      final days = end.difference(today).inDays;
      if (days == 0) {
        trialEndsToday.add(sub);
      }
      if (trialEnding == null || days < trialEndingInDays) {
        trialEnding = sub;
        trialEndingInDays = days;
      }
    }

    final hasEventToday = dueToday.isNotEmpty || trialEndsToday.isNotEmpty;
    // Not "clear" while anything charges/ends today — a renewal due today
    // must never show "You're clear" (device-test 2026-08-15).
    final clear =
        nextRenewal == null && trialEnding == null && !hasEventToday;

    return TodayBrief(
      clear: clear,
      dueToday: dueToday,
      nextRenewal: nextRenewal,
      nextRenewalInDays: clear ? null : nextRenewalInDays,
      trialEnding: trialEnding,
      trialEndingInDays: trialEnding == null ? null : trialEndingInDays,
      hasEventToday: hasEventToday,
    );
  }
}
