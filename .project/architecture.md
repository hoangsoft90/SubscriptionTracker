# Architecture

Kiến trúc tuân theo **`architecture/SKILL.md`** (mobile skill của project):
**Feature-First** + Riverpod + GoRouter. Không MVVM, không BLoC.

## Nguyên tắc phân lớp (bắt buộc)

Mỗi feature trong `lib/features/<feature>/` có tối đa 4 lớp — thứ tự phụ thuộc
một chiều: `presentation → application → data → domain` (presentation có thể
dùng trực tiếp domain).

```
lib/features/<feature>/
├── domain/        # Pure Dart, KHÔNG import Flutter/Riverpod/sqflite.
│                  #   Models (Subscription, Category, Preset), enums
│                  #   (BillingCycle, SubscriptionStatus), logic thuần
│                  #   (BillingCalculator), các hằng số.
├── data/          # Repository implementations (Sqflite*) + nguồn dữ liệu khác
│                  #   (preset_catalog). Chỉ phụ thuộc domain + sqflite.
├── application/   # Riverpod controllers (AsyncNotifier) — state management,
│                  #   orchestrate repos. Chỉ phụ thuộc data/domain.
└── presentation/  # Screens/widgets (ConsumerWidget/ConsumerStatefulWidget).
                  #   Watch providers, KHÔNG gọi repo trực tiếp.
```

**Quy tắc cứng**:
- `domain/` **tuyệt đối không** import Flutter, Riverpod, sqflite.
- Controllers không chứa logic nghiệp vụ phức tạp — đẩy xuống domain
  (vd: tổng tiền/dự báo ở `BillingCalculator` + `DashboardController`,
  scoring ở `ReviewQueueService`/`TodayBriefService`/`SavingsCalculator`).
- User-entered data (tên subscription, notes, tên category custom) **không bao
  giờ** được localize — render nguyên văn (spec §6).

## Data flow

```
UI (presentation)
   │  ref.watch(...Provider)
   ▼
Application (AsyncNotifier)  ←── build() gọi repo
   │  ref.read(...RepositoryProvider)
   ▼
Data (Sqflite*Repository | LocalStorage*Repository)  ←── toMap/fromMap
   ▼
SQLite (mobile, PRAGMA user_version v2)  |  localStorage (web)
```

- **Storage split (2026-08-10)**: `StorageBackend` interface + factory
  conditional-import — mobile = SQLite, web = browser localStorage; repository
  interface giữ nguyên (Subscription/Category/Settings), business logic không đổi.
- **Providers** (`lib/core/providers.dart`): `databaseProvider` (giữ cho test),
  `storageBackendProvider` → 3 `FutureProvider` repository; thêm wiring
  notifications (scheduler/coordinator/permission), IAP gateway, guidance.
- **Multi-currency (2026-08-15)**: `lib/core/money/exchange_rates.dart` — pure
  core (units/1-USD pivot, `convertMinorToPrimary` null khi thiếu rate — không
  bịa, `fetchLiveRates` qua open.er-api.com, `defaultManualExchangeRates`,
  `canFetchLive=false` khi test/web). Providers: `exchangeRatesProvider`
  (FutureProvider: live thắng, fallback manual) + `manualExchangeRatesProvider`
  + `saveManualExchangeRates` (persist JSON vào settings repo). Dashboard
  controller expose `monthlyTotalConverted`/`yearlyTotalConverted`; Home
  headline convert về primary + breakdown từng currency (l10n `dashboardConvertedNote`).
- **Controller pattern**: `AsyncNotifier.build()` await repo → state; mọi action
  (add/edit/delete/setStatus) gọi repo rồi `state = AsyncData(...)` hoặc `reload()`.
- `SubscriptionListController` giữ toàn bộ list trong state; `visible` getter áp
  search/sort/filter (tính lại mỗi lần, không cache stale).

## State management (Riverpod 3)

- Providers đều **family-less, plain** (không `@riverpod` codegen).
- Settings/Onboarding/Dashboard/List/Categories đều là `AsyncNotifierProvider`.
- **Chuẩn override cho test**: `provider.overrideWith((ref) => fake)` trong
  `ProviderScope(overrides: [...])` (xem `widget_harness.dart`).
- Lưu ý Riverpod 3: type `Override` không public-export — trong test dùng
  context-type inference (không khai báo kiểu tường minh `List<Override>`).

## Routing (GoRouter)

`lib/app/router/app_router.dart`:

- `routerProvider = Provider<GoRouter>` với `ValueNotifier<int> refresh` +
  `ref.listen(settingsControllerProvider)` → `refresh.value++` (pattern chuẩn
  GoRouter+Riverpod refresh).
- `redirect`: settings chưa load → `null` (đứng yên, tránh redirect storm);
  chưa onboard → `/onboarding`; đã onboard mà vào `/onboarding` → `/home`;
  deep-link trước onboarding → restore sau khi hoàn thành.
- Routes:
  - `/onboarding` (OnboardingScreen)
  - StatefulShellRoute.indexedStack, 3 branches:
    - `/home` → HomeScreen (dashboard + GuidanceHost tour)
    - `/subscriptions` → SubscriptionListScreen; children: `add`, `:id`
      (detail), `:id/edit` (edit)
    - `/more` → MoreTab; children: `settings`, `categories`, `backup`
  - `/calendar` (money calendar), `/paywall` (top-level, có nút Home khi vào thẳng)
  - `errorBuilder` recovery page cho path không tồn tại
- **Banner placement (2026-08-15)**: `_AppShell` (shell Scaffold) —
  `bottomNavigationBar` = `Column [BannerAdView, NavigationBar]` → banner nằm
  trực tiếp trên nav buttons, đều cả 3 tab (Home/Subscriptions/More), không
  SafeArea gap (NavigationBar bên dưới handle bottom inset). Banner KHÔNG còn
  nằm trong per-tab Scaffold (Home/Subscriptions); FAB nổi phía trên Column này.
- **Lưu ý test**: indexedStack giữ các branch sống (offstage) — `find.text(...)`
  có thể match nhiều branch; dùng `findsWidgets` hoặc scoped finder khi cần.
  Page transition cũng cần chờ (tap icon AppBar quá sớm sẽ trượt ra ngoài
  viewport) — `pump` thêm ~400ms sau transition.

## Database schema (v2 — `PRAGMA user_version = 2`)

- `categories(id TEXT PK, name, icon_emoji, color_hex, is_default)`
- `subscriptions(id TEXT PK, name, amount_minor INT, currency, billing_cycle,
  custom_interval_days, start_date, next_billing_date, billing_anchor_day INT,
  is_trial INT, trial_end_date, cancellation_url, status, category_id FK→categories,
  color, icon_emoji, reminder_days_before, notes, created_at, updated_at,
  + v2: last_reviewed_at, review_interval_days DEFAULT 90, pending_cancellation,
  cancelled_at, previous_amount_minor, superseded_at)`
  - Indexes: `next_billing_date`, `status`, `category_id`
- `subscription_price_history(id PK, subscription_id FK→subscriptions ON DELETE
  CASCADE, amount_minor, currency, effective_from, created_at)` + index (v2)
- `app_settings(key TEXT PK, value)` — gồm guidance/notification state, onboarding…
- FK ON (`PRAGMA foreign_keys = ON`), migration runner contiguous assert,
  seeder idempotent (11 categories + `primaryCurrency=USD`).
- Lưu ý: `reminder_days_before` chỉ tồn tại trong schema v1 (plan SQL gốc thiếu
  cột này nhưng Dart model có — đã ghi chú lệch; cột hiện không được UI dùng).

## Theme & l10n

- `AppTheme` Material 3, seed `#00696D` (calm financial awareness), light + dark,
  themeMode từ settings (system/light/dark).
- L10n qua ARB: `lib/core/l10n/app_en.arb` + `app_vi.arb`, `flutter gen-l10n` →
  `lib/l10n/app_localizations*.dart`. UI dùng `context.l10n` (extension).
  User data (tên sub/category/notes) render nguyên văn — không localize.
  Language switch runtime từ settings (localeCode) — `AppStrings` đã bị xóa (M2).
