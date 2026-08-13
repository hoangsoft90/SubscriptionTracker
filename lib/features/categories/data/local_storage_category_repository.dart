import '../../../core/storage/local_storage_store.dart';
import '../domain/category.dart';
import 'category_repository.dart';

/// localStorage-backed [CategoryRepository] for the web.
///
/// Mirrors the [SqfliteCategoryRepository] semantics exactly: deleting a
/// default (seeded) category is blocked at the repository level; deleting a
/// custom category first unassigns it from subscriptions (subscriptions
/// become uncategorized). Same interface — controllers and business logic
/// are shared across platforms.
class LocalStorageCategoryRepository implements CategoryRepository {
  LocalStorageCategoryRepository(this._store);

  final LocalStorageStore _store;

  @override
  Future<List<Category>> getAll() async {
    final rows = [..._store.readRows(LocalStorageStore.categoriesKey)];
    rows.sort((a, b) {
      final aDefault = a['is_default'] as int;
      final bDefault = b['is_default'] as int;
      if (aDefault != bDefault) return bDefault.compareTo(aDefault);
      return (a['name']! as String).compareTo(b['name']! as String);
    });
    return rows.map(Category.fromMap).toList();
  }

  @override
  Future<String> insert(Category category) async {
    final rows = _store.readRows(LocalStorageStore.categoriesKey);
    // Upsert by id — keeps rows unique regardless of the caller's insert path.
    rows.removeWhere((r) => r['id'] == category.id);
    rows.add(category.toMap());
    _store.writeRows(LocalStorageStore.categoriesKey, rows);
    return category.id;
  }

  @override
  Future<void> update(Category category) async {
    final rows = _store.readRows(LocalStorageStore.categoriesKey);
    final index = rows.indexWhere((r) => r['id'] == category.id);
    if (index == -1) return;
    rows[index] = category.toMap();
    _store.writeRows(LocalStorageStore.categoriesKey, rows);
  }

  @override
  Future<void> delete(String id) async {
    final rows = _store.readRows(LocalStorageStore.categoriesKey);
    final target = rows.where((r) => r['id'] == id).toList();
    if (target.isNotEmpty && (target.first['is_default'] as int) == 1) {
      throw ArgumentError('Default categories cannot be deleted');
    }
    // Unassign the category from any subscriptions, atomically with the
    // removal (mirrors the SQLite transaction).
    final subs = _store.readRows(LocalStorageStore.subscriptionsKey);
    for (final s in subs) {
      if (s['category_id'] == id) s['category_id'] = null;
    }
    _store.writeRows(LocalStorageStore.subscriptionsKey, subs);
    rows.removeWhere((r) => r['id'] == id);
    _store.writeRows(LocalStorageStore.categoriesKey, rows);
  }

  @override
  Future<void> deleteAll() async {
    _store.writeRows(LocalStorageStore.categoriesKey, const []);
  }
}
