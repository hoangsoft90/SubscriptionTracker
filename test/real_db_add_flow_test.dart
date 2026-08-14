import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:subtrack/core/providers.dart';
import 'package:subtrack/core/storage/app_database.dart';
import 'package:subtrack/core/storage/storage_backend_stub.dart';
import 'package:subtrack/features/dashboard/application/dashboard_controller.dart';
import 'package:subtrack/features/subscriptions/application/subscription_list_controller.dart';
import 'package:subtrack/features/subscriptions/domain/billing_cycle.dart';
import 'package:subtrack/features/subscriptions/domain/subscription.dart';
import 'package:subtrack/features/subscriptions/domain/subscription_status.dart';

/// Drives the REAL production storage stack (sqflite + migrations + seeder +
/// real repositories + real Riverpod controllers) — no fakes. This is the
/// closest reproduction of the on-device flow available on the VM: the
/// reported bug was "add a subscription → Home + Subscriptions tabs don't
/// update until the app is restarted".
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  ProviderContainer containerFor(Database db) {
    return ProviderContainer(overrides: [
      storageBackendProvider.overrideWith((ref) async => SqliteStorageBackend(db)),
    ]);
  }

  Subscription sample({required String id, required String name}) {
    return Subscription(
      id: id,
      name: name,
      amountMinor: 14900,
      currency: 'VND',
      billingCycle: BillingCycle.monthly,
      startDate: DateTime(2026, 8, 1),
      nextBillingDate: DateTime(2026, 9, 1),
      billingAnchorDay: 1,
      isTrial: false,
      status: SubscriptionStatus.active,
      createdAt: DateTime(2026, 8, 14, 10, 0, 0),
      updatedAt: DateTime(2026, 8, 14, 10, 0, 0),
    );
  }

  test('add through real sqflite: list + dashboard update immediately', () async {
    final dir = await Directory.systemTemp.createTemp('subtrack_realdb');
    addTearDown(() => dir.delete(recursive: true));
    final db = await AppDatabase.open(path: '${dir.path}/test.db');
    final container = containerFor(db);
    addTearDown(container.dispose);

    // Empty initially (fresh DB, seeded defaults).
    final initial =
        await container.read(subscriptionListControllerProvider.future);
    expect(initial.subscriptions, isEmpty);

    // The reported scenario: first subscription is added.
    await container
        .read(subscriptionListControllerProvider.notifier)
        .add(sample(id: 's1', name: 'Netflix'));

    // Subscriptions tab provider reflects it immediately.
    final after = container.read(subscriptionListControllerProvider);
    expect(after.hasValue, isTrue);
    expect(after.value!.subscriptions.map((s) => s.id), ['s1']);

    // Home tab provider (dashboard) reflects it immediately.
    final dash = await container.read(dashboardControllerProvider.future);
    expect(dash.active.map((s) => s.id), ['s1']);

    // A second add keeps both tabs fresh.
    await container
        .read(subscriptionListControllerProvider.notifier)
        .add(sample(id: 's2', name: 'Spotify'));
    final after2 = container.read(subscriptionListControllerProvider);
    expect(
      after2.value!.subscriptions.map((s) => s.id).toSet(),
      {'s1', 's2'},
    );
    final dash2 = await container.read(dashboardControllerProvider.future);
    expect(dash2.active.length, 2);

    // Simulated app restart: close everything, reopen the same DB file in a
    // brand-new container — data must persist.
    container.dispose();
    await db.close();
    final db2 = await AppDatabase.open(path: '${dir.path}/test.db');
    final container2 = containerFor(db2);
    addTearDown(container2.dispose);
    final afterRestart =
        await container2.read(subscriptionListControllerProvider.future);
    expect(afterRestart.subscriptions.length, 2);
    expect(
      afterRestart.subscriptions.map((s) => s.id).toSet(),
      {'s1', 's2'},
    );
  });
}
