import 'package:sqflite/sqflite.dart';

import '../../features/categories/domain/category.dart';
import 'seed_data.dart';

/// Idempotently seeds default categories and default settings on first launch
/// (spec §6 — 11 default categories; `primaryCurrency` default).
///
/// The seed data itself lives in [seed_data.dart] so the web localStorage
/// backend seeds identical defaults ([LocalStorageSeeder]).
class Seeder {
  Seeder(this._db);

  final Database _db;

  /// The 11 default categories (shared with the web seeder).
  static const List<Category> defaultCategories = seedDefaultCategories;

  /// Seeds missing default categories and default settings. Safe to call on
  /// every launch — existing rows are left untouched.
  Future<void> seed() async {
    final batch = _db.batch();

    for (final category in defaultCategories) {
      batch.insert(
        'categories',
        category.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    batch.insert(
      'app_settings',
      {'key': 'primaryCurrency', 'value': seedDefaultPrimaryCurrency},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    await batch.commit(noResult: true);
  }
}
