# Module: Providers & State management

**Files**: `lib/core/providers.dart`, `lib/features/*/application/*.dart`
· **Milestone**: M0 (providers) / M1 (controllers)

## Trách nhiệm

Kết nối repository → UI qua Riverpod; giữ state per-feature.

## Core providers (`lib/core/providers.dart`)

```dart
databaseProvider                    // FutureProvider<Database> → AppDatabase.open()
subscriptionRepositoryProvider      // FutureProvider<SubscriptionRepository>
categoryRepositoryProvider          // FutureProvider<CategoryRepository>
settingsRepositoryProvider          // FutureProvider<SettingsRepository>
```

## Controllers (đều là `AsyncNotifierProvider`)

| Controller | State | Trách nhiệm |
| --- | --- | --- |
| `SettingsController` | `SettingsState{themeMode, primaryCurrency, onboardingCompleted}` | load/persist settings qua app_settings; `setThemeMode`, `setPrimaryCurrency` (không convert lịch sử), `completeOnboarding`, `defaultCurrencyFromLocale` (VN→VND, EN_GB→GBP, fallback USD) |
| `OnboardingController` | — | completion flag + currency (M1) |
| `SubscriptionListController` | `SubscriptionListState{subscriptions, query, sort, filter}` | CRUD + search/sort/filter qua `visible` getter |
| `DashboardController` | `DashboardState{active, upcoming, topThree}` | totals/monthly/yearly/5year theo currency, upcoming 7d, top-3 |
| `CategoryController` | `List<Category>` | custom category CRUD |

## Pattern

```dart
class XController extends AsyncNotifier<XState> {
  @override
  Future<XState> build() async { ... ref.watch(xRepositoryProvider.future) ... }
  Future<void> mutate() async { ... await repo...; state = AsyncData(...); }
}
```

## Lưu ý Riverpod 3

- Type `Override` **không public-export** — test dùng inference (không khai báo
  `List<Override>` tường minh).
- Mutate state sau await; tránh `state.value!` khi state còn loading (thêm guard
  nếu action có thể chạy sớm).
- Dashboard `primaryCurrency` fallback USD khi settings chưa load (dùng
  `ref.watch` để rebuild khi settings resolve — không stale vĩnh viễn).

## Test

`test/subscription_list_controller_test.dart`, `test/dashboard_controller_test.dart`
(dùng `TestDb` ffi + `harness.container()`).
