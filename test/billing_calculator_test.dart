import 'package:flutter_test/flutter_test.dart';

import 'package:subtrack/features/subscriptions/domain/billing_calculator.dart';
import 'package:subtrack/features/subscriptions/domain/billing_cycle.dart';

void main() {
  DateTime d(int y, int m, int day) => DateTime(y, m, day);

  group('BillingCalculator.nextBillingDate — monthly', () {
    test('Jan 31 → Feb 28 (same-day impossible → last day)', () {
      expect(
        BillingCalculator.nextBillingDate(
          current: d(2026, 1, 31),
          cycle: BillingCycle.monthly,
          billingAnchorDay: 31,
        ),
        d(2026, 2, 28),
      );
    });

    test('clamp-restore: Feb 28 → Mar 31, NOT Mar 28 (anchor preserved)', () {
      expect(
        BillingCalculator.nextBillingDate(
          current: d(2026, 2, 28),
          cycle: BillingCycle.monthly,
          billingAnchorDay: 31,
        ),
        d(2026, 3, 31),
      );
    });

    test('full chain Jan 31 → Feb 28 → Mar 31 → Apr 30', () {
      var date = d(2026, 1, 31);
      const anchor = 31;
      date = BillingCalculator.nextBillingDate(
          current: date, cycle: BillingCycle.monthly, billingAnchorDay: anchor);
      expect(date, d(2026, 2, 28));
      date = BillingCalculator.nextBillingDate(
          current: date, cycle: BillingCycle.monthly, billingAnchorDay: anchor);
      expect(date, d(2026, 3, 31));
      date = BillingCalculator.nextBillingDate(
          current: date, cycle: BillingCycle.monthly, billingAnchorDay: anchor);
      expect(date, d(2026, 4, 30));
    });

    test('leap year: Jan 31 2028 → Feb 29 → Mar 31', () {
      var date = d(2028, 1, 31);
      const anchor = 31;
      date = BillingCalculator.nextBillingDate(
          current: date, cycle: BillingCycle.monthly, billingAnchorDay: anchor);
      expect(date, d(2028, 2, 29));
      date = BillingCalculator.nextBillingDate(
          current: date, cycle: BillingCycle.monthly, billingAnchorDay: anchor);
      expect(date, d(2028, 3, 31));
    });

    test('Dec 31 → Jan 31 (year boundary)', () {
      expect(
        BillingCalculator.nextBillingDate(
          current: d(2026, 12, 31),
          cycle: BillingCycle.monthly,
          billingAnchorDay: 31,
        ),
        d(2027, 1, 31),
      );
    });

    test('regular mid-month day stays same day', () {
      expect(
        BillingCalculator.nextBillingDate(
          current: d(2026, 5, 15),
          cycle: BillingCycle.monthly,
          billingAnchorDay: 15,
        ),
        d(2026, 6, 15),
      );
    });

    test('missing anchor for fixed cycle is rejected (anti-drift guard)', () {
      expect(
        () => BillingCalculator.nextBillingDate(
          current: d(2026, 1, 31),
          cycle: BillingCycle.monthly,
        ),
        throwsArgumentError,
      );
    });
  });

  group('BillingCalculator.nextBillingDate — quarterly/yearly', () {
    test('quarterly Feb 29 → May 29 → Aug 29', () {
      var date = d(2028, 2, 29);
      date = BillingCalculator.nextBillingDate(
          current: date, cycle: BillingCycle.quarterly, billingAnchorDay: 29);
      expect(date, d(2028, 5, 29));
      date = BillingCalculator.nextBillingDate(
          current: date, cycle: BillingCycle.quarterly, billingAnchorDay: 29);
      expect(date, d(2028, 8, 29));
    });

    test('quarterly Nov 30 → Feb 28 (clamp in non-leap Feb) → May 30', () {
      var date = d(2026, 11, 30);
      const anchor = 30;
      date = BillingCalculator.nextBillingDate(
          current: date, cycle: BillingCycle.quarterly, billingAnchorDay: anchor);
      expect(date, d(2027, 2, 28));
      date = BillingCalculator.nextBillingDate(
          current: date, cycle: BillingCycle.quarterly, billingAnchorDay: anchor);
      expect(date, d(2027, 5, 30));
    });

    test('yearly Feb 29 2028 → Feb 28 2029 → Feb 28 2030', () {
      var date = d(2028, 2, 29);
      const anchor = 29;
      date = BillingCalculator.nextBillingDate(
          current: date, cycle: BillingCycle.yearly, billingAnchorDay: anchor);
      expect(date, d(2029, 2, 28));
      date = BillingCalculator.nextBillingDate(
          current: date, cycle: BillingCycle.yearly, billingAnchorDay: anchor);
      expect(date, d(2030, 2, 28));
    });
  });

  group('BillingCalculator.nextBillingDate — custom & weekly', () {
    test('custom 45 days: start 2026-01-01 → 2026-02-15, ignores anchor', () {
      expect(
        BillingCalculator.nextBillingDate(
          current: d(2026, 1, 1),
          cycle: BillingCycle.custom,
          customIntervalDays: 45,
          billingAnchorDay: 31,
        ),
        d(2026, 2, 15),
      );
    });

    test('custom negative interval rejected', () {
      expect(
        () => BillingCalculator.nextBillingDate(
          current: d(2026, 1, 1),
          cycle: BillingCycle.custom,
          customIntervalDays: 0,
        ),
        throwsArgumentError,
      );
    });

    test('weekly ignores anchor, exactly +7 calendar days', () {
      expect(
        BillingCalculator.nextBillingDate(
          current: d(2026, 1, 31),
          cycle: BillingCycle.weekly,
          billingAnchorDay: 31,
        ),
        d(2026, 2, 7),
      );
    });

    test('weekly across year boundary', () {
      expect(
        BillingCalculator.nextBillingDate(
          current: d(2026, 12, 29),
          cycle: BillingCycle.weekly,
        ),
        d(2027, 1, 5),
      );
    });
  });

  group('Projections (integer minor units)', () {
    test('monthly × 12', () {
      expect(
        BillingCalculator.projectToYearly(
          amountMinor: 999,
          cycle: BillingCycle.monthly,
        ),
        11988,
      );
    });

    test('weekly × 52', () {
      expect(
        BillingCalculator.projectToYearly(
          amountMinor: 499,
          cycle: BillingCycle.weekly,
        ),
        25948,
      );
    });

    test('yearly unchanged', () {
      expect(
        BillingCalculator.projectToYearly(
          amountMinor: 11988,
          cycle: BillingCycle.yearly,
        ),
        11988,
      );
    });

    test('custom uses 365 / intervalDays', () {
      // 999 * 365 = 364635; 364635 ~/ 45 = 8103 (integer division)
      expect(
        BillingCalculator.projectToYearly(
          amountMinor: 999,
          cycle: BillingCycle.custom,
          customIntervalDays: 45,
        ),
        8103,
      );
    });

    test('five-year projection multiplies yearly', () {
      expect(BillingCalculator.projectToFiveYears(yearlyMinor: 11988), 59940);
    });
  });
}
