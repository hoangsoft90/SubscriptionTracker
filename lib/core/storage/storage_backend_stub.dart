import 'package:sqflite/sqflite.dart';

import '../../features/categories/data/category_repository.dart';
import '../../features/settings/data/settings_repository.dart';
import '../../features/subscriptions/data/subscription_repository.dart';
import 'app_database.dart';
import 'storage_backend.dart';

export 'storage_backend.dart';

/// SQLite-backed [StorageBackend] for native platforms (iOS/Android).
///
/// Holds the single app [Database] (migrated + seeded) and exposes it through
/// the three typed repositories.
class SqliteStorageBackend implements StorageBackend {
  SqliteStorageBackend(Database db)
      : subscriptions = SqfliteSubscriptionRepository(db),
        categories = SqfliteCategoryRepository(db),
        settings = SqfliteSettingsRepository(db);

  @override
  final SubscriptionRepository subscriptions;

  @override
  final CategoryRepository categories;

  @override
  final SettingsRepository settings;
}

/// Native factory: opens the app database (migrations + seed, spec §6) and
/// wraps it in the sqflite repositories.
Future<StorageBackend> createStorageBackend() async {
  final db = await AppDatabase.open();
  return SqliteStorageBackend(db);
}
