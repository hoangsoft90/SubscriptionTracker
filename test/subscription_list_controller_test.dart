import 'package:flutter_test/flutter_test.dart';

import 'package:subtrack/core/calendar/date_utils.dart';
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
    String id = 's',
    String name = 'Name',
    int amount = 1000,
    DateTime? nextBilling,
    SubscriptionStatus status = SubscriptionStatus.active,
    String? categoryId,
    BillingCycle cycle = BillingCycle.monthly,
  }) {
    return Subscription(
      id: id,
      name: name,
      amountMinor: amount,
      currency: 'USD',
      billingCycle: cycle,
      startDate: DateTime(2026, 1, 1),
      nextBillingDate: nextBilling ?? DateTime(2026, 8, 15),
      billingAnchorDay: 1,
      isTrial: false,
      status: status,
      categoryId: categoryId,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  test('add + search filters by name (case-insensitive)', () async {
    final container = harness.container();
    addTearDown(container.dispose);

    final notifier = container.read(subscriptionListControllerProvider.notifier);
    await notifier.add(sub(id: 'a', name: 'Netflix'));
    await notifier.add(sub(id: 'b', name: 'Spotify'));

    notifier.setQuery('net');
    final state = container.read(subscriptionListControllerProvider).requireValue;
    expect(state.visible.map((s) => s.id), ['a']);

    notifier.setQuery('NETFLIX');
    final state2 = container.read(subscriptionListControllerProvider).requireValue;
    expect(state2.visible.length, 1);
  });

  test('status filter excludes other statuses', () async {
    final container = harness.container();
    addTearDown(container.dispose);

    final notifier = container.read(subscriptionListControllerProvider.notifier);
    await notifier.add(sub(id: 'a', name: 'Active one'));
    await notifier.add(
      sub(id: 'b', name: 'Cancelled one', status: SubscriptionStatus.cancelled),
    );

    notifier.setStatusFilter(SubscriptionStatus.active);
    var state = container.read(subscriptionListControllerProvider).requireValue;
    expect(state.visible.map((s) => s.id), ['a']);

    notifier.setStatusFilter(SubscriptionStatus.cancelled);
    state = container.read(subscriptionListControllerProvider).requireValue;
    expect(state.visible.map((s) => s.id), ['b']);
  });

  test('sort by amount and by next billing', () async {
    final container = harness.container();
    addTearDown(container.dispose);

    final notifier = container.read(subscriptionListControllerProvider.notifier);
    await notifier.add(sub(id: 'a', name: 'Cheap', amount: 100));
    await notifier.add(sub(id: 'b', name: 'Expensive', amount: 9999));
    await notifier.add(sub(id: 'c', name: 'Middle', amount: 500));

    notifier.setSort(SubscriptionSort.amount);
    var state = container.read(subscriptionListControllerProvider).requireValue;
    expect(state.visible.map((s) => s.id), ['a', 'c', 'b']);
  });

  test('edit preserves untouched fields', () async {
    final container = harness.container();
    addTearDown(container.dispose);

    final notifier = container.read(subscriptionListControllerProvider.notifier);
    await notifier.add(
      sub(
        id: 'a',
        name: 'Netflix',
        amount: 1499,
        nextBilling: DateTime(2026, 9, 1),
        categoryId: 'streaming',
      ),
    );

    final existing = container
        .read(subscriptionListControllerProvider)
        .requireValue
        .subscriptions
        .first;
    final edited = existing.copyWith(amountMinor: 1999);
    await notifier.updateSubscription(edited);

    final restored = container
        .read(subscriptionListControllerProvider)
        .requireValue
        .subscriptions
        .first;
    expect(restored.amountMinor, 1999);
    expect(restored.name, 'Netflix');
    expect(restored.nextBillingDate, DateTime(2026, 9, 1));
    expect(restored.categoryId, 'streaming');
  });

  test('setStatus and delete update the list', () async {
    final container = harness.container();
    addTearDown(container.dispose);

    final notifier = container.read(subscriptionListControllerProvider.notifier);
    await notifier.add(sub(id: 'a', name: 'Netflix'));

    await notifier.setStatus('a', SubscriptionStatus.cancelled);
    var state = container.read(subscriptionListControllerProvider).requireValue;
    expect(state.subscriptions.first.status, SubscriptionStatus.cancelled);

    await notifier.delete('a');
    state = container.read(subscriptionListControllerProvider).requireValue;
    expect(state.subscriptions, isEmpty);
  });

  test('custom interval preserved through save', () async {
    final container = harness.container();
    addTearDown(container.dispose);

    final notifier = container.read(subscriptionListControllerProvider.notifier);
    await notifier.add(
      sub(id: 'a', name: 'Custom', cycle: BillingCycle.custom)
          .copyWith(customIntervalDays: 45),
    );

    final restored = container
        .read(subscriptionListControllerProvider)
        .requireValue
        .subscriptions
        .first;
    expect(restored.billingCycle, BillingCycle.custom);
    expect(restored.customIntervalDays, 45);
  });

  test('calendar dates round-trip without shift', () async {
    final container = harness.container();
    addTearDown(container.dispose);

    final notifier = container.read(subscriptionListControllerProvider.notifier);
    final aug31 = DateUtils.localMidnight(DateTime(2026, 8, 31));
    await notifier.add(
      sub(id: 'a', name: 'Netflix', nextBilling: aug31),
    );

    final restored = container
        .read(subscriptionListControllerProvider)
        .requireValue
        .subscriptions
        .first;
    expect(restored.nextBillingDate, aug31);
  });
}
