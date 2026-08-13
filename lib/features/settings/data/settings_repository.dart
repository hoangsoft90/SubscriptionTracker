import 'package:sqflite/sqflite.dart';

/// Typed access to the key/value app_settings table.
abstract class SettingsRepository {
  Future<String?> get(String key);
  Future<void> set(String key, String value);
}

/// sqflite-backed [SettingsRepository].
class SqfliteSettingsRepository implements SettingsRepository {
  SqfliteSettingsRepository(this._db);

  static const _table = 'app_settings';
  final Database _db;

  @override
  Future<String?> get(String key) async {
    final rows =
        await _db.query(_table, columns: ['value'], where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value']! as String;
  }

  @override
  Future<void> set(String key, String value) async {
    await _db.insert(
      _table,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
