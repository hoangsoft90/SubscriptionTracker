import '../../../core/storage/local_storage_store.dart';
import 'settings_repository.dart';

/// localStorage-backed [SettingsRepository] for the web — same interface as
/// [SqfliteSettingsRepository]; key/value rows live in the browser's
/// localStorage through [LocalStorageStore].
class LocalStorageSettingsRepository implements SettingsRepository {
  LocalStorageSettingsRepository(this._store);

  final LocalStorageStore _store;

  @override
  Future<String?> get(String key) async => _store.getSetting(key);

  @override
  Future<void> set(String key, String value) async =>
      _store.setSetting(key, value);
}
