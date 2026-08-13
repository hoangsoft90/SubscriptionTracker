# Module: Test infrastructure

**Files**: `test/` · **Milestone**: M0/M1

## Tổ chức

| File | Loại | Mục đích |
| --- | --- | --- |
| `fakes.dart` | Fake repos | `FakeSubscriptionRepository`, `FakeCategoryRepository`, `FakeSettingsRepository` (in-memory, implements interface) — cho widget tests |
| `widget_harness.dart` | Harness | `WidgetHarness` — `scope(child)` (ProviderScope overrides) + `container()` |
| `m1_support.dart` | TestDb | `TestDb.create()` — sqflite_common_ffi in-memory; `container()` — cho controller tests |
| `m1_widget_test.dart` | Widget tests | onboarding gate, theme, empty state, FAB a11y + helpers `pumpUntilFound`/`pumpUntilTheme` |
| `m1_crud_widget_test.dart` | Widget tests | CRUD flows + categories |
| `*_controller_test.dart` | Unit tests | controllers với DB ffi thật |
| `money/billing/data_storage_test.dart` | Unit tests | core M0 |

## Quy tắc quan trọng

1. **Không sqflite trong `testWidgets`** — ffi cần isolate thật, không resolve
   trong FakeAsync zone của `testWidgets`. → dùng fakes + harness.
2. **Không `pumpAndSettle`** với async provider loading spinner (treo vô hạn)
   → `pumpUntilFound(tester, finder)` loop pump có timeout.
3. **Form dài** (add/edit): Save dưới fold → `tester.view.physicalSize =
   Size(800, 1600)` + `devicePixelRatio = 1.0`.
4. **Page transition**: sau route mới xuất hiện, `pump(400ms)` trước khi tap
   AppBar widget (icon trượt từ ngoài viewport — đã từng gây miss tap).
5. **Riverpod 3**: type `Override` không public → không khai báo tường minh,
   để context-type inference.
6. Assert tiền: không có ký hiệu `$` trong format — assert `'14.99'`.

## Test status

73/73 pass, analyze sạch (2026-08-08).
