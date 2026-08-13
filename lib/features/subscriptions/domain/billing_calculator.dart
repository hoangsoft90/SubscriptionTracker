import '../../../core/calendar/date_utils.dart';
import 'billing_cycle.dart';

/// Pure calendar-date billing engine (spec §7).
///
/// Policy: "Same day if possible, else last day of month". `billingAnchorDay`
/// preserves the original anchor across month-end clamps (Jan 31 → Feb 28 →
/// Mar 31 — never Mar 28). WEEKLY ignores the anchor; CUSTOM cycles compute
/// `startDate + n × customIntervalDays`. All calculations are timezone-local
/// calendar dates — never UTC.
class BillingCalculator {
  BillingCalculator._();

  /// Computes the next billing date after [current] for [cycle].
  ///
  /// [customIntervalDays] is used only when [cycle] is [BillingCycle.custom].
  /// [billingAnchorDay] is used only for MONTHLY/QUARTERLY/YEARLY.
  static DateTime nextBillingDate({
    required DateTime current,
    required BillingCycle cycle,
    int? customIntervalDays,
    int billingAnchorDay = 0,
  }) {
    final date = DateUtils.localMidnight(current);

    switch (cycle) {
      case BillingCycle.weekly:
        // Calendar-day arithmetic (not Duration) so DST transitions cannot
        // shift the resulting calendar day.
        return DateTime(date.year, date.month, date.day + 7);

      case BillingCycle.monthly:
      case BillingCycle.quarterly:
      case BillingCycle.yearly:
        return DateUtils.addMonthsClamped(
          date,
          cycle == BillingCycle.monthly
              ? 1
              : (cycle == BillingCycle.quarterly ? 3 : 12),
          anchorDay: _requiredAnchor(date, cycle, billingAnchorDay),
        );

      case BillingCycle.custom:
        final days = customIntervalDays ?? 30;
        if (days <= 0) {
          throw ArgumentError('customIntervalDays must be > 0, got $days');
        }
        return DateTime(date.year, date.month, date.day + days);
    }
  }

  /// Returns the original anchor day for fixed calendar cycles.
  ///
  /// Throws when [billingAnchorDay] is not set (≤ 0): silently falling back
  /// to the clamped day would make the anchor drift (Jan 31 → Feb 28 → Mar 28,
  /// which is wrong per spec §7). Callers MUST persist the original anchor
  /// (e.g. from `startDate.day`) on the subscription.
  static int _requiredAnchor(DateTime date, BillingCycle cycle, int billingAnchorDay) {
    if (billingAnchorDay <= 0) {
      throw ArgumentError(
        'billingAnchorDay must be set for $cycle cycles (was $billingAnchorDay); '
        'persist the original anchor day (e.g. startDate.day) to avoid drift',
      );
    }
    return billingAnchorDay;
  }

  /// Projects [amountMinor] to a longer period on integer minor units.
  ///
  /// Weekly × 52, monthly × 12, quarterly × 4, yearly × 1; custom intervals
  /// approximate the yearly total as `amount × 365 / intervalDays` (integer
  /// math, rounded down) — used only for dashboard secondary figures.
  static int projectToYearly({
    required int amountMinor,
    required BillingCycle cycle,
    int? customIntervalDays,
  }) {
    switch (cycle) {
      case BillingCycle.weekly:
        return amountMinor * 52;
      case BillingCycle.monthly:
        return amountMinor * 12;
      case BillingCycle.quarterly:
        return amountMinor * 4;
      case BillingCycle.yearly:
        return amountMinor;
      case BillingCycle.custom:
        final days = customIntervalDays ?? 30;
        if (days <= 0) return amountMinor * 12;
        return (amountMinor * 365) ~/ days;
    }
  }

  /// Five-year projection at current prices (secondary dashboard figure).
  static int projectToFiveYears({required int yearlyMinor}) =>
      yearlyMinor * 5;
}
