import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/category.dart';

class CategoryController extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    final repo = await ref.watch(categoryRepositoryProvider.future);
    return repo.getAll();
  }

  Future<void> add(Category category) async {
    final repo = await ref.read(categoryRepositoryProvider.future);
    await repo.insert(category);
    state = AsyncData(await repo.getAll());
  }

  Future<void> updateCategory(Category category) async {
    final repo = await ref.read(categoryRepositoryProvider.future);
    await repo.update(category);
    state = AsyncData(await repo.getAll());
  }

  Future<void> delete(String id) async {
    final repo = await ref.read(categoryRepositoryProvider.future);
    await repo.delete(id);
    state = AsyncData(await repo.getAll());
  }
}

final categoryControllerProvider =
    AsyncNotifierProvider<CategoryController, List<Category>>(
  CategoryController.new,
);
