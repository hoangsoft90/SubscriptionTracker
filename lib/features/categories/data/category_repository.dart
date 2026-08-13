import 'package:sqflite/sqflite.dart';

import '../domain/category.dart';

/// Typed access to category rows.
abstract class CategoryRepository {
  Future<List<Category>> getAll();
  Future<String> insert(Category category);
  Future<void> update(Category category);
  Future<void> delete(String id);

  /// Removes every row (used by backup "Replace All").
  Future<void> deleteAll();
}

/// sqflite-backed [CategoryRepository]. Deleting a default (seeded) category
/// is blocked at the repository level; deleting a custom category first
/// unassigns it from subscriptions (subscriptions become uncategorized),
/// atomically, per the categories spec ("unassign or prompt — one defined
/// behavior only").
class SqfliteCategoryRepository implements CategoryRepository {
  SqfliteCategoryRepository(this._db);

  static const _table = 'categories';
  final Database _db;

  @override
  Future<List<Category>> getAll() async {
    final rows = await _db.query(_table, orderBy: 'is_default DESC, name ASC');
    return rows.map(Category.fromMap).toList();
  }

  @override
  Future<String> insert(Category category) async {
    await _db.insert(_table, category.toMap());
    return category.id;
  }
  
  @override
  Future<void> update(Category category) async {
    await _db.update(
      _table,
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  @override
  Future<void> delete(String id) async {
    final rows = await _db.query(_table,
        columns: ['is_default'], where: 'id = ?', whereArgs: [id]);
    if (rows.isNotEmpty && (rows.first['is_default'] as int) == 1) {
      throw ArgumentError('Default categories cannot be deleted');
    }
    await _db.transaction((txn) async {
      await txn.update(
        'subscriptions',
        {'category_id': null},
        where: 'category_id = ?',
        whereArgs: [id],
      );
      await txn.delete(_table, where: 'id = ?', whereArgs: [id]);
    });
  }

  @override
  Future<void> deleteAll() async {
    await _db.delete(_table);
  }
}
