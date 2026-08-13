import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../calendar/money_calendar.dart';
import '../../decision/review_queue.dart';
import '../../decision/savings.dart';
import '../../decision/today_brief.dart';
import '../../subscriptions/domain/billing_cycle.dart';
import '../../subscriptions/domain/subscription.dart';
import '../../subscriptions/domain/subscription_status.dart';

class DashboardState {
  const DashboardState({
    required this.active,
    required this.brief,
    required this.queue,
    required this.savings,
    required this.monthCharges,
  });

  /// Active (non-cancelled/archived, incl. pending-cancellation) subscriptions.
  final List<Subscription> active;

  /// Today Money Brief (first Home card, plan2_final §2).
  final TodayBrief brief;

  /// Full Review Queue, priority-sorted (Home card caps at 3).
  final List<ReviewQueueItem> queue;

  /// Savings (projected + realized), per currency.
  final SavingsSummary savings;

  /// Renewals in the current calendar month (drives the month card + calendar).
  final List<Subscription> monthCharges;
}

class DashboardController extends AsyncNotifier<DashboardState> {
  @override
  Future<DashboardState> build() async {
    final repo = await ref.watch(subscriptionRepositoryProvider.future);
    final all = await repo.getAll();
    final active = all
        .where((s) =>
            s.status == SubscriptionStatus.active ||
            s.status == SubscriptionStatus.pendingCancellation)
        .toList();

    final now = DateTime.now();
    final brief = const TodayBriefService().compute(
      subscriptions: all,
      now: now,
    );
    final queue = const ReviewQueueService().compute(
      subscriptions: all,
      now: now,
      hiddenIds: ref.watch(reviewQueueHiddenIdsProvider),
    );
    final savings = const SavingsCalculator().compute(
      subscriptions: all,
      now: now,
    );
    final monthCharges = const MoneyCalendarService()
        .compute(subscriptions: all, month: DateTime(now.year, now.month, 1))
        .chargesByDay
        .values
        .expand((list) => list)
        .toList();

    return DashboardState(
      active: active,
      brief: brief,
      queue: queue,
      savings: savings,
      monthCharges: monthCharges,
    );
  }

  /// Monthly cost in the given currency (integer minor units).
  ///
  /// Every active subscription contributes its *monthly equivalent* — derived
  /// from the yearly projection ÷ 12 — so weekly / quarterly / yearly /
  /// custom cycles are never silently missing from the Home headline (fix:
  /// previously only MONTHLY-cycle subs were counted).
  int monthlyTotal(String currency) => yearlyTotal(currency) ~/ 12;

  /// Yearly cost in the given currency (integer minor units, exact).
  int yearlyTotal(String currency) {
    final active = state.value?.active ?? const <Subscription>[];
    var total = 0;
    for (final sub in active) {
      if (sub.currency != currency) continue;
      total += _projectYearly(sub);
    }
    return total;
  }

  int _projectYearly(Subscription sub) {
    switch (sub.billingCycle) {
      case BillingCycle.weekly:
        return sub.amountMinor * 52;
      case BillingCycle.monthly:
        return sub.amountMinor * 12;
      case BillingCycle.quarterly:
        return sub.amountMinor * 4;
      case BillingCycle.yearly:
        return sub.amountMinor;
      case BillingCycle.custom:
        final days = sub.customIntervalDays ?? 30;
        if (days <= 0) return sub.amountMinor * 12;
        return (sub.amountMinor * 365) ~/ days;
    }
  }

  /// 5-year projection at current prices (secondary figure).
  int fiveYearTotal(String currency) => yearlyTotal(currency) * 5;

  /// Grouped monthly-equivalent totals by currency (multi-currency display).
  Map<String, int> monthlyByCurrency() {
    final yearly = <String, int>{};
    for (final sub in state.value?.active ?? const <Subscription>[]) {
      yearly[sub.currency] = (yearly[sub.currency] ?? 0) + _projectYearly(sub);
    }
    return {
      for (final entry in yearly.entries) entry.key: entry.value ~/ 12,
    };
  }

  /// Current-month recurring charges in [currency] (integer minor units).
  int monthTotal(String currency) {
    var total = 0;
    for (final sub in state.value?.monthCharges ?? const <Subscription>[]) {
      if (sub.currency != currency) continue;
      total += sub.amountMinor;
    }
    return total;
  }
}

/// Session-scoped "Later" ids from the Review Queue (plan2_final §3.4) —
/// items hidden here don't re-surface until the app restarts.
final reviewQueueHiddenIdsProvider =
    NotifierProvider<ReviewQueueHiddenIds, Set<String>>(
  ReviewQueueHiddenIds.new,
);

class ReviewQueueHiddenIds extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void hideLater(String id) {
    state = {...state, id};
  }
}

final dashboardControllerProvider =
    AsyncNotifierProvider<DashboardController, DashboardState>(
  DashboardController.new,
);
