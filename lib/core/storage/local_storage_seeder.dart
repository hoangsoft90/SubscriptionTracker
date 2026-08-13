import 'local_storage_store.dart';
import 'seed_data.dart';

/// Web counterpart of [Seeder] — writes the same default seed data (spec §6:
/// 11 default categories + `primaryCurrency` default) into a
/// [LocalStorageStore] instead of SQLite. Idempotent: existing rows are left
/// untouched, mirroring the SQLite [Seeder]'s conflict-ignore behavior.
class LocalStorageSeeder {
  LocalStorageSeeder(this._store);

  final LocalStorageStore _store;

  void seed() {
    if (_store.readRows(LocalStorageStore.categoriesKey).isEmpty) {
      _store.writeRows(LocalStorageStore.categoriesKey, [
        for (final category in seedDefaultCategories) category.toMap(),
      ]);
    }
    if (_store.getSetting('primaryCurrency') == null) {
      _store.setSetting('primaryCurrency', seedDefaultPrimaryCurrency);
    }
  }
}
