# Module: App shell & Routing

**Files**: `lib/main.dart`, `lib/app/app.dart`, `lib/app/router/app_router.dart`,
`lib/app/theme/app_theme.dart` · **Milestone**: M1

## Trách nhiệm

Root widget + navigation + theming.

## Entry

- `main.dart`: `runApp(ProviderScope(child: SubTrackApp()))`.
- `SubTrackApp` (ConsumerWidget): `MaterialApp.router` — theme/darkTheme từ
  `AppTheme`, `themeMode` từ `settingsControllerProvider.value?.themeMode`
  (fallback system), router từ `routerProvider`.

## Router

- `routerProvider = Provider<GoRouter>`:
  - `refresh = ValueNotifier<int>(0)`; `ref.listen(settingsControllerProvider)`
    → `refresh.value++` (pattern chuẩn GoRouter+Riverpod refresh).
  - `redirect`: settings null → `null` (đứng yên); chưa onboard → `/onboarding`;
    onboard xong mà ở `/onboarding` → `/home`.
- Routes: `/onboarding`; `StatefulShellRoute.indexedStack` 3 branches
  (`/home`, `/subscriptions` + children `add`/`:id`/`:id/edit`, `/more/settings`).
- `AppRoutes` (camelCase route names).

## Theme

- `AppTheme.light()/dark()` — Material 3, seed `#00696D`; appBar transparent,
  card radius 12, input radius 12, floating snackbar.
- ThemeMode persisted trong settings (system/light/dark).

## Lưu ý test

- indexedStack giữ mọi branch alive (offstage) — `find.text` có thể match nhiều
  nơi (vd dashboard monthly total + list tile).
- Page transition: pump ~400ms sau khi route xuất hiện trước khi tap AppBar widget.

## Test

`test/m1_widget_test.dart` (onboarding gate, dark/light theme, empty, FAB a11y),
`test/widget_test.dart` (smoke), `test/m1_crud_widget_test.dart` (navigation flows).
