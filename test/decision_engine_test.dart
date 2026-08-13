import 'package:flutter_test/flutter_test.dart';

import 'package:subtrack/core/calendar/date_utils.dart';
import 'package:subtrack/features/calendar/money_calendar.dart';
import 'package:subtrack/features/decision/review_queue.dart';
import 'package:subtrack/features/decision/savings.dart';
import 'package:subtrack/features/decision/today_brief.dart';
import 'package:subtrack/features/subscriptions/domain/billing_cycle.dart';
import 'package:subtrack/features/subscriptions/domain/subscription.dart';
import 'package:subtrack/features/subscriptions/domain/subscription_status.dart';

// Fixed "now" for deterministic tests (plan2_final scenarios around 2026-08).
final _now = DateTime(2026, 8, 10, 12, 0);

Subscription _sub({
  String id = 's1',
  String name = 'Netflix',
  int amount = 1499,
  String currency = 'USD',
  BillingCycle cycle = BillingCycle.monthly,
  DateTime? nextBilling,
  SubscriptionStatus status = SubscriptionStatus.active,
  bool isTrial = false,
  DateTime? trialEnd,
  DateTime? lastReviewedAt,
  int reviewIntervalDays = 90,
  DateTime? cancelledAt,
  int? previousAmountMinor,
  DateTime? supersededAt,
  int? billingAnchorDay,
  int? customIntervalDays,
}) {
  final effectiveNextBilling = nextBilling ?? DateTime(2026, 8, 15);
  return Subscription(
    id: id,
    name: name,
    amountMinor: amount,
    currency: currency,
    billingCycle: cycle,
    customIntervalDays: customIntervalDays,
    startDate: DateTime(2026, 7, 1),
    nextBillingDate: effectiveNextBilling,
    // Production invariant (add-edit screen): anchor = startDate.day and
    // nextBillingDate is derived from it — keep fixtures consistent so the
    // calendar walk-back (which honors the anchor) is deterministic.
    billingAnchorDay: billingAnchorDay ?? effectiveNextBilling.day,
    isTrial: isTrial,
    trialEndDate: trialEnd,
    status: status,
    createdAt: DateTime(2026, 7, 1),
    updatedAt: DateTime(2026, 7, 1),
    lastReviewedAt: lastReviewedAt,
    reviewIntervalDays: reviewIntervalDays,
    cancelledAt: cancelledAt,
    previousAmountMinor: previousAmountMinor,
    supersededAt: supersededAt,
  );
}

void main() {
  group('Today Money Brief (plan2_final §2)', () {
    test('nothing due → clear state', () {
      final brief = const TodayBriefService().compute(
        subscriptions: [_sub(nextBilling: DateTime(2026, 9, 1))],
        now: _now,
      );
      expect(brief.clear, isFalse); // a future renewal still shows Next
      expect(brief.nextRenewal, isNotNull);
    });

    test('no renewals or trials at all → clear', () {
      final brief = const TodayBriefService().compute(
        subscriptions: [
          _sub(
            status: SubscriptionStatus.cancelled,
            nextBilling: DateTime(2026, 8, 15),
          ),
        ],
        now: _now,
      );
      expect(brief.clear, isTrue);
    });

    test('next renewal picks the earliest future date', () {
      final brief = const TodayBriefService().compute(
        subscriptions: [
          _sub(id: 'a', name: 'A', nextBilling: DateTime(2026, 8, 20)),
          _sub(id: 'b', name: 'B', nextBilling: DateTime(2026, 8, 12)),
          _sub(id: 'c', name: 'C', nextBilling: DateTime(2026, 8, 30)),
        ],
        now: _now,
      );
      expect(brief.nextRenewal?.id, 'b');
      expect(brief.nextRenewalInDays, 2);
    });

    test('trial ending within 3 days surfaces a warning', () {
      final brief = const TodayBriefService().compute(
        subscriptions: [
          _sub(
            id: 't',
            name: 'Canva',
            isTrial: true,
            trialEnd: DateTime(2026, 8, 12),
          ),
        ],
        now: _now,
      );
      expect(brief.trialEnding?.id, 't');
      expect(brief.trialEndingInDays, 2);
    });

    test('billing today → hasEventToday', () {
      final brief = const TodayBriefService().compute(
        subscriptions: [_sub(nextBilling: DateTime(2026, 8, 10))],
        now: _now,
      );
      expect(brief.hasEventToday, isTrue);
    });
  });

  group('Review Queue (plan2_final §3)', () {
    test('trial ending ≤3d is high priority', () {
      final queue = const ReviewQueueService().compute(
        subscriptions: [
          _sub(
            id: 't',
            name: 'Canva',
            isTrial: true,
            trialEnd: DateTime(2026, 8, 12),
          ),
        ],
        now: _now,
      );
      expect(queue.single.priority, ReviewPriority.high);
      expect(queue.single.reason, ReviewReason.trialEnding);
    });

    test('renewal within 1 day is high priority', () {
      final queue = const ReviewQueueService().compute(
        subscriptions: [
          _sub(id: 'r', name: 'R', nextBilling: DateTime(2026, 8, 11)),
        ],
        now: _now,
      );
      expect(queue.single.reason, ReviewReason.renewalDue);
      expect(queue.single.priority, ReviewPriority.high);
    });

    test('unacknowledged price change is medium', () {
      final queue = const ReviewQueueService().compute(
        subscriptions: [
          _sub(id: 'p', name: 'P', previousAmountMinor: 999),
        ],
        now: _now,
      );
      expect(queue.single.reason, ReviewReason.priceChanged);
      expect(queue.single.priority, ReviewPriority.medium);
    });

    test('stale detection boundary at 90 days', () {
      // 89 days → not stale; 91 days → stale.
      final fresh = const ReviewQueueService().compute(
        subscriptions: [
          _sub(
            id: 'ok',
            name: 'Ok',
            lastReviewedAt: _now.subtract(const Duration(days: 89)),
          ),
        ],
        now: _now,
      );
      expect(fresh, isEmpty);

      final stale = const ReviewQueueService().compute(
        subscriptions: [
          _sub(
            id: 'old',
            name: 'Old',
            lastReviewedAt: _now.subtract(const Duration(days: 91)),
          ),
        ],
        now: _now,
      );
      expect(stale.single.reason, ReviewReason.stale);
      expect(stale.single.priority, ReviewPriority.medium);
    });

    test('priority ordering: high before medium', () {
      final queue = const ReviewQueueService().compute(
        subscriptions: [
          _sub(id: 'm', name: 'M', lastReviewedAt: _now.subtract(const Duration(days: 200))),
          _sub(id: 'h', name: 'H', isTrial: true, trialEnd: DateTime(2026, 8, 11)),
        ],
        now: _now,
      );
      expect(queue.first.subscription.id, 'h');
      expect(queue.last.subscription.id, 'm');
    });

    test('hidden ids (Later) are excluded', () {
      final queue = const ReviewQueueService().compute(
        subscriptions: [
          _sub(id: 'h', name: 'H', isTrial: true, trialEnd: DateTime(2026, 8, 11)),
        ],
        now: _now,
        hiddenIds: {'h'},
      );
      expect(queue, isEmpty);
    });

    test('cancelled/archived never appear in the queue', () {
      final queue = const ReviewQueueService().compute(
        subscriptions: [
          _sub(id: 'c', name: 'C', status: SubscriptionStatus.cancelled),
          _sub(id: 'a', name: 'A', status: SubscriptionStatus.archived),
          _sub(
            id: 'p',
            name: 'P',
            status: SubscriptionStatus.pendingCancellation,
            isTrial: true,
            trialEnd: DateTime(2026, 8, 11),
          ),
        ],
        now: _now,
      );
      expect(queue, isEmpty);
    });
  });

  group('Savings Counter (plan2_final §4)', () {
    test('projected = monthly-equivalent of pending + cancelled', () {
      final result = const SavingsCalculator().compute(
        subscriptions: [
          _sub(id: 'a', name: 'A', amount: 1000), // active → baseline only
          _sub(
            id: 'p',
            name: 'P',
            amount: 2000,
            status: SubscriptionStatus.pendingCancellation,
          ),
          _sub(
            id: 'c',
            name: 'C',
            amount: 3000,
            status: SubscriptionStatus.cancelled,
            cancelledAt: DateTime(2026, 8, 1),
          ),
        ],
        now: _now,
      );
      expect(result.projectedMonthly['USD'], 5000);
      expect(result.preCancellationMonthly['USD'], 6000);
    });

    test('superseded cancelled subscription stops projecting', () {
      final result = const SavingsCalculator().compute(
        subscriptions: [
          _sub(
            id: 'c',
            name: 'Netflix',
            amount: 3000,
            status: SubscriptionStatus.cancelled,
            cancelledAt: DateTime(2026, 6, 1),
            supersededAt: DateTime(2026, 7, 1),
          ),
        ],
        now: _now,
      );
      expect(result.projectedMonthly['USD'] ?? 0, 0);
      expect(result.realized['USD'] ?? 0, 0);
    });

    test('realized counts completed monthly cycles after cancelledAt', () {
      // Cancelled 2026-06-15; now 2026-08-10 → one completed cycle
      // (7/15 has passed, 8/15 hasn't), realized = 1500 × 1.
      final result = const SavingsCalculator().compute(
        subscriptions: [
          _sub(
            id: 'c',
            name: 'C',
            amount: 1500,
            status: SubscriptionStatus.cancelled,
            cancelledAt: DateTime(2026, 6, 15),
          ),
        ],
        now: _now,
      );
      expect(result.realized['USD'], 1500);
    });

    test('realized is zero before the cancelled billing date', () {
      final result = const SavingsCalculator().compute(
        subscriptions: [
          _sub(
            id: 'c',
            name: 'C',
            amount: 1500,
            status: SubscriptionStatus.cancelled,
            cancelledAt: DateTime(2026, 8, 15),
          ),
        ],
        now: _now,
      );
      expect(result.realized['USD'] ?? 0, 0);
    });

    test('mixed currencies stay grouped', () {
      final result = const SavingsCalculator().compute(
        subscriptions: [
          _sub(
            id: 'a',
            name: 'A',
            amount: 1000,
            status: SubscriptionStatus.cancelled,
            cancelledAt: DateTime(2026, 6, 1),
          ),
          _sub(
            id: 'b',
            name: 'B',
            amount: 20000,
            currency: 'VND',
            status: SubscriptionStatus.cancelled,
            cancelledAt: DateTime(2026, 6, 1),
          ),
        ],
        now: _now,
      );
      expect(result.projectedMonthly.keys, containsAll(['USD', 'VND']));
      expect(result.projectedMonthly['USD'], 1000);
      expect(result.projectedMonthly['VND'], 20000);
    });

    test('weekly subscription projected monthly = amount × 52 / 12', () {
      final result = const SavingsCalculator().compute(
        subscriptions: [
          _sub(
            id: 'w',
            name: 'W',
            amount: 100,
            cycle: BillingCycle.weekly,
            status: SubscriptionStatus.cancelled,
          ),
        ],
        now: _now,
      );
      // 100 × 52 = 5200 yearly → ~433/month (integer division).
      expect(result.projectedMonthly['USD'], 5200 ~/ 12);
    });
  });

  group('Money Calendar (plan2_final §6)', () {
    test('one dot per day regardless of renewal count', () {
      final data = const MoneyCalendarService().compute(
        subscriptions: [
          _sub(id: 'a', name: 'A', nextBilling: DateTime(2026, 8, 15)),
          _sub(id: 'b', name: 'B', nextBilling: DateTime(2026, 8, 15)),
        ],
        month: DateTime(2026, 8, 1),
        now: DateTime(2026, 8, 1),
      );
      expect(data.dotDays, {15});
      expect(data.chargesForDay(15).length, 2);
    });

    test('anchor-day month-end clamp appears on last day', () {
      // Anchor 31, next billing 2026-09-30 (clamped) — Sept has 30 days.
      final data = const MoneyCalendarService().compute(
        subscriptions: [
          _sub(
            id: 'a',
            name: 'A',
            nextBilling: DateTime(2026, 9, 30),
            billingAnchorDay: 31,
          ),
        ],
        month: DateTime(2026, 9, 1),
        now: DateTime(2026, 8, 1),
      );
      expect(data.dotDays, {30});
    });

    test('weekly cycle places multiple dots in one month', () {
      final data = const MoneyCalendarService().compute(
        subscriptions: [
          _sub(
            id: 'w',
            name: 'W',
            cycle: BillingCycle.weekly,
            nextBilling: DateTime(2026, 8, 3),
          ),
        ],
        month: DateTime(2026, 8, 1),
        now: DateTime(2026, 8, 1),
      );
      // 8/3, 8/10, 8/17, 8/24, 8/31.
      expect(data.dotDays, {3, 10, 17, 24, 31});
    });

    test('custom interval lands on computed days', () {
      final data = const MoneyCalendarService().compute(
        subscriptions: [
          _sub(
            id: 'c',
            name: 'C',
            cycle: BillingCycle.custom,
            customIntervalDays: 45,
            nextBilling: DateTime(2026, 8, 1),
          ),
        ],
        month: DateTime(2026, 8, 1),
        now: DateTime(2026, 8, 1),
      );
      // nextBilling 8/1 is a real charge today → dot on day 1; the following
      // occurrence (9/15) falls outside August, so no additional dots.
      expect(data.dotDays, {1});
    });

    test('past month shows the historical charge dot', () {
      // now = 2026-08-10; viewing July → the 7/15 charge must still show.
      final data = const MoneyCalendarService().compute(
        subscriptions: [
          _sub(id: 'a', name: 'A', nextBilling: DateTime(2026, 8, 15)),
        ],
        month: DateTime(2026, 7, 1),
        now: _now,
      );
      expect(data.dotDays, {15});
    });

    test('past charges earlier in the current month still show', () {
      // now = 2026-08-10; next billing 8/15 → the earlier 8/5 occurrence must
      // appear alongside it (full-month view, not a forecast).
      final data = const MoneyCalendarService().compute(
        subscriptions: [
          _sub(
            id: 'w',
            name: 'W',
            cycle: BillingCycle.weekly,
            nextBilling: DateTime(2026, 8, 5),
          ),
        ],
        month: DateTime(2026, 8, 1),
        now: _now,
      );
      expect(data.dotDays, {5, 12, 19, 26});
    });

    test('no charges before the subscription startDate', () {
      // Sub started 2026-07-01; viewing June must stay empty.
      final data = const MoneyCalendarService().compute(
        subscriptions: [
          _sub(id: 'a', name: 'A', nextBilling: DateTime(2026, 8, 15)),
        ],
        month: DateTime(2026, 6, 1),
        now: _now,
      );
      expect(data.dotDays, isEmpty);
    });

    test('future month after nextBillingDate still projects charges', () {
      // nextBilling 8/15; viewing October → 10/15 projected.
      final data = const MoneyCalendarService().compute(
        subscriptions: [
          _sub(id: 'a', name: 'A', nextBilling: DateTime(2026, 8, 15)),
        ],
        month: DateTime(2026, 10, 1),
        now: _now,
      );
      expect(data.dotDays, {15});
    });

    test('per-day totals never mix currencies', () {
      final data = const MoneyCalendarService().compute(
        subscriptions: [
          _sub(id: 'a', name: 'A', amount: 1000, nextBilling: DateTime(2026, 8, 15)),
          _sub(
            id: 'b',
            name: 'B',
            amount: 20000,
            currency: 'VND',
            nextBilling: DateTime(2026, 8, 15),
          ),
        ],
        month: DateTime(2026, 8, 1),
        now: DateTime(2026, 8, 1),
      );
      final totals = data.totalsForDay(15);
      expect(totals['USD'], 1000);
      expect(totals['VND'], 20000);
    });
  });

  group('DateUtils round-trip for new fields', () {
    test('parse/format new date fields', () {
      final d = DateUtils.parse('2026-08-10');
      expect(DateUtils.format(d), '2026-08-10');
    });
  });
}
