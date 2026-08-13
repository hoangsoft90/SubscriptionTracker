import 'package:flutter_test/flutter_test.dart';

import 'package:subtrack/core/providers.dart';
import 'package:subtrack/features/backup/backup_models.dart';
import 'package:subtrack/features/backup/export_service.dart';
import 'package:subtrack/features/backup/import_service.dart';
import 'package:subtrack/features/categories/domain/category.dart';
import 'package:subtrack/features/subscriptions/domain/billing_cycle.dart';
import 'package:subtrack/features/subscriptions/domain/subscription.dart';
import 'package:subtrack/features/subscriptions/domain/subscription_status.dart';

import 'm1_support.dart';
import 'fakes.dart';

Subscription _sub(String id, String name,
    {int amount = 999, String? categoryId}) {
  return Subscription(
    id: id,
    name: name,
    amountMinor: amount,
    currency: 'USD',
    billingCycle: BillingCycle.monthly,
    startDate: DateTime(2026, 1, 1),
    nextBillingDate: DateTime(2026, 8, 15),
    billingAnchorDay: 1,
    isTrial: false,
    status: SubscriptionStatus.active,
    categoryId: categoryId,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

Category _cat(String id, String name, {bool isDefault = false}) {
  return Category(id: id, name: name, iconEmoji: '📺', isDefault: isDefault);
}

void main() {
  group('Export (spec §2.6)', () {
    test('produces a valid versioned backup with marker + full data',
        () async {
      final subs = FakeSubscriptionRepository([
        _sub('s1', 'Netflix', amount: 1499),
        _sub('s2', 'Spotify', amount: 1099),
      ]);
      final cats = FakeCategoryRepository([
        _cat('streaming', 'Streaming', isDefault: true),
      ]);
      final settings = FakeSettingsRepository({'primaryCurrency': 'VND'});

      final service = BackupExportService(
        subscriptions: subs,
        categories: cats,
        settings: settings,
      );
      final file = await service.buildFile(now: DateTime.utc(2026, 8, 10));
      final json = file.encode();

      expect(json, contains(BackupFormat.formatMarker));
      expect(file.schemaVersion, BackupFormat.currentSchemaVersion);
      expect(file.subscriptionCount, 2);
      expect(file.categoryCount, 1);
      expect(file.settings['primaryCurrency'], 'VND');

      // Round-trip: decode → identical counts.
      final decoded = BackupFile.decode(json);
      expect(decoded.subscriptionCount, 2);
      expect(decoded.categoryCount, 1);
      expect(decoded.settings['primaryCurrency'], 'VND');
    });

    test('export→import round-trip restores 100% (DoD 2.6)', () async {
      final source = FakeSubscriptionRepository([
        _sub('s1', 'Netflix', amount: 1499),
        _sub('s2', 'Spotify', amount: 1099),
      ]);
      final sourceCats = FakeCategoryRepository([
        _cat('streaming', 'Streaming', isDefault: true),
        _cat('music', 'Music'),
      ]);
      final sourceSettings = FakeSettingsRepository({'primaryCurrency': 'EUR'});
      final file = await BackupExportService(
        subscriptions: source,
        categories: sourceCats,
        settings: sourceSettings,
      ).buildFile();

      // Fresh "device" (empty repos) + Replace All.
      final dest = FakeSubscriptionRepository();
      final destCats = FakeCategoryRepository();
      final destSettings = FakeSettingsRepository();
      final importer = BackupImportService(
        subscriptions: dest,
        categories: destCats,
        settings: destSettings,
      );

      final result = await importer.apply(
        file,
        strategy: ImportStrategy.replaceAll,
      );
      expect(result.importedSubscriptions, 2);
      expect(result.importedCategories, 2);

      final restored = await dest.getAll();
      expect(restored.length, 2);
      expect(
        {for (final s in restored) s.name},
        {'Netflix', 'Spotify'},
      );
      expect((await destCats.getAll()).length, 2);
      expect(await destSettings.get('primaryCurrency'), 'EUR');
    });
  });

  group('Validation (spec §2.6)', () {
    test('rejects a non-backup JSON file before any mutation', () async {
      final dest = FakeSubscriptionRepository();

      expect(
        () => BackupFile.decode('{"foo": "bar"}'),
        throwsA(isA<BackupValidationException>()),
      );
      // Nothing was touched.
      expect(await dest.getAll(), isEmpty);
    });

    test('rejects garbage that is not JSON', () {
      expect(
        () => BackupFile.decode('not json at all'),
        throwsA(isA<BackupValidationException>()),
      );
    });

    test('rejects a future schemaVersion', () {
      final future = BackupFile(
        schemaVersion: BackupFormat.currentSchemaVersion + 1,
        exportedAt: DateTime.now(),
        appVersion: '99.0.0',
        settings: const {},
        categories: const [],
        subscriptions: const [],
      ).encode();
      try {
        BackupFile.decode(future);
        fail('should have thrown');
      } on BackupValidationException catch (e) {
        expect(e.isFutureVersion, isTrue);
      }
    });

    test('preview shows counts before any mutation', () async {
      final file = BackupFile(
        schemaVersion: 1,
        exportedAt: DateTime.now(),
        appVersion: '1.0.0',
        settings: const {'primaryCurrency': 'VND'},
        categories: [
          _cat('streaming', 'Streaming').toMap(),
        ],
        subscriptions: [
          _sub('s1', 'Netflix').toMap(),
          _sub('s2', 'Spotify').toMap(),
        ],
      );
      final importer = BackupImportService(
        subscriptions: FakeSubscriptionRepository(),
        categories: FakeCategoryRepository(),
        settings: FakeSettingsRepository(),
      );
      final preview = await importer.preview(file.encode());
      expect(preview.subscriptionCount, 2);
      expect(preview.categoryCount, 1);
      expect(preview.settingsSummary, 'primaryCurrency=VND');
    });
  });

  group('Merge (spec §2.6)', () {
    test('skips existing IDs and inserts new rows — no duplicates', () async {
      final backup = BackupFile(
        schemaVersion: 1,
        exportedAt: DateTime.now(),
        appVersion: '1.0.0',
        settings: const {},
        categories: [_cat('streaming', 'Streaming').toMap()],
        subscriptions: [
          _sub('s1', 'Netflix').toMap(),
          _sub('s2', 'Spotify').toMap(),
        ],
      );
      final dest = FakeSubscriptionRepository([_sub('s1', 'Netflix Old')]);
      final destCats = FakeCategoryRepository([_cat('streaming', 'Streaming')]);
      final destSettings = FakeSettingsRepository();
      final importer = BackupImportService(
        subscriptions: dest,
        categories: destCats,
        settings: destSettings,
      );

      // First merge: s2 is new.
      var result = await importer.apply(backup, strategy: ImportStrategy.merge);
      expect(result.importedSubscriptions, 1);
      expect(result.importedCategories, 0);

      // Re-import with merge: no duplicates (both IDs exist now).
      result = await importer.apply(backup, strategy: ImportStrategy.merge);
      expect(result.importedSubscriptions, 0);

      final all = await dest.getAll();
      expect(all.length, 2);
      // Existing row was kept untouched.
      expect(all.firstWhere((s) => s.id == 's1').name, 'Netflix Old');
    });

    test('merge applies settings only when unset', () async {
      final backup = BackupFile(
        schemaVersion: 1,
        exportedAt: DateTime.now(),
        appVersion: '1.0.0',
        settings: const {'primaryCurrency': 'VND'},
        categories: const [],
        subscriptions: const [],
      );
      final destSettings = FakeSettingsRepository({'primaryCurrency': 'USD'});
      final importer = BackupImportService(
        subscriptions: FakeSubscriptionRepository(),
        categories: FakeCategoryRepository(),
        settings: destSettings,
      );
      await importer.apply(backup, strategy: ImportStrategy.merge);
      expect(await destSettings.get('primaryCurrency'), 'USD');
    });
  });

  group('Replace All (spec §2.6)', () {
    test('wipes existing data then restores the backup', () async {
      final backup = BackupFile(
        schemaVersion: 1,
        exportedAt: DateTime.now(),
        appVersion: '1.0.0',
        settings: const {'primaryCurrency': 'JPY'},
        categories: [_cat('music', 'Music').toMap()],
        subscriptions: [_sub('s9', 'From Backup').toMap()],
      );
      final dest = FakeSubscriptionRepository([
        _sub('old1', 'Old 1'),
        _sub('old2', 'Old 2'),
      ]);
      final destCats = FakeCategoryRepository([_cat('streaming', 'Streaming')]);
      final destSettings = FakeSettingsRepository({'primaryCurrency': 'USD'});
      final importer = BackupImportService(
        subscriptions: dest,
        categories: destCats,
        settings: destSettings,
      );

      final result =
          await importer.apply(backup, strategy: ImportStrategy.replaceAll);
      expect(result.importedSubscriptions, 1);
      expect(result.importedCategories, 1);

      final all = await dest.getAll();
      expect(all.length, 1);
      expect(all.single.name, 'From Backup');
      expect((await destCats.getAll()).single.name, 'Music');
      expect(await destSettings.get('primaryCurrency'), 'JPY');
    });

    test('wipes children before parents on real sqlite (FK order)', () async {
      // Regression: deleting categories while subscriptions still reference
      // them violates `PRAGMA foreign_keys = ON`. The fake repositories used
      // by the other tests don't enforce FK, so this test runs on real
      // in-memory sqlite to prove Replace All no longer crashes.
      final harness = await TestDb.create();
      addTearDown(() => closeTestDb(harness));
      final container = harness.container();
      addTearDown(container.dispose);

      final subs = await container.read(subscriptionRepositoryProvider.future);
      final cats = await container.read(categoryRepositoryProvider.future);
      final settings =
          await container.read(settingsRepositoryProvider.future);

      // Existing rows: a category (non-seed id, to avoid colliding with the
      // Seeder's defaults) + a subscription that references it.
      await cats.insert(_cat('custom-old', 'Old Cat'));
      await subs.insert(_sub('old1', 'Old 1', categoryId: 'custom-old'));

      final backup = BackupFile(
        schemaVersion: 1,
        exportedAt: DateTime.now(),
        appVersion: '1.0.0',
        settings: const {'primaryCurrency': 'USD'},
        categories: [_cat('custom-new', 'New Cat').toMap()],
        subscriptions: [_sub('s9', 'From Backup', categoryId: 'custom-new').toMap()],
      );
      final importer = BackupImportService(
        subscriptions: subs,
        categories: cats,
        settings: settings,
      );

      final result =
          await importer.apply(backup, strategy: ImportStrategy.replaceAll);
      expect(result.importedSubscriptions, 1);
      expect(result.importedCategories, 1);
      expect((await subs.getAll()).single.name, 'From Backup');
      expect((await cats.getAll()).single.name, 'New Cat');
    });
  });
}
