import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:subtrack/core/providers.dart';
import 'package:subtrack/core/storage/app_database.dart';
import 'package:subtrack/core/storage/migrations.dart';
import 'package:subtrack/core/storage/seeder.dart';
import 'package:subtrack/features/categories/data/category_repository.dart';
import 'package:subtrack/features/settings/data/settings_repository.dart';
import 'package:subtrack/features/subscriptions/data/subscription_repository.dart';

/// Test harness: fresh in-memory sqflite with migrations + seed, exposed
/// through the real repository providers.
///
/// NOTE (Riverpod 3): the `Override` type name is not part of the public
/// exports, so override lists must be written as *inline list literals*
/// directly at the `ProviderContainer(overrides:)` / `ProviderScope(overrides:)`
/// call site — a helper returning `List<Object>` won't type-check. We therefore
/// keep the literal inside [container] and [scope] below.
class TestDb {
  TestDb._(this.database);

  final Database database;

  static Future<TestDb> create({bool onboardingCompleted = true}) async {
    sqfliteFfiInit();
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute('PRAGMA foreign_keys = ON');
    await DatabaseMigrationRunner(AppDatabase.migrations).run(db);
    await Seeder(db).seed();

    final settingsRepo = SqfliteSettingsRepository(db);
    if (onboardingCompleted) {
      await settingsRepo.set('onboardingCompleted', 'true');
      await settingsRepo.set('primaryCurrency', 'USD');
    }

    return TestDb._(db);
  }

  /// A ProviderContainer wired to this in-memory database (unit tests).
  ProviderContainer container() {
    return ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(AsyncValue.data(database)),
      subscriptionRepositoryProvider.overrideWith(
          (ref) => SqfliteSubscriptionRepository(database)),
      categoryRepositoryProvider.overrideWith(
          (ref) => SqfliteCategoryRepository(database)),
      settingsRepositoryProvider.overrideWith(
          (ref) => SqfliteSettingsRepository(database)),
    ]);
  }

  /// A ProviderScope wired to this in-memory database (widget tests).
  ProviderScope scope({required Widget child}) {
    return ProviderScope(overrides: [
      databaseProvider.overrideWithValue(AsyncValue.data(database)),
      subscriptionRepositoryProvider.overrideWith(
          (ref) => SqfliteSubscriptionRepository(database)),
      categoryRepositoryProvider.overrideWith(
          (ref) => SqfliteCategoryRepository(database)),
      settingsRepositoryProvider.overrideWith(
          (ref) => SqfliteSettingsRepository(database)),
    ], child: child);
  }
}

Future<void> closeTestDb(TestDb harness) async {
  await harness.database.close();
}
