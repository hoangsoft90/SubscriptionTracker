import '../../../core/calendar/date_utils.dart';
import '../subscriptions/domain/billing_calculator.dart';
import '../subscriptions/domain/subscription.dart';
import '../subscriptions/domain/subscription_status.dart';

/// Result of the savings calculation (plan2_final §4), per currency.
class SavingsSummary {
  const SavingsSummary({
    required this.projectedMonthly,
    required this.realized,
    required this.preCancellationMonthly,
  });

  /// Projected savings: monthly-equivalent of every PENDING_CANCELLATION +
  /// CANCELLED subscription (excluding superseded), per currency.
  final Map<String, int> projectedMonthly;

  /// Realized savings: money actually not charged, per currency. Only counts
  /// completed billing cycles after `cancelledAt` (plan2_final §4.1).
  final Map<String, int> realized;

  /// Monthly cost before any cancellations (active + pending-cancellation +
  /// cancelled monthly-equivalents), per currency — drives the "↓ $X" delta.
  final Map<String, int> preCancellationMonthly;

  /// Monthly-equivalent of one subscription in minor units (integer math).
  static int monthlyEquivalent(Subscription sub) {
    final yearly = BillingCalculator.projectToYearly(
      amountMinor: sub.amountMinor,
      cycle: sub.billingCycle,
      customIntervalDays: sub.customIntervalDays,
    );
    // Integer division — document as "estimated" in UI (plan2_final §4.3).
    return yearly ~/ 12;
  }
}

/// Pure savings engine (plan2_final §4). All money is integer minor units;
/// multi-currency totals are grouped per currency (never mixed).
class SavingsCalculator {
  const SavingsCalculator();

  SavingsSummary compute({
    required List<Subscription> subscriptions,
    required DateTime now,
  }) {
    final today = DateUtils.localMidnight(now);
    final projected = <String, int>{};
    final realized = <String, int>{};
    final preCancellation = <String, int>{};

    void add(Map<String, int> map, String currency, int minor) {
      map[currency] = (map[currency] ?? 0) + minor;
    }

    for (final sub in subscriptions) {
      final status = sub.status;
      final isSlot = status == SubscriptionStatus.active ||
          status == SubscriptionStatus.pendingCancellation;
      final isCancelled = status == SubscriptionStatus.cancelled;
      final superseded = sub.supersededAt != null;

      // Pre-cancellation baseline includes everything that was (or is) paying.
      if (isSlot || isCancelled) {
        add(preCancellation, sub.currency, SavingsSummary.monthlyEquivalent(sub));
      }

      // Projected: pending + cancelled, minus superseded re-subscriptions.
      if ((status == SubscriptionStatus.pendingCancellation || isCancelled) &&
          !superseded) {
        add(projected, sub.currency, SavingsSummary.monthlyEquivalent(sub));
      }

      // Realized: only fully-superseded-free cancelled subs whose billing date
      // has passed. Counts completed cycles strictly before today.
      if (isCancelled && !superseded && sub.cancelledAt != null) {
        final cycles = _elapsedCyclesSince(sub, DateUtils.localMidnight(sub.cancelledAt!), today);
        if (cycles > 0) {
          add(realized, sub.currency, sub.amountMinor * cycles);
        }
      }
    }

    return SavingsSummary(
      projectedMonthly: projected,
      realized: realized,
      preCancellationMonthly: preCancellation,
    );
  }

  /// Number of billing cycles fully completed between [from] (exclusive) and
  /// [today] (exclusive of today — a cycle is "realized" only after its date
  /// has passed, plan2_final §4.1). Bounded to avoid infinite loops for
  /// WEEKLY/CUSTOM subscriptions.
  int _elapsedCyclesSince(Subscription sub, DateTime from, DateTime today) {
    var cycles = 0;
    var cursor = from;
    var guard = 0;
    while (guard < 5000) {
      guard++;
      cursor = BillingCalculator.nextBillingDate(
        current: cursor,
        cycle: sub.billingCycle,
        customIntervalDays: sub.customIntervalDays,
        billingAnchorDay: sub.billingAnchorDay > 0
            ? sub.billingAnchorDay
            : cursor.day,
      );
      if (!cursor.isBefore(today)) break;
      cycles++;
    }
    return cycles;
  }
}
