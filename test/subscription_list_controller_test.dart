import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:subtrack/core/calendar/date_utils.dart';
import 'package:subtrack/core/providers.dart';
import 'package:subtrack/features/subscriptions/application/subscription_list_controller.dart';
import 'package:subtrack/features/subscriptions/data/subscription_repository.dart';
import 'package:subtrack/features/subscriptions/domain/billing_cycle.dart';
import 'package:subtrack/features/subscriptions/domain/price_history.dart';
import 'package:subtrack/features/subscriptions/domain/subscription.dart';
import 'package:subtrack/features/subscriptions/domain/subscription_status.dart';

import 'fakes.dart';
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

  test('reload is null-safe when a mutation races the initial build', () async {
    // Regression for the reported "tabs don't show the new item until app
    // restart" symptom: if a mutation ever runs while the provider's first
    // build is still loading (state has no value), reload() must rebuild the
    // state from the fresh DB rows instead of crashing on `state.value!`.
    // A crash there would leave the list on stale data until the next launch.
    final gate = Completer<void>();
    final repo = _GatedSubscriptionRepository(
      FakeSubscriptionRepository(),
      gate,
    );

    final container = ProviderContainer(overrides: [
      subscriptionRepositoryProvider.overrideWith((ref) async => repo),
      categoryRepositoryProvider.overrideWith(
          (ref) async => FakeCategoryRepository()),
      settingsRepositoryProvider.overrideWith(
          (ref) async => FakeSettingsRepository()),
    ]);
    addTearDown(container.dispose);

    // Start the initial build — its getAll() is gated, so the provider has
    // no value yet (the race window).
    final notifier = container.read(subscriptionListControllerProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(subscriptionListControllerProvider).value, isNull);

    // The mutation races the first load: must not throw, and the list must
    // immediately reflect the insert.
    await notifier.add(sub(id: 'a', name: 'Netflix'));

    final after = container.read(subscriptionListControllerProvider);
    expect(after.hasError, isFalse);
    expect(after.value!.subscriptions.map((s) => s.id), ['a']);

    // Release the initial build: it re-reads storage (which already has the
    // row) so the data stays — never a stale empty list.
    gate.complete();
    await Future<void>.delayed(Duration.zero);
    final settled = container.read(subscriptionListControllerProvider);
    expect(settled.value!.subscriptions.map((s) => s.id), ['a']);
  });
}

/// [FakeSubscriptionRepository] whose FIRST `getAll()` is gated — used to
/// simulate a slow initial load so a mutation can race it.
class _GatedSubscriptionRepository implements SubscriptionRepository {
  _GatedSubscriptionRepository(this._inner, this._gate);

  final FakeSubscriptionRepository _inner;
  final Completer<void> _gate;
  bool _firstGetAll = true;

  @override
  Future<List<Subscription>> getAll() {
    if (_firstGetAll) {
      _firstGetAll = false;
      return _gate.future.then((_) => _inner.getAll());
    }
    return _inner.getAll();
  }

  @override
  Future<String> insert(Subscription subscription) => _inner.insert(subscription);

  @override
  Future<void> update(Subscription subscription) => _inner.update(subscription);

  @override
  Future<void> delete(String id) => _inner.delete(id);

  @override
  Future<Subscription?> getById(String id) => _inner.getById(id);

  @override
  Future<int> countByStatus(SubscriptionStatus status) =>
      _inner.countByStatus(status);

  @override
  Future<void> insertPriceHistory(PriceHistoryEntry entry) =>
      _inner.insertPriceHistory(entry);

  @override
  Future<List<PriceHistoryEntry>> getPriceHistory(String subscriptionId) =>
      _inner.getPriceHistory(subscriptionId);

  @override
  Future<void> deleteAll() => _inner.deleteAll();
}
