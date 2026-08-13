# Module: Categories

**Files**: `lib/features/categories/` · **Spec**: M1 categories capability · **Milestone**: M0 (domain/data) + M1 (UI)

## Trách nhiệm

Phân loại subscription: 11 defaults (seeded, non-deletable) + custom CRUD
(emoji + color).

## Domain (`Category`)

`id, name, iconEmoji?, colorHex?, isDefault` + `toMap/fromMap` + `copyWith`.

## Data (`SqfliteCategoryRepository`)

- `getAll`, `insert`, `update`, `delete`.
- **Delete**: unassign subscriptions trước khi xóa (transaction) — spec M1
  "unassign or prompt — one defined behavior".

## Application (`CategoryController`)

AsyncNotifier<List<Category>> — add/update/delete + reload từ repo.

## Presentation (`CategoriesScreen`)

- List: avatar (color + emoji), name; default → subtitle "Default", **không có
  delete/edit actions**.
- Custom → edit/delete icon buttons.
- `_CategoryDialog` (add/edit): name + emoji ChoiceChips + color swatches.
- Delete default → SnackBar "Default categories cannot be deleted" (blocked).

## Test

`test/m1_crud_widget_test.dart`: default category không có delete action;
custom category delete → removed.
