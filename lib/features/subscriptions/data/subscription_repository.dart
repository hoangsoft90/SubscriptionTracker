import 'package:sqflite/sqflite.dart';

import '../domain/price_history.dart';
import '../domain/subscription.dart';
import '../domain/subscription_status.dart';

/// Typed access to subscription rows. Implementations never leak raw SQL to
/// callers.
abstract class SubscriptionRepository {
  Future<String> insert(Subscription subscription);
  Future<void> update(Subscription subscription);
  Future<void> delete(String id);
  Future<Subscription?> getById(String id);
  Future<List<Subscription>> getAll();
  Future<int> countByStatus(SubscriptionStatus status);

  /// Records a price change (plan2_final §7). Rows cascade-delete with the
  /// subscription.
  Future<void> insertPriceHistory(PriceHistoryEntry entry);

  /// Price history for [subscriptionId], oldest first.
  Future<List<PriceHistoryEntry>> getPriceHistory(String subscriptionId);

  /// Removes every row (used by backup "Replace All" — never called from
  /// normal app flows).
  Future<void> deleteAll();
}

/// sqflite-backed [SubscriptionRepository].
class SqfliteSubscriptionRepository implements SubscriptionRepository {
  SqfliteSubscriptionRepository(this._db);

  static const _table = 'subscriptions';
  final Database _db;

  @override
  Future<String> insert(Subscription subscription) async {
    await _db.insert(_table, subscription.toMap());
    return subscription.id;
  }

  @override
  Future<void> update(Subscription subscription) async {
    await _db.update(
      _table,
      subscription.toMap(),
      where: 'id = ?',
      whereArgs: [subscription.id],
    );
  }

  @override
  Future<void> delete(String id) async {
    await _db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<Subscription?> getById(String id) async {
    final rows = await _db.query(_table, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Subscription.fromMap(rows.first);
  }

  @override
  Future<List<Subscription>> getAll() async {
    final rows = await _db.query(_table);
    return rows.map(Subscription.fromMap).toList();
  }

  @override
  Future<int> countByStatus(SubscriptionStatus status) async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM $_table WHERE status = ?',
      [status.dbValue],
    );
    return (result.first['c']! as int);
  }

  static const _priceHistoryTable = 'subscription_price_history';

  @override
  Future<void> insertPriceHistory(PriceHistoryEntry entry) async {
    await _db.insert(_priceHistoryTable, entry.toMap());
  }

  @override
  Future<List<PriceHistoryEntry>> getPriceHistory(String subscriptionId) async {
    final rows = await _db.query(
      _priceHistoryTable,
      where: 'subscription_id = ?',
      whereArgs: [subscriptionId],
      orderBy: 'effective_from ASC',
    );
    return rows.map(PriceHistoryEntry.fromMap).toList();
  }

  @override
  Future<void> deleteAll() async {
    await _db.delete(_priceHistoryTable);
    await _db.delete(_table);
  }
}
