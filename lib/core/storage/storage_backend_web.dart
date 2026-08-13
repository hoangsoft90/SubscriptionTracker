import 'package:web/web.dart' as web;

import '../../features/categories/data/category_repository.dart';
import '../../features/categories/data/local_storage_category_repository.dart';
import '../../features/settings/data/settings_repository.dart';
import '../../features/settings/data/local_storage_settings_repository.dart';
import '../../features/subscriptions/data/subscription_repository.dart';
import '../../features/subscriptions/data/local_storage_subscription_repository.dart';
import 'local_storage_seeder.dart';
import 'local_storage_store.dart';
import 'storage_backend.dart';

export 'storage_backend.dart';

/// Browser `localStorage`-backed [KeyValueStorage] (web only).
class BrowserLocalStorage implements KeyValueStorage {
  @override
  String? getItem(String key) => web.window.localStorage.getItem(key);

  @override
  void setItem(String key, String value) =>
      web.window.localStorage.setItem(key, value);

  @override
  void removeItem(String key) => web.window.localStorage.removeItem(key);
}

/// localStorage-backed [StorageBackend] for the web.
///
/// Replaces SQLite on web (which had to ship a WASM-compiled sqlite via
/// `sqflite_common_ffi_web`): all rows live in the browser's localStorage as
/// JSON under the `subtrack_` prefix, with the same row shapes and repository
/// interfaces — business logic is unchanged.
class LocalStorageBackend implements StorageBackend {
  LocalStorageBackend(this._store)
      : subscriptions = LocalStorageSubscriptionRepository(_store),
        categories = LocalStorageCategoryRepository(_store),
        settings = LocalStorageSettingsRepository(_store) {
    LocalStorageSeeder(_store).seed();
  }

  final LocalStorageStore _store;

  @override
  final SubscriptionRepository subscriptions;

  @override
  final CategoryRepository categories;

  @override
  final SettingsRepository settings;
}

/// Web factory: builds the localStorage backend over `BrowserLocalStorage`
/// (defaults seeded idempotently, mirroring the SQLite [Seeder]).
Future<StorageBackend> createStorageBackend() async {
  return LocalStorageBackend(LocalStorageStore(BrowserLocalStorage()));
}
