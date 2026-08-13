import 'package:flutter_test/flutter_test.dart';

import 'package:subtrack/features/dashboard/application/dashboard_controller.dart';
import 'package:subtrack/features/decision/review_queue.dart';
import 'package:subtrack/features/subscriptions/application/subscription_list_controller.dart';
import 'package:subtrack/features/subscriptions/domain/billing_cycle.dart';
import 'package:subtrack/features/subscriptions/domain/subscription.dart';
import 'package:subtrack/features/subscriptions/domain/subscription_status.dart';

import 'm1_support.dart';

void main() {
  late TestDb harness;

  setUp(() async {
    harness = await TestDb.create();
  });

  tearDown(() async {
    await closeTestDb(harness);
  });

  Subscription sub({
    required String id,
    String name = 'Sub',
    int amount = 1000,
    String currency = 'USD',
    BillingCycle cycle = BillingCycle.monthly,
    DateTime? nextBilling,
    SubscriptionStatus status = SubscriptionStatus.active,
  }) {
    return Subscription(
      id: id,
      name: name,
      amountMinor: amount,
      currency: currency,
      billingCycle: cycle,
      startDate: DateTime(2026, 1, 1),
      nextBillingDate: nextBilling ?? DateTime(2026, 8, 15),
      billingAnchorDay: 1,
      isTrial: false,
      status: status,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  test('totals exclude cancelled and archived', () async {
    final container = harness.container();
    addTearDown(container.dispose);

    final notifier =
        container.read(subscriptionListControllerProvider.notifier);
    await notifier.add(sub(id: 'a', amount: 1000)); // monthly
    await notifier.add(
      sub(
        id: 'b',
        amount: 2000,
        status: SubscriptionStatus.cancelled,
      ),
    );
    await notifier.add(
      sub(
        id: 'c',
        amount: 3000,
        status: SubscriptionStatus.archived,
      ),
    );

    await container.read(dashboardControllerProvider.future);
    final controller = container.read(dashboardControllerProvider.notifier);
    expect(controller.monthlyTotal('USD'), 1000); // only active
  });

  test('monthly and yearly totals are exact integers', () async {
    final container = harness.container();
    addTearDown(container.dispose);

    final notifier =
        container.read(subscriptionListControllerProvider.notifier);
    await notifier.add(sub(id: 'a', amount: 999, cycle: BillingCycle.monthly));
    await notifier.add(sub(id: 'b', amount: 1299, cycle: BillingCycle.yearly));

    await container.read(dashboardControllerProvider.future);
    final controller = container.read(dashboardControllerProvider.notifier);
    // monthlyTotal is the monthly equivalent of *every* cycle — yearly subs
    // contribute their yearly ÷ 12 (fix: only monthly-cycle subs used to count).
    expect(controller.monthlyTotal('USD'), (999 * 12 + 1299) ~/ 12);
    // yearly = monthly×12 + yearly as-is
    expect(controller.yearlyTotal('USD'), 999 * 12 + 1299);
  });

  test('monthly total converts non-monthly cycles to monthly equivalent',
      () async {
    final container = harness.container();
    addTearDown(container.dispose);

    final notifier =
        container.read(subscriptionListControllerProvider.notifier);
    // $120/yr → $10/month-equivalent.
    await notifier.add(sub(id: 'a', amount: 12000, cycle: BillingCycle.yearly));
    // $10/week → $520/yr → $43/month-equivalent (43.33 truncated).
    await notifier.add(sub(id: 'b', amount: 1000, cycle: BillingCycle.weekly));

    await container.read(dashboardControllerProvider.future);
    final controller = container.read(dashboardControllerProvider.notifier);
    expect(controller.yearlyTotal('USD'), 12000 + 1000 * 52);
    expect(controller.monthlyTotal('USD'), (12000 + 52000) ~/ 12);
  });

  test('five-year projection multiplies yearly', () async {
    final container = harness.container();
    addTearDown(container.dispose);

    final notifier =
        container.read(subscriptionListControllerProvider.notifier);
    await notifier.add(sub(id: 'a', amount: 1000, cycle: BillingCycle.monthly));

    await container.read(dashboardControllerProvider.future);
    final controller = container.read(dashboardControllerProvider.notifier);
    expect(controller.fiveYearTotal('USD'), 1000 * 12 * 5);
  });

  test('today brief picks the earliest future renewal', () async {
    final container = harness.container();
    addTearDown(container.dispose);

    final now = DateTime.now();
    final notifier =
        container.read(subscriptionListControllerProvider.notifier);
    await notifier.add(
      sub(id: 'later', name: 'Later', nextBilling: now.add(const Duration(days: 20))),
    );
    await notifier.add(
      sub(id: 'soon', name: 'Soon', nextBilling: now.add(const Duration(days: 2))),
    );

    final dashboard = await container.read(dashboardControllerProvider.future);
    expect(dashboard.brief.clear, isFalse);
    expect(dashboard.brief.nextRenewal?.id, 'soon');
    expect(dashboard.brief.nextRenewalInDays, 2);
  });

  test('review queue caps high-priority items and scores staleness', () async {
    final container = harness.container();
    addTearDown(container.dispose);

    final now = DateTime.now();
    final notifier =
        container.read(subscriptionListControllerProvider.notifier);
    // Trial ending in 2 days → high.
    await notifier.add(
      sub(id: 'trial', name: 'Canva')
          .copyWith(isTrial: true, trialEndDate: now.add(const Duration(days: 2))),
    );
    // Old reviewed sub → medium (stale).
    await notifier.add(
      sub(id: 'stale', name: 'Adobe')
          .copyWith(lastReviewedAt: now.subtract(const Duration(days: 200))),
    );
    // Price changed → medium.
    await notifier.add(sub(id: 'price', name: 'Netflix').copyWith(previousAmountMinor: 999));

    final dashboard = await container.read(dashboardControllerProvider.future);
    final reasons = {
      for (final item in dashboard.queue) item.subscription.id: item.reason,
    };
    expect(reasons['trial'], ReviewReason.trialEnding);
    expect(reasons['stale'], ReviewReason.stale);
    expect(reasons['price'], ReviewReason.priceChanged);
    // High priority first.
    expect(dashboard.queue.first.subscription.id, 'trial');
  });

  test('savings projected from cancelled + pending-cancellation, not superseded',
      () async {
    final container = harness.container();
    addTearDown(container.dispose);

    final notifier =
        container.read(subscriptionListControllerProvider.notifier);
    // Active monthly $10 → keeps counting toward pre-cancellation baseline.
    await notifier.add(sub(id: 'active', name: 'A', amount: 1000));
    // Cancelled monthly $20 → projected.
    await notifier.add(
      sub(id: 'gone', name: 'G', amount: 2000, status: SubscriptionStatus.cancelled)
          .copyWith(cancelledAt: DateTime.now()),
    );
    // Pending cancellation monthly $30 → projected too.
    await notifier.add(
      sub(id: 'pending', name: 'P', amount: 3000,
          status: SubscriptionStatus.pendingCancellation),
    );

    final dashboard = await container.read(dashboardControllerProvider.future);
    expect(dashboard.savings.projectedMonthly['USD'], 5000);
    expect(dashboard.savings.preCancellationMonthly['USD'], 6000);
  });

  test('month total aggregates current-month charges', () async {
    final container = harness.container();
    addTearDown(container.dispose);

    final now = DateTime.now();
    final notifier =
        container.read(subscriptionListControllerProvider.notifier);
    await notifier.add(
      sub(id: 'a', name: 'A', amount: 1000, nextBilling: now.add(const Duration(days: 3))),
    );
    await notifier.add(
      sub(id: 'b', name: 'B', amount: 2000, nextBilling: now.add(const Duration(days: 5))),
    );

    final dashboard = await container.read(dashboardControllerProvider.future);
    final controller = container.read(dashboardControllerProvider.notifier);
    // Both renewals land in the current month (nextBilling ~ now).
    expect(dashboard.monthCharges.length, 2);
    expect(controller.monthTotal('USD'), 3000);
  });
}
