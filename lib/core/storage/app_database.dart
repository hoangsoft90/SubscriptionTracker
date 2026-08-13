import 'package:sqflite/sqflite.dart';

import 'migrations.dart';
import 'seeder.dart';

/// Opens the app database and applies pending migrations.
class AppDatabase {
  AppDatabase._();

  /// Default database file name.
  static const String defaultFileName = 'subtrack.db';

  /// All migrations, in order. v1 = full locked schema (spec §6); v2 = M2.5
  /// decision-engine columns + price history (plan2_final §7).
  static final List<Migration> migrations = [
    Migration(1, _migrationV1),
    Migration(2, _migrationV2),
  ];

  static Future<void> _migrationV1(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE categories (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          icon_emoji TEXT,
          color_hex TEXT,
          is_default INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE subscriptions (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          amount_minor INTEGER NOT NULL,
          currency TEXT NOT NULL,
          billing_cycle TEXT NOT NULL,
          custom_interval_days INTEGER,
          start_date TEXT NOT NULL,
          next_billing_date TEXT NOT NULL,
          billing_anchor_day INTEGER NOT NULL,
          is_trial INTEGER NOT NULL DEFAULT 0,
          trial_end_date TEXT,
          cancellation_url TEXT,
          status TEXT NOT NULL,
          category_id TEXT,
          color INTEGER,
          icon_emoji TEXT,
          reminder_days_before TEXT,
          notes TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY(category_id) REFERENCES categories(id)
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_sub_next_billing ON subscriptions(next_billing_date)',
    );
    await db.execute('CREATE INDEX idx_sub_status ON subscriptions(status)');
    await db.execute(
      'CREATE INDEX idx_sub_category ON subscriptions(category_id)',
    );

    await db.execute('''
      CREATE TABLE app_settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
      )
    ''');
  }

  /// M2.5 decision-engine migration (plan2_final §7): additive columns on
  /// `subscriptions` + the `subscription_price_history` table. Non-destructive;
  /// existing rows keep their data (new columns are nullable/defaulted).
  static Future<void> _migrationV2(DatabaseExecutor db) async {
    await db.execute(
      'ALTER TABLE subscriptions ADD COLUMN last_reviewed_at TEXT',
    );
    await db.execute(
      'ALTER TABLE subscriptions ADD COLUMN review_interval_days INTEGER NOT NULL DEFAULT 90',
    );
    await db.execute(
      'ALTER TABLE subscriptions ADD COLUMN pending_cancellation INTEGER NOT NULL DEFAULT 0',
    );
    await db.execute(
      'ALTER TABLE subscriptions ADD COLUMN cancelled_at TEXT',
    );
    await db.execute(
      'ALTER TABLE subscriptions ADD COLUMN previous_amount_minor INTEGER',
    );
    await db.execute(
      'ALTER TABLE subscriptions ADD COLUMN superseded_at TEXT',
    );

    await db.execute('''
      CREATE TABLE subscription_price_history (
          id TEXT PRIMARY KEY,
          subscription_id TEXT NOT NULL,
          amount_minor INTEGER NOT NULL,
          currency TEXT NOT NULL,
          effective_from TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY(subscription_id) REFERENCES subscriptions(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_price_history_sub ON subscription_price_history(subscription_id)',
    );
  }

  /// Opens the database at [path] (defaults to the app database), enables
  /// foreign keys, runs pending migrations, and seeds defaults (idempotently)
  /// — categories + primaryCurrency on first launch (spec §6).
  static Future<Database> open({String? path}) async {
    final db = await openDatabase(path ?? defaultFileName);
    await db.execute('PRAGMA foreign_keys = ON');
    await DatabaseMigrationRunner(migrations).run(db);
    await Seeder(db).seed();
    return db;
  }
}
