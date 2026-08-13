import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:sqflite/sqflite.dart';

import '../core/notifications/coordinator.dart';
import '../core/notifications/notification_platform.dart';
import '../core/notifications/notification_scheduler.dart';
import '../core/notifications/permission.dart';
import '../core/storage/app_database.dart';
import '../core/storage/storage_backend_factory.dart';
import '../features/paywall/purchase_gateway.dart';
import '../features/categories/data/category_repository.dart';
import '../features/dashboard/application/dashboard_controller.dart';
import '../features/settings/data/settings_repository.dart';
import '../features/subscriptions/application/subscription_list_controller.dart';
import '../features/subscriptions/data/subscription_repository.dart';
import '../features/subscriptions/domain/subscription_status.dart';

/// The app database (sqflite, seeded defaults — M0).
///
/// Retained as the SQLite source for tests that override it directly
/// (native-only; the web build never touches sqflite).
final databaseProvider = FutureProvider<Database>((ref) {
  return AppDatabase.open();
});

/// Platform storage backend: SQLite on iOS/Android, browser localStorage on
/// web. Controllers and business logic depend only on the repository
/// interfaces below, never on this provider directly.
final storageBackendProvider = FutureProvider<StorageBackend>((ref) {
  return createStorageBackend();
});

/// Typed repositories over the platform storage backend.
final subscriptionRepositoryProvider = FutureProvider<SubscriptionRepository>(
  (ref) async =>
      (await ref.watch(storageBackendProvider.future)).subscriptions,
);

final categoryRepositoryProvider = FutureProvider<CategoryRepository>(
  (ref) async => (await ref.watch(storageBackendProvider.future)).categories,
);

final settingsRepositoryProvider = FutureProvider<SettingsRepository>(
  (ref) async => (await ref.watch(storageBackendProvider.future)).settings,
);

// ---------------------------------------------------------------------------
// Notifications (M2): platform + scheduler + permission + coordinator.
// ---------------------------------------------------------------------------

/// Local-notification platform — swapped for a fake in widget tests.
final notificationPlatformProvider = Provider<NotificationPlatform>(
  (_) => LocalNotificationPlatform(),
);

/// Adapter that lazily resolves the (future-backed) settings repository so
/// the scheduler/coordinator can be plain classes over [SettingsRepository].
class _AsyncSettingsRepository implements SettingsRepository {
  _AsyncSettingsRepository(this._future);

  final Future<SettingsRepository> _future;

  @override
  Future<String?> get(String key) async => (await _future).get(key);

  @override
  Future<void> set(String key, String value) async =>
      (await _future).set(key, value);
}

final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  return NotificationScheduler(
    platform: ref.watch(notificationPlatformProvider),
    loadActive: () async {
      final repo = await ref.read(subscriptionRepositoryProvider.future);
      final all = await repo.getAll();
      return all
          .where((s) => s.status == SubscriptionStatus.active)
          .toList();
    },
    // M2.5 lifecycle (plan2_final §5): scan ALL rows and persist the automatic
    // PENDING_CANCELLATION → CANCELLED transition during reconcile().
    loadAll: () async {
      final repo = await ref.read(subscriptionRepositoryProvider.future);
      return repo.getAll();
    },
    updateSubscription: (sub) async {
      final repo = await ref.read(subscriptionRepositoryProvider.future);
      await repo.update(sub);
      // The scheduler persists lifecycle transitions (PENDING_CANCELLATION →
      // CANCELLED) outside the normal CRUD flow — refresh the UI so the list,
      // dashboard and free-tier slot count reflect the change (fix: previously
      // the transition happened silently until the next app data change).
      ref.invalidate(subscriptionListControllerProvider);
      ref.invalidate(dashboardControllerProvider);
    },
    settings:
        _AsyncSettingsRepository(ref.read(settingsRepositoryProvider.future)),
  );
});

final notificationPermissionServiceProvider =
    Provider<NotificationPermissionService>((ref) {
  return NotificationPermissionService(
    ref.watch(notificationPlatformProvider),
    _AsyncSettingsRepository(ref.read(settingsRepositoryProvider.future)),
  );
});

/// Platform store gateway (IAP) — swapped for a fake in tests.
final purchaseGatewayProvider = Provider<PurchaseGateway>(
  (_) => StorePurchaseGateway(),
);

/// Web fallback for the timezone name: no plugin available, so derive a
/// stable name from the browser's UTC offset. Only used for change-detection
/// (which never fires on web since the offset can't change mid-session).
String _webTimezoneName() {
  final offset = -DateTime.now().timeZoneOffset.inMinutes;
  final hours = offset ~/ 60;
  final minutes = (offset % 60).abs();
  final sign = hours >= 0 ? 'Etc/GMT+' : 'Etc/GMT-';
  // POSIX sign convention is inverted (Etc/GMT+7 == UTC-7).
  final magnitude = (hours.abs()).toString().padLeft(2, '0');
  return '$sign$magnitude:$minutes';
}

final notificationCoordinatorProvider = Provider<NotificationCoordinator>((ref) {
  return NotificationCoordinator(
    scheduler: ref.watch(notificationSchedulerProvider),
    permission: ref.watch(notificationPermissionServiceProvider),
    settings:
        _AsyncSettingsRepository(ref.read(settingsRepositoryProvider.future)),
    // Web has no timezone plugin — fall back to the local offset so the
    // scheduler keeps working (it stores an IANA name only for change
    // detection, which is a no-op on web anyway).
    currentTimezone: () async => kIsWeb
        ? _webTimezoneName()
        : (await FlutterTimezone.getLocalTimezone()).identifier,
  );
});
