import '../../../core/calendar/date_utils.dart';
import '../subscriptions/domain/billing_cycle.dart';
import '../subscriptions/domain/billing_calculator.dart';
import '../subscriptions/domain/subscription.dart';
import '../subscriptions/domain/subscription_status.dart';

/// Charges for one displayed month (plan2_final §6): day-of-month → renewals.
class CalendarMonthData {
  const CalendarMonthData({required this.month, required this.chargesByDay});

  /// First day of the displayed month (local midnight).
  final DateTime month;

  /// Day-of-month → subscriptions renewing that day. A day appears at most
  /// once (one dot max regardless of how many renewals, plan2_final §6).
  final Map<int, List<Subscription>> chargesByDay;

  /// Days that carry a dot.
  Set<int> get dotDays => chargesByDay.keys.toSet();

  /// Total minor units per currency for [day] (never mixed).
  Map<String, int> totalsForDay(int day) {
    final totals = <String, int>{};
    for (final sub in chargesByDay[day] ?? const <Subscription>[]) {
      totals[sub.currency] = (totals[sub.currency] ?? 0) + sub.amountMinor;
    }
    return totals;
  }

  /// Renewals for [day] (empty when none).
  List<Subscription> chargesForDay(int day) =>
      chargesByDay[day] ?? const [];
}

/// Computes charge days for a displayed month (plan2_final §6).
///
/// Performance rule: only the visible month is computed — never the whole
/// year. For each active subscription, billing dates inside the month are
/// derived from the existing billing engine (anchor-day clamping, custom
/// intervals). One dot per day regardless of renewal count.
class MoneyCalendarService {
  const MoneyCalendarService();

  CalendarMonthData compute({
    required List<Subscription> subscriptions,
    required DateTime month,
    DateTime? now,
  }) {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);

    final chargesByDay = <int, List<Subscription>>{};
    for (final sub in subscriptions) {
      if (sub.status != SubscriptionStatus.active) continue;

      final subStart = DateUtils.localMidnight(sub.startDate);
      // Subscription didn't exist during this month → no charges to show.
      if (subStart.isAfter(last)) continue;

      // Anchor the walk at the last charge on/before the month start so
      // occurrences earlier in the month are found even when
      // nextBillingDate falls mid-month (plan2_final §6 — full month view
      // including past charges).
      var cursor = _firstOccurrenceOnOrBefore(sub, first);
      if (cursor.isBefore(first)) {
        cursor = BillingCalculator.nextBillingDate(
          current: cursor,
          cycle: sub.billingCycle,
          customIntervalDays: sub.customIntervalDays,
          billingAnchorDay: sub.billingAnchorDay > 0
              ? sub.billingAnchorDay
              : cursor.day,
        );
      }
      if (cursor.isAfter(last)) continue;

      // Collect every occurrence inside the month (weekly/custom can hit
      // several times). Past charges are shown too — the calendar renders the
      // whole month, not a forecast. Occurrences before the month start
      // (possible when nextBillingDate is far in the past) and before the
      // subscription existed (startDate) never appear.
      var guard = 0;
      while (!cursor.isAfter(last) && guard < 500) {
        guard++;
        if (!cursor.isBefore(first) && !cursor.isBefore(subStart)) {
          chargesByDay.putIfAbsent(cursor.day, () => []).add(sub);
        }
        cursor = BillingCalculator.nextBillingDate(
          current: cursor,
          cycle: sub.billingCycle,
          customIntervalDays: sub.customIntervalDays,
          billingAnchorDay: sub.billingAnchorDay > 0
              ? sub.billingAnchorDay
              : cursor.day,
        );
      }
    }

    return CalendarMonthData(
      month: first,
      chargesByDay: Map.fromEntries(
        chargesByDay.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key)),
      ),
    );
  }

  /// Last billing occurrence on or before [target], walking backwards via the
  /// billing engine (anchor-day aware).
  DateTime _firstOccurrenceOnOrBefore(Subscription sub, DateTime target) {
    var cursor = DateUtils.localMidnight(sub.nextBillingDate);
    var guard = 0;
    while (cursor.isAfter(target) && guard < 5000) {
      guard++;
      cursor = _previousOccurrence(sub, cursor);
    }
    return cursor;
  }

  DateTime _previousOccurrence(Subscription sub, DateTime date) {
    switch (sub.billingCycle) {
      case BillingCycle.weekly:
        return DateTime(date.year, date.month, date.day - 7);
      case BillingCycle.monthly:
        return DateUtils.addMonthsClamped(
          date,
          -1,
          anchorDay: sub.billingAnchorDay > 0
              ? sub.billingAnchorDay
              : date.day,
        );
      case BillingCycle.quarterly:
        return DateUtils.addMonthsClamped(
          date,
          -3,
          anchorDay: sub.billingAnchorDay > 0
              ? sub.billingAnchorDay
              : date.day,
        );
      case BillingCycle.yearly:
        return DateUtils.addMonthsClamped(
          date,
          -12,
          anchorDay: sub.billingAnchorDay > 0
              ? sub.billingAnchorDay
              : date.day,
        );
      case BillingCycle.custom:
        final days = sub.customIntervalDays ?? 30;
        return DateTime(date.year, date.month, date.day - days);
    }
  }
}
