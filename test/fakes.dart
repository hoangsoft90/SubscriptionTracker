import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:subtrack/core/notifications/notification_platform.dart';
import 'package:subtrack/features/categories/data/category_repository.dart';
import 'package:subtrack/features/paywall/purchase_gateway.dart';
import 'package:subtrack/features/categories/domain/category.dart';
import 'package:subtrack/features/settings/data/settings_repository.dart';
import 'package:subtrack/features/subscriptions/data/subscription_repository.dart';
import 'package:subtrack/features/subscriptions/domain/price_history.dart';
import 'package:subtrack/features/subscriptions/domain/subscription.dart';
import 'package:subtrack/features/subscriptions/domain/subscription_status.dart';

/// In-memory [SubscriptionRepository] for widget tests — no sqflite, no
/// isolate, so it works inside the fake-async zone of `testWidgets`.
class FakeSubscriptionRepository implements SubscriptionRepository {
  FakeSubscriptionRepository([List<Subscription>? seed])
      : _rows = {for (final s in seed ?? const <Subscription>[]) s.id: s};

  final Map<String, Subscription> _rows;
  final Map<String, List<PriceHistoryEntry>> _history = {};

  @override
  Future<String> insert(Subscription subscription) async {
    _rows[subscription.id] = subscription;
    return subscription.id;
  }

  @override
  Future<void> update(Subscription subscription) async {
    _rows[subscription.id] = subscription;
  }

  @override
  Future<void> delete(String id) async {
    _rows.remove(id);
    _history.remove(id);
  }

  @override
  Future<Subscription?> getById(String id) async => _rows[id];

  @override
  Future<List<Subscription>> getAll() async => _rows.values.toList();

  @override
  Future<int> countByStatus(SubscriptionStatus status) async =>
      _rows.values.where((s) => s.status == status).length;

  @override
  Future<void> insertPriceHistory(PriceHistoryEntry entry) async {
    _history.putIfAbsent(entry.subscriptionId, () => []).add(entry);
  }

  @override
  Future<List<PriceHistoryEntry>> getPriceHistory(String subscriptionId) async =>
      List.unmodifiable(_history[subscriptionId] ?? const []);

  @override
  Future<void> deleteAll() async {
    _rows.clear();
    _history.clear();
  }
}

/// In-memory [CategoryRepository] for widget tests.
class FakeCategoryRepository implements CategoryRepository {
  FakeCategoryRepository([List<Category>? seed])
      : _rows = {for (final c in seed ?? const <Category>[]) c.id: c};

  final Map<String, Category> _rows;

  @override
  Future<List<Category>> getAll() async => _rows.values.toList();

  @override
  Future<String> insert(Category category) async {
    _rows[category.id] = category;
    return category.id;
  }

  @override
  Future<void> update(Category category) async {
    _rows[category.id] = category;
  }

  @override
  Future<void> delete(String id) async {
    _rows.remove(id);
  }

  @override
  Future<void> deleteAll() async {
    _rows.clear();
  }
}

/// In-memory [SettingsRepository] for widget tests.
class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository([Map<String, String>? seed])
      : _rows = {...?seed};

  final Map<String, String> _rows;

  @override
  Future<String?> get(String key) async => _rows[key];

  @override
  Future<void> set(String key, String value) async {
    _rows[key] = value;
  }
}

/// Scripted [PurchaseGateway] for tests — no store SDK involved.
class FakePurchaseGateway implements PurchaseGateway {
  FakePurchaseGateway({
    this.available = true,
    this.buyResult = PurchaseOutcome.purchased,
    this.restoreResult = PurchaseOutcome.purchased,
  });

  bool available;
  PurchaseOutcome buyResult;
  PurchaseOutcome restoreResult;
  int buyCalls = 0;
  int restoreCalls = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<ProductDetails?> getProduct() async => null;

  @override
  Future<PurchaseOutcome> buy() async {
    buyCalls++;
    return buyResult;
  }

  @override
  Future<PurchaseOutcome> restore() async {
    restoreCalls++;
    return restoreResult;
  }
}

/// No-op [NotificationPlatform] for tests — records scheduling so tests can
/// assert on current pending state and cancellations without platform
/// channels.
class FakeNotificationPlatform implements NotificationPlatform {
  /// History of every `schedule` call (append-only).
  final List<({int id, DateTime when})> scheduled = [];

  /// Current pending notifications: id → trigger time. Mirrors the OS state.
  final Map<int, DateTime> pending = {};

  /// IDs passed to `cancel`.
  final List<int> cancelled = [];

  bool permissionRequested = false;
  bool permissionGranted = true;
  bool settingsOpened = false;

  /// Current OS permission state reported by [permissionStatus].
  NotificationPermissionStatus status = NotificationPermissionStatus.enabled;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async {
    permissionRequested = true;
    // First request adopts [permissionGranted]; afterwards the OS keeps the
    // reported status in sync for subsequent status() reads.
    if (permissionGranted) {
      status = NotificationPermissionStatus.enabled;
    } else {
      status = NotificationPermissionStatus.disabled;
    }
    return permissionGranted;
  }

  @override
  Future<NotificationPermissionStatus> permissionStatus() async => status;

  @override
  Future<void> openNotificationSettings() async {
    settingsOpened = true;
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    scheduled.add((id: id, when: when));
    pending[id] = when;
  }

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
    pending.remove(id);
  }

  @override
  Future<void> cancelAll() async {
    scheduled.clear();
    cancelled.clear();
    pending.clear();
  }
}
