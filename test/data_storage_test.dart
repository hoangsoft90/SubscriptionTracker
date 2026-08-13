import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:subtrack/core/storage/app_database.dart';
import 'package:subtrack/core/storage/migrations.dart';
import 'package:subtrack/core/storage/seeder.dart';
import 'package:subtrack/features/categories/data/category_repository.dart';
import 'package:subtrack/features/categories/domain/category.dart';
import 'package:subtrack/features/settings/data/settings_repository.dart';
import 'package:subtrack/features/subscriptions/data/subscription_repository.dart';
import 'package:subtrack/features/subscriptions/domain/billing_cycle.dart';
import 'package:subtrack/features/subscriptions/domain/price_history.dart';
import 'package:subtrack/features/subscriptions/domain/subscription.dart';
import 'package:subtrack/features/subscriptions/domain/subscription_status.dart';

void main() {
  sqfliteFfiInit();

  late DatabaseFactory factory;
  late Database db;

  setUp(() async {
    factory = databaseFactoryFfi;
    db = await factory.openDatabase(inMemoryDatabasePath);
    await db.execute('PRAGMA foreign_keys = ON');
    await DatabaseMigrationRunner(AppDatabase.migrations).run(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Schema & migrations', () {
    test('fresh database has all tables and user_version = 2', () async {
      expect(await db.getVersion(), 2);
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
      );
      final names = tables.map((r) => r['name']).toSet();
      expect(
        names,
        containsAll(['categories', 'subscriptions', 'app_settings', 'subscription_price_history']),
      );
    });

    test('indexes created', () async {
      final indexes = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='subscriptions'",
      );
      final names = indexes.map((r) => r['name']).toSet();
      expect(
        names,
        containsAll(['idx_sub_next_billing', 'idx_sub_status', 'idx_sub_category']),
      );
      final hist = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='subscription_price_history'",
      );
      expect(hist.map((r) => r['name']), contains('idx_price_history_sub'));
    });

    test('foreign key enforcement rejects unknown category', () async {
      final repo = SqfliteSubscriptionRepository(db);
      final sub = _sampleSubscription(categoryId: 'missing-category');
      expect(() => repo.insert(sub), throwsA(isA<DatabaseException>()));
    });

    test('v2 columns + price history exist after migration', () async {
      final cols = await db.rawQuery('PRAGMA table_info(subscriptions)');
      final names = cols.map((r) => r['name']).toSet();
      expect(
        names,
        containsAll([
          'last_reviewed_at',
          'review_interval_days',
          'pending_cancellation',
          'cancelled_at',
          'previous_amount_minor',
          'superseded_at',
        ]),
      );
    });

    test('migration 1→2 forward preserves data', () async {
      // The shared `db` is already at v2 (setUp runs the full migration list),
      // so simulate an existing v1 database on a separate file DB: apply only
      // v1, seed data, then run the full runner — data must survive the v2
      // ALTERs and the new table must exist.
      final dbPath = '${Directory.systemTemp.path}/subtrack_migration_v1_test.db';
      final db1 = await factory.openDatabase(dbPath);
      addTearDown(() async {
        await db1.close();
        await factory.deleteDatabase(dbPath);
      });
      await db1.execute('PRAGMA foreign_keys = ON');
      await DatabaseMigrationRunner([AppDatabase.migrations.first]).run(db1);
      expect(await db1.getVersion(), 1);

      final categoryRepo = SqfliteCategoryRepository(db1);
      await categoryRepo.insert(const Category(id: 'cat-a', name: 'Cat A'));
      final repo = SqfliteSubscriptionRepository(db1);
      final sub = _sampleSubscription(categoryId: 'cat-a');
      // Seed with the *legacy* v1 row shape (the new model would write the
      // v2-only columns which don't exist yet on a v1 database — exactly the
      // real-world situation of an old app writing, then upgrading).
      final legacyRow = sub.toMap()..removeWhere((k, _) => const {
            'last_reviewed_at',
            'review_interval_days',
            'pending_cancellation',
            'cancelled_at',
            'previous_amount_minor',
            'superseded_at',
          }.contains(k));
      await db1.insert('subscriptions', legacyRow);

      await DatabaseMigrationRunner(AppDatabase.migrations).run(db1);

      expect(await db1.getVersion(), 2);
      final tables = await db1.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );
      expect(tables.map((r) => r['name']), contains('subscription_price_history'));
      final restored = await repo.getById(sub.id);
      expect(restored, isNotNull);
      expect(restored!.name, sub.name);
      expect(restored.amountMinor, sub.amountMinor);
      expect(restored.nextBillingDate, sub.nextBillingDate);
      expect(restored.lastReviewedAt, isNull); // new column defaults to null
      expect(restored.reviewIntervalDays, 90);
    });

    test('re-running migrations is a no-op', () async {
      final runner = DatabaseMigrationRunner(AppDatabase.migrations);
      await runner.run(db); // already at v2
      expect(await db.getVersion(), 2);
      final count = SqfliteCategoryRepository(db);
      expect(await count.getAll(), isEmpty); // nothing destructive happened
    });
  });

  group('CategoryRepository', () {
    test('CRUD round-trip', () async {
      final repo = SqfliteCategoryRepository(db);
      final category =
          const Category(id: 'cat-1', name: 'Streaming', iconEmoji: '📺', colorHex: '#000000');
      await repo.insert(category);

      final all = await repo.getAll();
      expect(all.length, 1);
      expect(all.first.id, 'cat-1');
      expect(all.first.name, 'Streaming');
      expect(all.first.iconEmoji, '📺');
      expect(all.first.colorHex, '#000000');
      expect(all.first.isDefault, isFalse);

      await repo.update(category.copyWith(name: 'Streaming+'));
      final updated = (await repo.getAll()).first;
      expect(updated.name, 'Streaming+');

      await repo.delete('cat-1');
      expect(await repo.getAll(), isEmpty);
    });

    test('default category cannot be deleted', () async {
      final repo = SqfliteCategoryRepository(db);
      await repo.insert(
          const Category(id: 'def', name: 'Default', isDefault: true));
      expect(() => repo.delete('def'), throwsArgumentError);
    });
  });

  group('SettingsRepository', () {
    test('set and get round-trip with upsert', () async {
      final repo = SqfliteSettingsRepository(db);
      expect(await repo.get('primaryCurrency'), isNull);
      await repo.set('primaryCurrency', 'USD');
      expect(await repo.get('primaryCurrency'), 'USD');
      await repo.set('primaryCurrency', 'VND');
      expect(await repo.get('primaryCurrency'), 'VND');
    });
  });

  group('SubscriptionRepository', () {
    test('CRUD round-trip preserves all fields incl. dates', () async {
      final repo = SqfliteSubscriptionRepository(db);
      final categoryRepo = SqfliteCategoryRepository(db);
      await categoryRepo.insert(const Category(id: 'cat-a', name: 'Cat A'));

      final sub = _sampleSubscription(categoryId: 'cat-a');
      await repo.insert(sub);

      final restored = await repo.getById(sub.id);
      expect(restored, isNotNull);
      expect(restored!.name, 'Netflix');
      expect(restored.amountMinor, 1499);
      expect(restored.currency, 'USD');
      expect(restored.billingCycle, BillingCycle.monthly);
      expect(restored.startDate, DateTime(2026, 8, 1));
      expect(restored.nextBillingDate, DateTime(2026, 8, 31));
      expect(restored.billingAnchorDay, 31);
      expect(restored.isTrial, isTrue);
      expect(restored.trialEndDate, DateTime(2026, 9, 15));
      expect(restored.cancellationUrl, 'https://example.com/cancel');
      expect(restored.status, SubscriptionStatus.active);
      expect(restored.categoryId, 'cat-a');
      expect(restored.reminderDaysBefore, [3, 1]);
      expect(restored.notes, 'Family plan');
    });

    test('update modifies row', () async {
      final repo = SqfliteSubscriptionRepository(db);
      final sub = _sampleSubscription();
      await repo.insert(sub);

      final updated = sub.copyWith(
        amountMinor: 1999,
        status: SubscriptionStatus.cancelled,
        updatedAt: DateTime(2026, 8, 2),
      );
      await repo.update(updated);

      final restored = await repo.getById(sub.id);
      expect(restored!.amountMinor, 1999);
      expect(restored.status, SubscriptionStatus.cancelled);
    });

    test('delete removes row', () async {
      final repo = SqfliteSubscriptionRepository(db);
      final sub = _sampleSubscription();
      await repo.insert(sub);
      await repo.delete(sub.id);
      expect(await repo.getById(sub.id), isNull);
    });

    test('countByStatus', () async {
      final repo = SqfliteSubscriptionRepository(db);
      await repo.insert(_sampleSubscription());
      await repo.insert(_sampleSubscription(id: 's2', status: SubscriptionStatus.cancelled));
      expect(await repo.countByStatus(SubscriptionStatus.active), 1);
      expect(await repo.countByStatus(SubscriptionStatus.cancelled), 1);
    });

    test('deleting an in-use custom category unassigns subscriptions', () async {
      final repo = SqfliteSubscriptionRepository(db);
      final categoryRepo = SqfliteCategoryRepository(db);
      await categoryRepo.insert(const Category(id: 'cat-x', name: 'Custom'));
      await repo.insert(_sampleSubscription(categoryId: 'cat-x'));

      await categoryRepo.delete('cat-x');

      final restored = await repo.getById('sub-1');
      expect(restored, isNotNull);
      expect(restored!.categoryId, isNull); // unassigned, row not lost
      expect(await categoryRepo.getAll(), isEmpty);
    });
  });

  group('Price history (plan2_final §7)', () {
    test('insertPriceHistory persists; getPriceHistory returns oldest first',
        () async {
      final repo = SqfliteSubscriptionRepository(db);
      final sub = _sampleSubscription();
      await repo.insert(sub);

      await repo.insertPriceHistory(PriceHistoryEntry(
        id: 'h1',
        subscriptionId: sub.id,
        amountMinor: 1499,
        currency: 'USD',
        effectiveFrom: DateTime(2026, 7, 1),
        createdAt: DateTime(2026, 7, 1),
      ));
      await repo.insertPriceHistory(PriceHistoryEntry(
        id: 'h2',
        subscriptionId: sub.id,
        amountMinor: 1999,
        currency: 'USD',
        effectiveFrom: DateTime(2026, 8, 1),
        createdAt: DateTime(2026, 8, 1),
      ));

      final history = await repo.getPriceHistory(sub.id);
      expect(history.length, 2);
      expect(history.first.id, 'h1');
      expect(history.first.amountMinor, 1499);
      expect(history.last.amountMinor, 1999);
    });

    test('deleting a subscription cascades its price history', () async {
      final repo = SqfliteSubscriptionRepository(db);
      final sub = _sampleSubscription();
      await repo.insert(sub);
      await repo.insertPriceHistory(PriceHistoryEntry(
        id: 'h1',
        subscriptionId: sub.id,
        amountMinor: 1499,
        currency: 'USD',
        effectiveFrom: DateTime(2026, 7, 1),
        createdAt: DateTime(2026, 7, 1),
      ));

      await repo.delete(sub.id);
      expect(await repo.getPriceHistory(sub.id), isEmpty);
    });
  });

  group('Seeder', () {
    test('seeds 11 default categories + primaryCurrency idempotently', () async {
      final seeder = Seeder(db);
      await seeder.seed();
      await seeder.seed(); // second run must not duplicate

      final categoryRepo = SqfliteCategoryRepository(db);
      final categories = await categoryRepo.getAll();
      expect(categories.length, 11);
      expect(categories.where((c) => c.isDefault).length, 11);

      final settingsRepo = SqfliteSettingsRepository(db);
      expect(await settingsRepo.get('primaryCurrency'), 'USD');
    });
  });
}

Subscription _sampleSubscription({
  String id = 'sub-1',
  SubscriptionStatus status = SubscriptionStatus.active,
  String? categoryId,
}) {
  return Subscription(
    id: id,
    name: 'Netflix',
    amountMinor: 1499,
    currency: 'USD',
    billingCycle: BillingCycle.monthly,
    startDate: DateTime(2026, 8, 1),
    nextBillingDate: DateTime(2026, 8, 31),
    billingAnchorDay: 31,
    isTrial: true,
    trialEndDate: DateTime(2026, 9, 15),
    cancellationUrl: 'https://example.com/cancel',
    status: status,
    categoryId: categoryId,
    color: 0xFFE50914,
    iconEmoji: '📺',
    reminderDaysBefore: const [3, 1],
    notes: 'Family plan',
    createdAt: DateTime(2026, 8, 1),
    updatedAt: DateTime(2026, 8, 1),
  );
}
