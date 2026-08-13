import '../../../core/storage/local_storage_store.dart';
import '../domain/price_history.dart';
import '../domain/subscription.dart';
import '../domain/subscription_status.dart';
import 'subscription_repository.dart';

/// localStorage-backed [SubscriptionRepository] for the web.
///
/// Same interface and same row shapes as [SqfliteSubscriptionRepository]
/// (`Subscription.toMap()` / `Subscription.fromMap()`), so controllers and
/// business logic are identical across platforms — only the persistence
/// medium differs. All mutations are persisted synchronously into the
/// browser's localStorage through [LocalStorageStore].
class LocalStorageSubscriptionRepository implements SubscriptionRepository {
  LocalStorageSubscriptionRepository(this._store);

  final LocalStorageStore _store;

  @override
  Future<String> insert(Subscription subscription) async {
    final rows = _store.readRows(LocalStorageStore.subscriptionsKey);
    // Upsert by id (the app never inserts a duplicate uuid, but being
    // idempotent here prevents row duplication in any path that re-inserts).
    rows.removeWhere((r) => r['id'] == subscription.id);
    rows.add(subscription.toMap());
    _store.writeRows(LocalStorageStore.subscriptionsKey, rows);
    return subscription.id;
  }

  @override
  Future<void> update(Subscription subscription) async {
    final rows = _store.readRows(LocalStorageStore.subscriptionsKey);
    final index = rows.indexWhere((r) => r['id'] == subscription.id);
    if (index == -1) return;
    rows[index] = subscription.toMap();
    _store.writeRows(LocalStorageStore.subscriptionsKey, rows);
  }

  @override
  Future<void> delete(String id) async {
    final rows = _store.readRows(LocalStorageStore.subscriptionsKey);
    rows.removeWhere((r) => r['id'] == id);
    _store.writeRows(LocalStorageStore.subscriptionsKey, rows);

    // Mirror the SQLite ON DELETE CASCADE for price history.
    final history = _store.readPriceHistory();
    if (history.remove(id) != null) {
      _store.writePriceHistory(history);
    }
  }

  @override
  Future<Subscription?> getById(String id) async {
    final rows = _store.readRows(LocalStorageStore.subscriptionsKey);
    for (final row in rows) {
      if (row['id'] == id) return Subscription.fromMap(row);
    }
    return null;
  }

  @override
  Future<List<Subscription>> getAll() async {
    return _store
        .readRows(LocalStorageStore.subscriptionsKey)
        .map(Subscription.fromMap)
        .toList();
  }

  @override
  Future<int> countByStatus(SubscriptionStatus status) async {
    return _store
        .readRows(LocalStorageStore.subscriptionsKey)
        .where((r) => r['status'] == status.dbValue)
        .length;
  }

  @override
  Future<void> insertPriceHistory(PriceHistoryEntry entry) async {
    final history = _store.readPriceHistory();
    history.putIfAbsent(entry.subscriptionId, () => []).add(entry.toMap());
    _store.writePriceHistory(history);
  }

  @override
  Future<List<PriceHistoryEntry>> getPriceHistory(String subscriptionId) async {
    final rows = _store.readPriceHistory()[subscriptionId] ?? const [];
    final sorted = [...rows]
      ..sort((a, b) => (a['effective_from']! as String)
          .compareTo(b['effective_from']! as String));
    return sorted.map(PriceHistoryEntry.fromMap).toList();
  }

  @override
  Future<void> deleteAll() async {
    _store.writeRows(LocalStorageStore.subscriptionsKey, const []);
    _store.writePriceHistory(const {});
  }
}
