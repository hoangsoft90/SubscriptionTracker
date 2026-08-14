import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:subtrack/core/providers.dart';
import 'package:subtrack/core/storage/local_storage_store.dart';
import 'package:subtrack/features/categories/data/local_storage_category_repository.dart';
import 'package:subtrack/features/settings/data/local_storage_settings_repository.dart';
import 'package:subtrack/features/subscriptions/application/subscription_list_controller.dart';
import 'package:subtrack/features/subscriptions/data/local_storage_subscription_repository.dart';
import 'package:subtrack/features/subscriptions/domain/billing_cycle.dart';
import 'package:subtrack/features/subscriptions/domain/subscription.dart';
import 'package:subtrack/features/subscriptions/domain/subscription_status.dart';

import 'local_storage_repository_test.dart' show MemoryKeyValueStorage;

/// Integration test of the REAL web storage layer (LocalStorage*Repository
/// over an in-memory [KeyValueStorage] — the exact code the web build ships,
/// minus the browser wrapper) + the REAL controller providers: proves the
/// "add → list shows → restart → still there → refresh → still there" cycle.
/// If this passes, the disappearing-data symptom cannot come from the web
/// storage layer.
void main() {
  late MemoryKeyValueStorage kv;
  late LocalStorageStore store;

  setUp(() {
    kv = MemoryKeyValueStorage();
    store = LocalStorageStore(kv);
  });

  ProviderContainer makeContainer() {
    // Mirrors LocalStorageBackend from storage_backend_web.dart (web-only
    // BrowserLocalStorage swapped for the in-memory KeyValueStorage).
    return ProviderContainer(overrides: [
      subscriptionRepositoryProvider.overrideWithValue(
        AsyncValue.data(LocalStorageSubscriptionRepository(store)),
      ),
      categoryRepositoryProvider.overrideWithValue(
        AsyncValue.data(LocalStorageCategoryRepository(store)),
      ),
      settingsRepositoryProvider.overrideWithValue(
        AsyncValue.data(LocalStorageSettingsRepository(store)),
      ),
    ]);
  }

  Subscription sub({String id = 's1', String name = 'Netflix'}) {
    return Subscription(
      id: id,
      name: name,
      amountMinor: 1499,
      currency: 'USD',
      billingCycle: BillingCycle.monthly,
      startDate: DateTime(2026, 8, 1),
      nextBillingDate: DateTime(2026, 8, 15),
      billingAnchorDay: 1,
      isTrial: false,
      status: SubscriptionStatus.active,
      createdAt: DateTime(2026, 8, 1),
      updatedAt: DateTime(2026, 8, 1),
    );
  }

  test('add → list shows → restart (fresh container) → still there', () async {
    final container = makeContainer();
    addTearDown(container.dispose);

    var state = await container.read(subscriptionListControllerProvider.future);
    expect(state.subscriptions, isEmpty);

    await container
        .read(subscriptionListControllerProvider.notifier)
        .add(sub());

    state = await container.read(subscriptionListControllerProvider.future);
    expect(state.subscriptions.map((s) => s.name), contains('Netflix'));

    // Simulate reopening the app: a brand-new container over the SAME kv
    // (localStorage persists across sessions on web).
    final container2 = makeContainer();
    addTearDown(container2.dispose);
    state = await container2.read(subscriptionListControllerProvider.future);
    expect(state.subscriptions.map((s) => s.name), contains('Netflix'));

    // Simulate pull-to-refresh: force a rebuild of the list provider from
    // storage — data must still be present.
    container2.refresh(subscriptionListControllerProvider);
    state = await container2.read(subscriptionListControllerProvider.future);
    expect(state.subscriptions.map((s) => s.name), contains('Netflix'));
  });

  test('add twice → both survive restart + refresh', () async {
    final container = makeContainer();
    addTearDown(container.dispose);

    final notifier =
        container.read(subscriptionListControllerProvider.notifier);
    await notifier.add(sub(id: 'a', name: 'Netflix'));
    await notifier.add(sub(id: 'b', name: 'Spotify'));

    final container2 = makeContainer();
    addTearDown(container2.dispose);
    container2.refresh(subscriptionListControllerProvider);
    final state = await container2.read(subscriptionListControllerProvider.future);
    expect(state.subscriptions.length, 2);
    expect(
      state.subscriptions.map((s) => s.name).toSet(),
      {'Netflix', 'Spotify'},
    );
  });
}
