# Module: Settings & More

**Files**: `lib/features/settings/` · **Spec**: M1 · **Milestone**: M1

## Trách nhiệm

Settings persist qua bảng `app_settings` (M0) — **không** shared_preferences.

## `SettingsController` (application)

- `SettingsState{themeMode, primaryCurrency, onboardingCompleted}`.
- `setThemeMode(ThemeMode)` — persist + update state.
- `setPrimaryCurrency(String)` — **không convert lịch sử**; amount cũ giữ
  currency riêng, dashboard regroup (spec M1).
- `completeOnboarding({currency})`.
- `defaultCurrencyFromLocale(locale)` — vi→VND, ja→JPY, ko→KRW, en_GB→GBP,
  de/fr→EUR, fallback USD.

## `MoreTab`

- ListTile → Settings; privacy line footer.

## `SettingsScreen`

- Primary currency (PopupMenu: USD/EUR/GBP/VND/JPY/KRW, check current).
- Appearance: SegmentedButton system/light/dark → `setThemeMode`.
- Categories (push CategoriesScreen), About + privacy line.

## Test

Theme dark/light qua widget tests (`m1_widget_test.dart`). Controller logic
(currency regroup) qua `dashboard_controller_test.dart`. Widget test đổi
currency/theme trong Settings có thể bổ sung.
