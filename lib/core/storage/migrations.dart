import 'package:sqflite/sqflite.dart';

/// A single schema migration: a function applied inside a transaction.
class Migration {
  const Migration(this.version, this.up);

  /// Schema version this migration produces (1-based).
  final int version;

  /// Applies the migration. Runs inside a transaction.
  final Future<void> Function(DatabaseExecutor db) up;
}

/// Sequential migration runner driven by `PRAGMA user_version` (spec §2.6).
///
/// Migrations run strictly in order: for a database at version N, only
/// migrations with `version > N` are applied, each in its own transaction,
/// then `user_version` is bumped. Re-opening an up-to-date database is a
/// no-op — existing data is never touched by migrations it already passed.
class DatabaseMigrationRunner {
  DatabaseMigrationRunner(this.migrations);

  /// Migrations ordered by [Migration.version]; must start at 1 and be
  /// contiguous.
  final List<Migration> migrations;

  /// Asserts the migration list is contiguous starting at version 1.
  ///
  /// Fails fast in debug/tests if a version is missing — a silently skipped
  /// migration would leave the schema inconsistent with `user_version`.
  void _validate() {
    for (var i = 0; i < migrations.length; i++) {
      assert(migrations[i].version == i + 1,
          'Migration list must be contiguous starting at 1; '
          'expected version ${i + 1} at index $i, got ${migrations[i].version}');
    }
  }

  Future<void> run(Database db) async {
    _validate();
    var current = await db.getVersion();
    for (final migration in migrations) {
      if (migration.version <= current) continue;
      await db.transaction((txn) async {
        await migration.up(txn);
      });
      await db.setVersion(migration.version);
      current = migration.version;
    }
  }
}
