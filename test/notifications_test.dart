import 'package:flutter_test/flutter_test.dart';

import 'package:subtrack/core/notifications/coordinator.dart';
import 'package:subtrack/core/notifications/ids.dart';
import 'package:subtrack/core/notifications/notification_platform.dart';
import 'package:subtrack/core/notifications/notification_scheduler.dart';
import 'package:subtrack/core/notifications/permission.dart';
import 'package:subtrack/features/subscriptions/domain/billing_cycle.dart';
import 'package:subtrack/features/subscriptions/domain/subscription.dart';
import 'package:subtrack/features/subscriptions/domain/subscription_status.dart';

import 'fakes.dart';

// Fixed "now" so tests are deterministic (spec scenario dates around 2026-08).
final _now = DateTime(2026, 8, 10, 12, 0);

Subscription _sub({
  String id = 's1',
  String name = 'Netflix',
  DateTime? nextBilling,
  bool isTrial = false,
  DateTime? trialEnd,
  SubscriptionStatus status = SubscriptionStatus.active,
  BillingCycle cycle = BillingCycle.monthly,
}) {
  return Subscription(
    id: id,
    name: name,
    amountMinor: 1499,
    currency: 'USD',
    billingCycle: cycle,
    startDate: DateTime(2026, 7, 1),
    nextBillingDate: nextBilling ?? DateTime(2026, 8, 15),
    billingAnchorDay: 1,
    isTrial: isTrial,
    trialEndDate: trialEnd,
    status: status,
    createdAt: DateTime(2026, 7, 1),
    updatedAt: DateTime(2026, 7, 1),
  );
}

/// One scheduler over a *mutable* subscription list + shared fakes, so state
/// (persisted scheduled IDs) carries across reconciles like in production.
(NotificationScheduler, FakeNotificationPlatform, FakeSettingsRepository,
    List<Subscription>) _makeScheduler(
  List<Subscription> initial, {
  int maxPending = 50,
  Duration horizon = const Duration(days: 14),
}) {
  final subs = [...initial];
  final platform = FakeNotificationPlatform();
  final settings = FakeSettingsRepository();
  final scheduler = NotificationScheduler(
    platform: platform,
    loadActive: () async => List.unmodifiable(subs),
    settings: settings,
    maxPending: maxPending,
    horizon: horizon,
  );
  return (scheduler, platform, settings, subs);
}

void main() {
  group('Deterministic notification IDs (spec §2.4)', () {
    test('same event yields same ID', () {
      final a = ReminderEvent(
        subscriptionId: 'abc-123',
        triggerAt: DateTime(2026, 8, 15, 9),
        type: ReminderType.billing,
        title: 't',
        body: 'b',
      );
      final b = ReminderEvent(
        subscriptionId: 'abc-123',
        triggerAt: DateTime(2026, 8, 15, 9),
        type: ReminderType.billing,
        title: 't',
        body: 'b',
      );
      expect(a.id, b.id);
    });

    test('different dates/types yield different IDs', () {
      final e1 = ReminderEvent(
        subscriptionId: 'abc',
        triggerAt: DateTime(2026, 8, 15, 9),
        type: ReminderType.billing,
        title: '',
        body: '',
      );
      final e2 = ReminderEvent(
        subscriptionId: 'abc',
        triggerAt: DateTime(2026, 8, 16, 9),
        type: ReminderType.billing,
        title: '',
        body: '',
      );
      final e3 = ReminderEvent(
        subscriptionId: 'abc',
        triggerAt: DateTime(2026, 8, 15, 9),
        type: ReminderType.trialEndDay,
        title: '',
        body: '',
      );
      expect(e1.id, isNot(e2.id));
      expect(e1.id, isNot(e3.id));
      expect(e1.id, inInclusiveRange(0, 2147483646));
    });
  });

  group('reconcile()', () {
    test('schedules billing reminders inside the 14-day horizon at 09:00',
        () async {
      final (scheduler, platform, _, _) = _makeScheduler([
        _sub(nextBilling: DateTime(2026, 8, 15)),
      ]);
      final events = await scheduler.reconcile(now: _now);
      // Horizon = 8/10 + 14d = 8/24 → only 8/15 is inside.
      expect(events.length, 1);
      expect(platform.scheduled.first.when, DateTime(2026, 8, 15, 9));
    });

    test('weekly cycle advances every 7 days', () async {
      final (scheduler, platform, _, _) = _makeScheduler([
        _sub(cycle: BillingCycle.weekly, nextBilling: DateTime(2026, 8, 12)),
      ]);
      await scheduler.reconcile(now: _now);
      // 8/12, 8/19 inside the horizon; 8/26 is beyond 8/24.
      expect(platform.scheduled.length, 2);
      expect(platform.scheduled[1].when, DateTime(2026, 8, 19, 9));
    });

    test('edit that moves the billing date cancels the old ID', () async {
      final (scheduler, platform, _, subs) =
          _makeScheduler([_sub(nextBilling: DateTime(2026, 8, 15))]);
      final first = await scheduler.reconcile(now: _now);
      final oldIds = {for (final e in first) e.id};

      // Edit: billing moves to 8/20 (same id, same scheduler, shared state).
      subs[0] = _sub(nextBilling: DateTime(2026, 8, 20));
      final second = await scheduler.reconcile(now: _now);
      final newIds = {for (final e in second) e.id};

      // The stale (15th) ID must have been cancelled; the new date scheduled.
      expect(platform.cancelled, containsAll(oldIds));
      expect(platform.pending.keys, isNot(containsAll(oldIds)));
      expect(platform.pending.values, contains(DateTime(2026, 8, 20, 9)));
      expect(newIds, isNot(oldIds));
    });

    test('delete cancels all its notification IDs (no stale remains)',
        () async {
      final (scheduler, platform, _, subs) = _makeScheduler([
        _sub(id: 'a', nextBilling: DateTime(2026, 8, 15)),
        _sub(id: 'b', nextBilling: DateTime(2026, 8, 20)),
      ]);
      final first = await scheduler.reconcile(now: _now);
      final idsOfB = {
        for (final e in first)
          if (e.subscriptionId == 'b') e.id,
      };
      expect(idsOfB, isNotEmpty);

      // Delete b.
      subs.removeWhere((s) => s.id == 'b');
      await scheduler.reconcile(now: _now);
      expect(platform.cancelled, containsAll(idsOfB));
      expect(platform.pending.keys, isNot(containsAll(idsOfB)));
    });

    test('cancelled/archived subscriptions produce no reminders', () async {
      final (scheduler, platform, _, _) = _makeScheduler([
        _sub(status: SubscriptionStatus.cancelled),
        _sub(id: 'arch', status: SubscriptionStatus.archived),
      ]);
      final events = await scheduler.reconcile(now: _now);
      expect(events, isEmpty);
      expect(platform.scheduled, isEmpty);
    });

    test('cap keeps only the first 50 events by trigger time', () async {
      // 60 subscriptions, one monthly billing each, all with DISTINCT dates
      // inside a long horizon → 60 events → capped at 50.
      final subs = [
        for (var i = 0; i < 60; i++)
          _sub(id: 's$i', nextBilling: DateTime(2026, 8, 11 + i)),
      ];
      final (scheduler, platform, settings, _) = _makeScheduler(
        subs,
        horizon: const Duration(days: 60),
      );
      final events = await scheduler.reconcile(now: _now);
      expect(events.length, 50);
      expect(platform.scheduled.length, 50);
      // Sorted by trigger time.
      for (var i = 1; i < events.length; i++) {
        expect(
          events[i].triggerAt.isBefore(events[i - 1].triggerAt),
          isFalse,
        );
      }
      // State persisted.
      expect(
        await settings.get('notifScheduledIds'),
        contains('[${events.first.id}'),
      );
    });

    test('same-time events are kept together at the cap boundary', () async {
      // 33 distinct-time events + 20 events sharing one trigger time (8/14).
      final subs = [
        for (var i = 0; i < 33; i++)
          _sub(id: 'a$i', nextBilling: DateTime(2026, 8, 12 + (i % 2))),
        for (var i = 0; i < 20; i++)
          _sub(id: 'g$i', nextBilling: DateTime(2026, 8, 14)),
      ];
      final (scheduler, platform, _, _) = _makeScheduler(subs);
      final events = await scheduler.reconcile(now: _now);
      // The 8/14 group straddles the 50 boundary; it must be kept whole, so
      // all 53 events are scheduled rather than splitting the group.
      final onBoundary =
          events.where((e) => e.triggerAt == DateTime(2026, 8, 14, 9)).length;
      expect(onBoundary, 20);
      expect(platform.scheduled.length, 53);
    });

    test('reconcile is idempotent — same input produces the same schedule',
        () async {
      final subs = [_sub(nextBilling: DateTime(2026, 8, 15))];
      final (s1, p1, _, _) = _makeScheduler(subs);
      final (s2, p2, _, _) = _makeScheduler(subs);
      final e1 = await s1.reconcile(now: _now);
      final e2 = await s2.reconcile(now: _now);
      expect([for (final e in e1) e.id], [for (final e in e2) e.id]);
      expect(
        [for (final e in p1.scheduled) e.id],
        [for (final e in p2.scheduled) e.id],
      );
    });
  });

  group('Trial Shield (spec §2.5)', () {
    test('two reminders: 2 days before + on trial end day', () async {
      final (scheduler, platform, _, _) = _makeScheduler([
        _sub(id: 't1', isTrial: true, trialEnd: DateTime(2026, 8, 20)),
      ]);
      await scheduler.reconcile(now: _now);
      final trialTriggers = platform.scheduled
          .where((e) =>
              e.when == DateTime(2026, 8, 18, 9) ||
              e.when == DateTime(2026, 8, 20, 9))
          .length;
      expect(trialTriggers, 2);
    });

    test('expired trial has no trial reminders', () async {
      final (scheduler, platform, _, _) = _makeScheduler([
        _sub(id: 't2', isTrial: true, trialEnd: DateTime(2026, 8, 1)),
      ]);
      final events = await scheduler.reconcile(now: _now);
      // Only the billing reminder may exist — never a trial one.
      expect(
        events.where((e) => e.type != ReminderType.billing),
        isEmpty,
      );
      expect(platform.scheduled.length, lessThanOrEqualTo(1));
    });

    test('non-trial subscriptions produce no trial reminders', () async {
      final (scheduler, platform, _, _) =
          _makeScheduler([_sub(isTrial: false)]);
      final events = await scheduler.reconcile(now: _now);
      expect(
        events.where((e) => e.type != ReminderType.billing),
        isEmpty,
      );
    });

    test('trial reminders are independent of nextBillingDate', () async {
      // Trial ends 8/20 while billing is 9/15 — reminders must follow the
      // trial dates, not the billing date.
      final (scheduler, platform, _, _) = _makeScheduler([
        _sub(
          id: 't3',
          isTrial: true,
          trialEnd: DateTime(2026, 8, 20),
          nextBilling: DateTime(2026, 9, 15),
        ),
      ]);
      await scheduler.reconcile(now: _now);
      final trialTriggers = platform.scheduled
          .where((e) =>
              e.when == DateTime(2026, 8, 18, 9) ||
              e.when == DateTime(2026, 8, 20, 9))
          .length;
      expect(trialTriggers, 2);
    });
  });

  group('Permission timing (spec §2.4)', () {
    test('never requested before any subscription exists', () async {
      final platform = FakeNotificationPlatform();
      final service = NotificationPermissionService(
        platform,
        FakeSettingsRepository(),
      );
      expect(service, isNotNull);
      expect(platform.permissionRequested, isFalse);
    });

    test('requested once, then remembered', () async {
      final platform = FakeNotificationPlatform();
      final settings = FakeSettingsRepository();
      final service = NotificationPermissionService(platform, settings);

      expect(await service.requestIfNeeded(), isTrue);
      expect(platform.permissionRequested, isTrue);

      // A later call must NOT re-prompt.
      await service.requestIfNeeded();
      expect(platform.permissionRequested, isTrue);
    });

    test('status() reports the OS permission state without prompting',
        () async {
      final platform = FakeNotificationPlatform();
      final service =
          NotificationPermissionService(platform, FakeSettingsRepository());

      platform.status = NotificationPermissionStatus.disabled;
      expect(await service.status(), NotificationPermissionStatus.disabled);
      // Reading status never triggers the OS prompt.
      expect(platform.permissionRequested, isFalse);

      platform.status = NotificationPermissionStatus.enabled;
      expect(await service.status(), NotificationPermissionStatus.enabled);
      expect(platform.permissionRequested, isFalse);
    });

    test('enableFromSettings prompts on first use, opens settings after',
        () async {
      final platform = FakeNotificationPlatform();
      final settings = FakeSettingsRepository();
      final service = NotificationPermissionService(platform, settings);

      // Never asked before → show the OS prompt.
      var prompted = await service.enableFromSettings();
      expect(prompted, isTrue);
      expect(platform.permissionRequested, isTrue);
      expect(platform.settingsOpened, isFalse);

      // Asked before (user denied) → OS usually stops re-prompting; open the
      // system notification settings screen instead.
      platform.permissionGranted = false;
      platform.status = NotificationPermissionStatus.disabled;
      prompted = await service.enableFromSettings();
      expect(prompted, isFalse);
      expect(platform.settingsOpened, isTrue);
      expect(platform.permissionRequested, isTrue); // no second prompt
    });
  });

  group('Lifecycle auto-transition (plan2_final §5)', () {
    (NotificationScheduler, List<Subscription>) makeLifecycleScheduler(
        List<Subscription> initial) {
      final subs = [...initial];
      final platform = FakeNotificationPlatform();
      final settings = FakeSettingsRepository();
      final scheduler = NotificationScheduler(
        platform: platform,
        loadActive: () async => List.unmodifiable(
          subs.where((s) => s.status == SubscriptionStatus.active),
        ),
        settings: settings,
        loadAll: () async => List.unmodifiable(subs),
        updateSubscription: (updated) async {
          final i = subs.indexWhere((s) => s.id == updated.id);
          if (i >= 0) subs[i] = updated;
        },
      );
      return (scheduler, subs);
    }

    test('expired PENDING_CANCELLATION becomes CANCELLED with cancelledAt '
        '= its billing date', () async {
      final (scheduler, subs) = makeLifecycleScheduler([
        _sub(
          id: 'pc',
          name: 'Adobe',
          status: SubscriptionStatus.pendingCancellation,
          nextBilling: DateTime(2026, 8, 5), // passed (now 8/10)
        ),
      ]);
      await scheduler.reconcile(now: _now);

      final transitioned = subs.single;
      expect(transitioned.status, SubscriptionStatus.cancelled);
      expect(transitioned.cancelledAt, DateTime(2026, 8, 5));
    });

    test('PENDING_CANCELLATION within its paid cycle is left alone',
        () async {
      final (scheduler, subs) = makeLifecycleScheduler([
        _sub(
          id: 'keep',
          status: SubscriptionStatus.pendingCancellation,
          nextBilling: DateTime(2026, 8, 20), // still in the future
        ),
      ]);
      await scheduler.reconcile(now: _now);

      expect(subs.single.status, SubscriptionStatus.pendingCancellation);
      expect(subs.single.cancelledAt, isNull);
    });

    test('ACTIVE and CANCELLED subscriptions are never touched', () async {
      final (scheduler, subs) = makeLifecycleScheduler([
        _sub(id: 'a', nextBilling: DateTime(2026, 8, 5)),
        _sub(
          id: 'c',
          status: SubscriptionStatus.cancelled,
          nextBilling: DateTime(2026, 8, 5),
        ),
      ]);
      await scheduler.reconcile(now: _now);

      expect(subs[0].status, SubscriptionStatus.active);
      expect(subs[1].status, SubscriptionStatus.cancelled);
      expect(subs[1].cancelledAt, isNull);
    });
  });

  group('Coordinator triggers', () {
    test('app open reconciles and persists the timezone', () async {
      var tz = 'Asia/Ho_Chi_Minh';
      final (scheduler, platform, settings, _) =
          _makeScheduler([_sub(nextBilling: DateTime(2026, 8, 15))]);

      // Each app launch creates a fresh coordinator (one-shot onAppOpen).
      NotificationCoordinator launch() => NotificationCoordinator(
            scheduler: scheduler,
            permission: NotificationPermissionService(platform, settings),
            settings: settings,
            currentTimezone: () async => tz,
          );

      await launch().onAppOpen();
      expect(await settings.get('lastTimeZone'), 'Asia/Ho_Chi_Minh');
      expect(platform.scheduled, isNotEmpty);

      // Travel: device timezone changed → new launch persists it and
      // re-reconciles (spec §2.4 timezone scenario).
      tz = 'America/New_York';
      await launch().onAppOpen();
      expect(await settings.get('lastTimeZone'), 'America/New_York');
      expect(platform.scheduled.length, 2);
    });

    test('onAppOpen is guarded to run once per process', () async {
      final (scheduler, platform, settings, _) =
          _makeScheduler([_sub(nextBilling: DateTime(2026, 8, 15))]);
      final coordinator = NotificationCoordinator(
        scheduler: scheduler,
        permission: NotificationPermissionService(platform, settings),
        settings: settings,
        currentTimezone: () async => 'UTC',
      );
      await coordinator.onAppOpen();
      final count = platform.scheduled.length;
      await coordinator.onAppOpen(); // no-op — already handled
      expect(platform.scheduled.length, count);
    });

    test('subscription change triggers a reconcile', () async {
      final (scheduler, platform, settings, _) =
          _makeScheduler([_sub(nextBilling: DateTime(2026, 8, 15))]);
      final coordinator = NotificationCoordinator(
        scheduler: scheduler,
        permission: NotificationPermissionService(platform, settings),
        settings: settings,
        currentTimezone: () async => 'UTC',
      );
      await coordinator.onSubscriptionsChanged();
      expect(platform.scheduled, isNotEmpty);
    });
  });
}
