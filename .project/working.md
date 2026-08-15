# Working Log — SubTrack

Format: `- [YYYY-MM-DD] status: mô tả` (ISO dates).

## OpenSpec retrospective + docs refresh .project/ (2026-08-15)

- [2026-08-15] User yêu cầu: (1) cập nhật openspec cho toàn bộ work đã ship từ sau change cuối `subtrack-guidance` (2026-08-12); (2) tuân thủ `.project/ai-rules.md` cập nhật `.project/` (state.md/working.md/architecture.md) theo trạng thái mới.
- [2026-08-15] Xong OpenSpec: tạo change retrospective **`subtrack-monetization-release`** — `proposal.md` (Why/What/Impact) + 4 specs đúng format delta (`## ADDED Requirements` + `### Requirement:` + `#### Scenario:`): `ads-monetization` (test ads default, interstitial frequency+cooldown, banner layout SizedBox AdSize, banner trong bottomNavigationBar FAB-safe), `multi-currency-report` (USD-pivot conversion, live API + manual fallback, converted Home headline + breakdown, currency codes), `release-infra` (package rename `com.hoangsoft.subtrack`, targetSdk 36, split GH workflows, keystore secrets, privacy policy gh-pages), `display-reliability` (null-safe reload, dashboard invalidation, pull-to-refresh 2 tab, notification permission Settings) + `tasks.md` retrospective all [x]. Verify: `openspec validate --changes` **6/6 pass**. Commit + push **`f4329eb`** lên `main` (docs-only, debug APK workflow tự trigger).
- [2026-08-15] Xong docs refresh theo `ai-rules.md`: `state.md` (milestone `subtrack-monetization-release` + test 247/247 + todo mở + session notes 08-15), `architecture.md` (thêm mục Multi-currency — `exchange_rates.dart` + providers + dashboard/Home wiring), `working.md` (mục này). Lưu ý: working.md giữ đầy đủ các phiên 08-13 → 08-15 (ghi trong commit trước); mục OpenSpec trước đó thiếu, giờ đã bổ sung.

## Split GH workflows + đổi package com.subguard.app → com.hoangsoft.subtrack (2026-08-15)

- [2026-08-15] User yêu cầu: (1) tách GH workflow thành 2 cái — debug APK (no keystore) riêng, release AAB (with keystore) riêng; (2) package `com.subguard.app` đã tồn tại → đổi sang package khác (user chọn `com.hoangsoft.subtrack` qua ask_user).
- [2026-08-15] Xong split workflow (xóa `build-apk.yml` cũ — build cả debug+release+APK+AAB):
  - `.github/workflows/build-debug-apk.yml` — chỉ `flutter build apk --debug`, upload `subtrack-debug-apk`; trigger push main + workflow_dispatch; KHÔNG cần keystore.
  - `.github/workflows/build-release-aab.yml` — chỉ `flutter build appbundle --release` ký thật; trigger workflow_dispatch (manual); keystore từ GitHub Secrets: decode `ANDROID_KEYSTORE_BASE64` → `android/keystore/subtrack-release.jks` + ghi `android/key.properties` từ secrets (`ANDROID_STORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`). Có error rõ nếu secret chưa set.
  - Đã set 4 GitHub Secrets qua `gh secret set` (repo `hoangsoft90/SubscriptionTracker`): `ANDROID_KEYSTORE_BASE64` (base64 của `android/keystore/subtrack-release.jks`), `ANDROID_STORE_PASSWORD`=83793900, `ANDROID_KEY_ALIAS`=upload, `ANDROID_KEY_PASSWORD`=83793900. Verified bằng `gh secret list` (4 secrets xuất hiện).
- [2026-08-15] Xong đổi package `com.subguard.app` → `com.hoangsoft.subtrack` (user chọn, do package cũ đã tồn tại):
  - Android: `namespace` + `applicationId` trong `android/app/build.gradle.kts`; move `MainActivity.kt` `com/subguard/app/` → `com/hoangsoft/subtrack/` (+ `package` line); comment AdMob app ID trong `AndroidManifest.xml`.
  - iOS: `PRODUCT_BUNDLE_IDENTIFIER` 6 chỗ trong `project.pbxproj` (`com.hoangsoft.subtrack` + `.RunnerTests`).
  - `google-services.json` package_name → `com.hoangsoft.subtrack` (lưu ý: google-services plugin KHÔNG được apply — file chỉ là tham chiếu AdMob; nếu sau này bật Firebase/real ads cần tạo AdMob app mới cho package mới và cập nhật ID trong `ads_config.dart` — đã ghi chú trong comment).
  - `integration_test/device_ux_test.dart` comment `adb pm clear`; `ads_config.dart` comments ghi rõ ID thật đang đăng ký cho package cũ, cần re-register trước khi bật ads thật; `.project/ai-rules.md`/`overview.md`/`state.md` cập nhật.
- [2026-08-15] Verify: `flutter analyze` 0 issues; `flutter test` **247/247 pass**; grep kiểm tra không còn ref `com.subguard.app`/`com/subguard` trong code (chỉ còn comment lịch sử trong working.md + ads_config note). **KHÔNG build APK local** (user yêu cầu tuyệt đối không build local — build qua GH Actions). Commit + push lên `main` → debug APK workflow tự trigger verify package mới; release AAB chạy manual khi cần submit Play Store.

## Multi-currency Home report + test_ads default + FAB/banner overlap (2026-08-15)

- [2026-08-15] User yêu cầu 3 việc: (1) set `test_ads=true` mặc định để hiển thị test ads tránh AdMob limit tài khoản thật; (2) nút "+" bị banner ads đè lên; (3) list subscriptions chưa hiển thị currency + hỏi Home có chuyển đổi multi-currency về base currency không.
- [2026-08-15] Xong #1: `ads_config.dart` — `testAds = bool.fromEnvironment('TEST_ADS', defaultValue: true)` (test ads ON mặc định; production flip bằng `--dart-define=TEST_ADS=false`). Cập nhật `ads_test.dart` (test-ads mode giờ assert default true + sample IDs).
- [2026-08-15] Xong #2: **Root cause** — banner nằm trong body Column của màn hình, FAB default `endFloat` trôi lên trên banner. Fix: chuyển `BannerAdView` từ body Column sang **`Scaffold.bottomNavigationBar`** (Home + Subscriptions) → FAB tự động nổi PHÍA TRÊN banner (không còn đè), đồng thời loại bỏ nguy cơ banner làm collapse list (đã có `banner_layout_test.dart`). ListView bottom padding 88→16 (banner không còn nằm trong body).
- [2026-08-15] Xong #3a: list tile thêm `currencyCode: true` vào `MoneyText` (hiển thị "14.99 USD"/"99,999 VND" thay vì số trần), maxWidth 110→140. Widget test mới trong `subscription_display_test.dart`.
- [2026-08-15] Xong #3b (user chọn "Cả hai" + "Live API + fallback thủ công" qua ask_user):
  - `lib/core/money/exchange_rates.dart` — pure core: rates = units/1-USD pivot; `convertMinorToPrimary` (minor→USD→target, null khi thiếu rate — không bịa), `sumConvertedTo`, `fetchLiveRates` (open.er-api.com/v6/latest/USD, free không key, timeout 6s), `defaultManualExchangeRates` (VND 25400/EUR 0.92/GBP 0.79/JPY 156/KRW 1380), `canFetchLive=false` khi test/web.
  - `providers.dart` — `exchangeRatesProvider` (FutureProvider: live thắng, fallback manual) + `manualExchangeRatesProvider` + `saveManualExchangeRates` (persist JSON vào settings repo).
  - Dashboard controller — `monthlyTotalConverted`/`yearlyTotalConverted`/`allActiveConvertible`/`savingsConverted`.
  - Home `_CostCard` — headline convert về primary + Wrap breakdown từng currency (currencyCode) + note "≈ converted" (l10n `dashboardConvertedNote` EN+VI). An toàn tiền: chỉ convert khi MỌI active sub có rate (không truncate âm thầm), fallback primary-only.
  - Settings — section "Exchange rates (fallback)" (`_ExchangeRatesSection`): nhập thủ công 1 USD = X cho EUR/GBP/VND/JPY/KRW, lưu qua `saveManualExchangeRates`, invalidate cả 2 provider. L10n keys mới EN+VI.
  - Dependency mới: `http ^1.5.0` (chỉ dùng fetch live rates).
- [2026-08-15] Tests: `test/exchange_rates_test.dart` (conversion USD→VND/VND→USD/VND→EUR qua pivot, missing rate→null, sumConvertedTo, defaults, canFetchLive=false) + `dashboard_controller_test.dart` +3 multi-currency + `subscription_display_test.dart` +1 currency display. Fix test phụ thuộc layout: `ux_bugfix_widget_test.dart` (Settings giờ có section tỷ giá đẩy "Appearance" xuống → scrollUntilVisible). Verify: `flutter analyze` 0 issues; `flutter test` **247/247 pass**.
- [2026-08-15] Commit + push **`593244d`** lên `main` (19 files, +844/−28) — GH Actions run `31857687594` build APK + AAB (in_progress). Không secret trong diff (đã grep ghp_/api key/password trước commit).

## AdMob banner collapse list — root cause device (2026-08-14)

- [2026-08-14] Test trên phone thật (debug APK từ run `31784152560`/42e12cd, Pixel 3a): add "Netflix Test" 99,999 VND qua UI thật → **cả 2 tab Subscriptions + Home update NGAY** (bug invalidate dashboard đã hết, `30a8334` hoạt động đúng trên máy thật). Restart → dữ liệu persist, không crash.
- [2026-08-14] **Tái hiện được bug thật còn lại trên máy**: sau pull-down (hoặc sau khi tab Subscriptions hiển thị một lúc), **list tab Subscriptions trống** dù DB vẫn còn 2 rows (verify qua sqlite thật: Spotify USD + Netflix VND, cả 2 ACTIVE). Home tab vẫn hiển thị đủ 2 items → data KHÔNG mất, chỉ UI list bị trống. Tap tab Subscriptions còn bị "nuốt" (có lúc không chuyển tab — dấu hiệu layout tràn che vùng tap).
- [2026-08-14] **Root cause (xác minh bằng VM service thật trên máy, không đoán)**: dump widget tree + render tree qua `ext.flutter.debugDumpApp`/`debugDumpRenderTree`:
  - Widget tree: 2 `_SubscriptionTile` VẪN ĐƯỢC BUILD (data provider bình thường) — chứng minh không phải bug dữ liệu.
  - Render tree: Column tab Subscriptions `RenderFlex#800cc` **OVERFLOWING**; ListView của list có `constraints: BoxConstraints(0.0<=w<=392.7, h=0.0)`, `size: Size(392.7, 0.0)`, `viewport: 0.0`, sliver geometry **hidden** → list bị ép 0 chiều cao.
  - Thủ phạm: **AdMob banner đã load** — `BannerAdView` trả `AdWidget` (platform view) KHÔNG bọc SizedBox, platform-view placeholder nhận `additionalConstraints: BoxConstraints(biggest)` → tự nở `Size(392.7, Infinity)` bên trong Column (chiều cao không giới hạn) → Column tràn → Expanded list nhận h=0. Đúng y hệt symptom "lúc hiển thị lúc không": list chỉ biến mất khi ad LOAD xong (thường vài giây sau mở app), và sau pull-down/rebuild khiến banner re-render.
  - Home tab không bị vì banner Home lúc đó chưa load (SizedBox.shrink) — cùng widget nên cũng có thể dính sau.
- [2026-08-14] Xong fix `banner_ad_view.dart`: bọc `AdWidget` trong `SizedBox(width: size.width.toDouble(), height: size.height.toDouble())` với `_size` (AdSize đã dùng để load banner) — pattern chuẩn google_mobile_ads; giữ `SafeArea`/Container surface. Regression test mới `test/banner_layout_test.dart` (2 tests, dùng RenderProxyBox tự nở theo `constraints.biggest` mô phỏng platform-view placeholder): (1) ad slot không constrain → Column tràn + Expanded list h=0 (repro); (2) bọc SizedBox(w,h) → list giữ chiều cao + 2 tiles hiển thị (fix).
- [2026-08-14] Verify: `flutter analyze` 0 issues; `flutter test` **232/232 pass** (230 cũ + 2 banner layout). Commit + push **`eaa9a5c`** lên `main` — GH Actions run `31810714502` đang build APK/AAB mới (chứa fix banner). Khi xong, cài lại debug APK lên phone và verify lại flow add + pull-down + chờ ad load.

## Subscriptions tab không update — investigation + hardening (2026-08-14)

- [2026-08-14] User báo tiếp: "vẫn chưa được — lúc hiển thị lúc không; khi thêm subscription thì 2 tab (home, subscriptions) không update động mà restart app mới thấy". Điều tra systematic:
  - **Ground truth GH Actions**: build `9cdb776` (chứa fix invalidate dashboard + RefreshIndicator) đã **completed/success 2026-08-14T05:30Z**; workflow build từ `main` trên push (không lỗi artifact). User gần như chắc chắn vẫn đang cài APK cũ (hết thời gian tải bản mới khi report).
  - **Verify code hiện tại trên mọi tầng**: (1) widget repro `subscription_display_test.dart` 4 scenarios PASS; (2) **mới: integration test chạy REAL sqflite** `test/real_db_add_flow_test.dart` — `AppDatabase.open()` (migrations v1+v2 + seeder) → `SqliteStorageBackend` → controller thật: add → list provider + dashboard provider cập nhật NGAY, thêm lần 2 vẫn đúng, simulate restart (đóng DB + container mới, mở lại cùng file) → dữ liệu persist. PASS. (3) web localStorage layer `web_storage_flow_test.dart` PASS.
  - **Root cause của symptom gốc** (đã fix `30a8334`): Home không invalidate dashboard sau add. **Cơ chế stale còn lại duy nhất** tìm thấy: `SubscriptionListController.reload()` dùng `state.value!` — nếu mutation race lần build đầu tiên (state chưa có value) → **crash null-check → list giữ state cũ tới khi restart** (đúng y hệt "restart app mới thấy").
- [2026-08-14] Xong: **Harden `reload()` null-safe** — nếu `state.value == null` (initial build còn loading) thì rebuild full `SubscriptionListState` từ rows mới thay vì crash; giữ nguyên `ref.invalidate(dashboardControllerProvider)` sau mọi mutation.
- [2026-08-14] Test: thêm regression `reload is null-safe when a mutation races the initial build` (repo gated `Completer`, mutation chạy khi state chưa có value → không throw + list hiển thị ngay + sau khi build xong vẫn đúng) + integration test `real_db_add_flow_test.dart`. Verify: `flutter analyze` 0 issues; `flutter test` **230/230 pass**.
- [2026-08-14] Commit + push **`2298083`** lên `main` (theo yêu cầu user: push thẳng main, không tạo branch khác) — GH Actions tự trigger build APK + AAB cho `2298083` (run `31776276001`, in_progress lúc ghi). Từ giờ APK luôn build từ `main`.

## Subscription display bug report — investigation (2026-08-13)

- [2026-08-13] User báo: sau khi thêm subscription, tab subscriptions không hiển thị (phải mở lại app), pull down thì mất dữ liệu. **Điều tra systematic (không fix vội):**
  - Chạy repro widget test (`test/subscription_display_test.dart`, 4 scenarios: add→hiển thị ngay, restart cùng storage, pull-refresh Home, pull-down list subscriptions) trên **current main `30a8334` → PASS hết**. Chạy cùng test trên **2 build cũ** (worktree `a746af6` = build APK đầu tiên, `09a6edc` = build gần nhất trước 30a8334) → cả 2 **FAIL đúng 1 chỗ**: Home tab vẫn empty sau add (dashboard KHÔNG được invalidate — chính là bug đã fix ở `30a8334`). Test "add → subscriptions list hiển thị" PASS trên mọi version.
  - Kết luận: **bug user gặp nằm ở build cũ** (Home tab stale — đã fix trong `30a8334`, build GH Actions mới nhất hoàn thành 2026-08-13T08:29Z). Code hiện tại không tái hiện lỗi trên mọi đường storage.
  - Verify thêm web storage layer: `test/web_storage_flow_test.dart` (2 tests, LocalStorage*Repository thật + controller thật: add → restart container mới → refresh provider, dữ liệu không mất) → PASS. `flutter build web` sạch (chỉ note wasm informational).
- [2026-08-13] Xong: Thêm **pull-to-refresh cho subscriptions list** (`RefreshIndicator` quanh `ListView.builder`, `AlwaysScrollableScrollPhysics`, onRefresh = `reload()`) — trước đây tab subscriptions KHÔNG có refresh gesture nào (chỉ Home có), nên user pull-down không làm gì và dữ liệu tưởng như "mất". Giờ pull-down re-read storage → list luôn phản ánh dữ liệu đã persist.
- [2026-08-13] Test: `test/subscription_display_test.dart` (4 tests, regression giữ lại) + `test/web_storage_flow_test.dart` (2 tests). Verify: `flutter analyze` 0 issues; `flutter test` **228/228 pass** (222 cũ + 6 mới).
- [2026-08-13] **Test web trước khi build APK**: chạy `flutter run -d chrome` (dev, hot reload) hoặc `flutter build web` + serve (production): `cd build/web && python3 -m http.server 8080` → mở http://localhost:8080. Lưu ý: web dùng **localStorage** (không phải SQLite như Android) — dữ liệu web và APK tách biệt; behavior khác biệt duy nhất là web không có notifications/timezone (no-op), còn logic list/dashboard/add/refresh giống hệt.
- [2026-08-14] Xong: Commit + push **`9cdb776`** (RefreshIndicator subscriptions list + 4 regression/2 web-storage tests + fix test date-dependent `dashboard_controller_test`): verify lần nữa trước commit — `flutter analyze` 0 issues, `flutter test` **228/228 pass**; không secret trong diff (`.env` gitignored). GH Actions đã tự trigger build APK + AAB cho `9cdb776` (run `31773206294`, queued). Set remote `origin` = `https://github.com/hoangsoft90/SubscriptionTracker.git`.

## Home tab stale fix + Notification permission UI (2026-08-13)

- [2026-08-13] Xong bug: **Home tab trống sau khi thêm subscription đầu tiên** — `SubscriptionListController` chỉ reload state của chính nó, KHÔNG invalidate `dashboardControllerProvider` → Home tab giữ state cũ (trống). Fix: `reload()` giờ gọi `ref.invalidate(dashboardControllerProvider)` sau mọi mutation (add/edit/delete/setStatus/markReviewed) → Home cập nhật ngay. Regression test trong `dashboard_controller_test.dart` (dashboard rỗng → add → active chứa sub mới + monthlyTotal đúng).
- [2026-08-13] Xong: **Notification permission UI trong Settings** (trước đây không có nút bật thông báo):
  - `NotificationPlatform` thêm `permissionStatus()` (Android `areNotificationsEnabled` / iOS `checkPermissions` — v22.3.0 không có `getNotificationSettings` nên dùng `NotificationsEnabledOptions.isEnabled`) + `openNotificationSettings()` qua package `app_settings ^8.0.3` (mở OS app-notification settings).
  - `NotificationPermissionService` thêm `status()` (không prompt) + `enableFromSettings()` (lần đầu → prompt OS; đã hỏi rồi → mở OS settings vì Android ngừng prompt sau denial).
  - Settings screen giờ hiển thị section Notifications: title + hint (reminders cục bộ) + trạng thái Bật/Tắt (live từ OS) + nút "Bật thông báo" (FilledButton.tonal) khi đang tắt; refresh status sau mỗi lần enable; busy spinner khi xử lý.
  - L10n keys mới `settingsNotifications*` EN + VI, regenerate qua `flutter gen-l10n`.
- [2026-08-13] Test: `notifications_test.dart` +2 (status không prompt, enableFromSettings prompt lần đầu → mở settings lần sau), `dashboard_controller_test.dart` +1 regression Home stale, `settings_notifications_test.dart` mới 3 widget tests (status hiển thị, disabled → enable mở settings, never-asked → prompt). Verify: `flutter analyze` 0 issues; `flutter test` **222/222 pass**.
- [2026-08-13] Trả lời câu hỏi user: (1) notification khi đến hạn — **có**, scheduler cục bộ tự động (billing: ngày đến hạn 09:00 + trial: 2 ngày trước + đúng ngày, tái lập mỗi lần mở app/timezone đổi); âm thanh — **có** qua `Importance.defaultImportance`/`DarwinNotificationDetails` (sound mặc định OS, không tùy chỉnh âm riêng — channel dùng sound mặc định). (2) nút permission — đã thêm trong Settings (xem trên).

## Privacy policy + GitHub Pages (2026-08-13)

- [2026-08-13] Xong: Tạo privacy policy song ngữ EN/VI cho SubTrack — `docs/privacy-policy.md` (source, khớp nội dung khóa trong `docs/privacy-labels.md`): local-first (dữ liệu lưu trên thiết bị), không backend/tài khoản/analytics SDK, AdMob non-personalized (free tier, Pro gỡ), IAP qua store, notifications cục bộ, permissions, xóa dữ liệu, contact.
- [2026-08-13] Xong: Host lên **GitHub Pages** — branch `gh-pages` (orphan, chỉ chứa `index.html` self-contained responsive song ngữ, dark-mode aware) từ `docs/privacy-policy.html`. GitHub auto-enable Pages khi push branch. Live tại **https://hoangsoft90.github.io/SubscriptionTracker/** (HTTP 200 verified).
- [2026-08-13] Xong: Commit `docs/privacy-policy.md` + `docs/privacy-policy.html` vào main (`38f3bb6`). URL này dùng cho App Store/Play Store privacy policy field khi submit.

## Nav rà soát toàn diện + safe back + web warning (2026-08-13)

- [2026-08-13] Xong: Rà soát toàn bộ nav flow (router + 36 điểm push/go/pop trong lib). Phát hiện + fix **điểm chết**: mở web ở root URL `/` (bare domain) → không có route `/` → errorBuilder hiện "Page not found" thay vì Home. Fix: `app_router.dart` redirect `path == '/' → '/home'` (onboarding gate vẫn áp dụng).
- [2026-08-13] Verify nav toàn diện (thêm 5 test vào `navigation_deep_link_test.dart` → 10 total): root path lands Home; deep link `/more/settings`, `/more/backup`, `/subscriptions/add`, `/subscriptions/:id/edit` đều có BackButton (nested shell route, không dead-end); `/calendar`, `/paywall` deep link có Home nút (đã có từ 2026-08-10); unknown path → recovery screen; deep link trước onboarding → restore.
- [2026-08-13] Web: `flutter build web` sạch, không warning (chỉ note wasm informational); bootstrap `semanticsEnabled` đã đúng từ trước. Lưu ý: môi trường này không có headless Chrome → không verify console runtime; trước đó (2026-08-10) đã CDP-verify web không exception.
- [2026-08-13] Safe back toàn app: paywall/calendar/not-found có PopScope (back khi không back stack → `/home`); nested shell routes có back stack tự nhiên.
- [2026-08-13] Verify: `flutter analyze` 0 issues; `flutter test` **216/216 pass** (+5 nav).

## Ads test mode + cooldown + full code review (2026-08-13)

- [2026-08-13] Xong: AdMob — thêm flag `testAds` (`bool.fromEnvironment('TEST_ADS')`) trong `ads_config.dart`: khi bật dùng Google sample ad unit IDs (banner/interstitial/rewarded/app) → tránh "No fill"/giới hạn trước khi ad unit thật có traffic. Bật bằng `flutter build apk --dart-define=TEST_ADS=true`. Production mặc định dùng ID thật.
- [2026-08-13] Xong: AdMob — thêm **cooldown interstitial** `AdConfig.interstitialCooldown` (5 phút) + pure function `shouldShowInterstitial` (frequency + cooldown, unit-testable, không cần platform channel) trong `ads_controller.dart`; controller ghi `_lastShownAt` khi show. Test mới `test/ads_test.dart` (8 tests: milestone, cooldown elapsed/boundary, non-milestone, degenerate).
- [2026-08-13] Review toàn bộ code (~40 file lib/) + fix 2 lỗi crash:
  - **HIGH**: `backup_screen.dart` `_showImportFlow` — `importService.apply()` không bọc try/catch; backup JSON hợp lệ format nhưng row thiếu field/enum lạ (hand-edited/truncated) → `Subscription.fromMap` (`map['id']!`) / `BillingCycle.fromDb` (`firstWhere` throw) → **crash app**. Giờ bọc try/catch → snackbar lỗi, dữ liệu hiện tại không đổi.
  - **MEDIUM**: `local_storage_store.readPriceHistory` — `e.value as List` cast cứng (hàm khác đều có `is!` guard) → crash nếu localStorage corrupt. Thêm guard.
- [2026-08-13] Review findings (giữ nguyên, không fix): `_QueueTile._reasonLabel` trial days có thể âm (display-only); `_MonthCard`/`_NextRenewalRow` dùng `DateFormat('MMMM')`/`'EEE, MMM d'` không locale-aware (tháng tiếng Anh cho user VN — cosmetic); banner double-dispose race hiếm khi mua Pro đúng lúc ad đang load.
- [2026-08-13] Verify: `flutter analyze` 0 issues; `flutter test` **211/211 pass** (203 cũ + 8 ads mới). Workflow GH Actions `build-apk.yml` đã chạy APK **và AAB** success (run `31662555768`): artifact `subtrack-release-apk` 32MB + `subtrack-release-aab` 66.8MB.

## GitHub Actions build APK (2026-08-13)

- [2026-08-13] Xong: Push toàn bộ code SubTrack lên `github.com/hoangsoft90/SubscriptionTracker` (public, default branch `main`) — commit đầu tiên `a746af6` (289 files). Tạo workflow `.github/workflows/build-apk.yml` build **release APK bằng Gradle trực tiếp** (Flutter 3.44.9 stable + JDK 21 temurin qua `actions/setup-java`, `flutter build apk --release`, upload artifact `subtrack-release-apk`, retention 30 ngày) — **không dùng EAS, không cần token EAS**.
- [2026-08-13] Fix CI-critical: `android/gradle.properties` trước đây hard-code `org.gradle.java.home=/Library/Java/...` (path macOS) → **fail trên runner Linux** của GH Actions. Bỏ hardcode, Gradle giờ chọn JDK qua `JAVA_HOME` (CI: setup-java; local: export trong `.project/ai-rules.md`).
- [2026-08-13] Verify: run GH Actions `31661329510` **completed/success** (mọi step xanh: JDK 21, Flutter 3.44.9, pub get, Build APK, Upload artifact). APK tải về: `dist-apk/app-release.apk` 66.8MB (64M), valid zip, có `classes.dex` + `AndroidManifest.xml`. Lưu ý: release hiện ký bằng **debug signing config** (`android/app/build.gradle.kts`) — APK build để test nội bộ; publish Play Store cần signing config thật.
- [2026-08-13] Tạo skill `.opencode/skills/build-apk-github/SKILL.md` (đã push cùng repo) — hướng dẫn lần sau AI build APK/AAB trên GH Actions: repo link, trigger push `main`/`workflow_dispatch`, poll run, tải artifact, cách thêm step build AAB. **Token KHÔNG hardcode trong skill** (repo public — GitHub tự revoke token lộ); token đọc từ `.env` (gitignored, key `GH_TOKEN`).
- [2026-08-13] Lưu ý: `.env` tạo mới (gitignored) chứa `GH_TOKEN` — KHÔNG commit file này.

## Docs: refresh .project/ (2026-08-12)

- [2026-08-12] Xong: Cập nhật `.project/` theo ai-rules (state.md sau mỗi task lớn):
  - `state.md` — refresh toàn bộ (milestones M0→M2.5 + guidance, test 203/203, session notes 08-08→08-12, todo mở: commit chờ duyệt, manual device tests, MEDIUM fixes còn lại).
  - `README.md`/`overview.md` — TL;DR + tech stack mới (notifications/backup/IAP/ads deps, ARB l10n) + cấu trúc thư mục + roadmap (M0✅→guidance✅) + quyết định #9/#10 (guidance persist, monthly-equivalent).
  - `architecture.md` — StorageBackend split (web localStorage), schema v2 (columns + price_history), routes mới (/calendar, /paywall, /more/*, error page), providers wiring, l10n ARB (xóa `app_strings`).
  - `patterns.md` — fix §5 (LocalStorage* + FK order), §8 (l10n qua ARB/context.l10n, formatDate locale-aware), thêm §10 guidance overlay toolkit.
  - `modules/README.md` + `modules/guidance.md` (mới) — module doc guidance; M2/M2.5 modules chưa có doc riêng → ghi chú trỏ working.md/openspec.

## OpenSpec: change subtrack-guidance (2026-08-12)

- [2026-08-12] Xong: Tạo OpenSpec change `subtrack-guidance` (retrospective — ghi lại 2 việc đã ship ngày 2026-08-12):
  - Capability `in-app-guidance` — FeatureBadge, Spotlight & tooltip (positioning responsive), DisabledStateHelper, GuidanceHost + GuidanceController (persist `app_settings`), show-once rules.
  - Capability `review-bugfixes` — 7 lỗi đã fix (FK-safe Replace All, monthly-equivalent, category display name, locale dates, import reconcile, lifecycle UI refresh, StatusChip overflow).
  - Artifacts: `proposal.md` + `specs/{in-app-guidance,review-bugfixes}/spec.md` + `design.md` (D1–D8) + `tasks.md` (retrospective, all [x]). `openspec validate` 5/5 pass (4 change cũ + 1 mới). Lưu ý: `openspec validate --changes <tên>` (số nhiều), không phải `--change`.

## Full review fixes — HIGH/MEDIUM (2026-08-12)

- [2026-08-12] Xong: Review toàn bộ code (3 reviewer agents + verify trực tiếp trên code, loại false positives) → fix 7 lỗi HIGH/MEDIUM:
  - **#1 FK crash Replace All** (`backup/import_service.dart`): `_applyReplace` từng xóa categories TRƯỚC subscriptions → FK violation (`PRAGMA foreign_keys = ON`) trên real sqlite. Giờ đảo thứ tự (subscriptions trước). Verify: `subscription_price_history` có `ON DELETE CASCADE` nên không có crash sâu hơn. Test regression mới chạy trên **real in-memory sqflite** (fake repos không enforce FK nên trước đó không bắt được).
  - **#2 Monthly Cost** (`dashboard_controller.dart`): `monthlyTotal` trước chỉ đếm cycle monthly → weekly/quarterly/yearly/custom bị mất khỏi headline Home. Giờ = `yearlyTotal ~/ 12` (monthly-equivalent mọi cycle), `monthlyByCurrency` đồng bộ, xóa `_sumByCycle` (dead). Test cập nhật + thêm test chuyển đổi.
  - **#3 Raw category id** (`subscription_detail_screen.dart`): detail hiển thị `sub.categoryId!` (UUID/slug) → giờ `_DetailBody` là ConsumerWidget resolve tên qua `categoryControllerProvider`, fallback `l10n.uncategorized` (key đã có sẵn). Test widget mới `subscription_detail_test.dart` (tên hiển thị + fallback).
  - **#4 Date format locale-aware** (`subscription_list_screen.dart` `formatDate`): hard-code MM/DD → giờ nhận context, `vi → dd/MM`, else MM/DD (không đổi behavior EN nên test cũ không vỡ).
  - **#5 Backup import → reconcile** (`backup_screen.dart`): sau import gọi `notificationCoordinatorProvider.onSubscriptionsChanged()` (best-effort try/catch) — stale reminders bị cancel ngay thay vì chờ lần mở app sau.
  - **#6 Reconcile transition → UI** (`core/providers.dart`): `updateSubscription` của scheduler giờ invalidate `subscriptionListControllerProvider` + `dashboardControllerProvider` sau transition PENDING_CANCELLATION → CANCELLED (trước đây đổi âm thầm đến khi có data change khác). Phân tích: hội tụ (transition 1 lần, reconcile lần 2 không còn gì để đổi).
  - **#7 StatusChip overflow** (`subscription_list_screen.dart`): text chip maxLines 1 + ellipsis, tile trailing bọc `ConstrainedBox(maxWidth: 110)`.
  - Verify: `flutter analyze` 0 issues; `flutter test` **203/203 pass** (+4: FK regression, monthly-equivalent, 2 detail widget).

## In-app Guidance & User Onboarding (2026-08-12)

- [2026-08-12] Xong: Feature `guidance` (`lib/features/guidance/`) — 3 components UI + state + positioning:
  - `FeatureBadge` (dot/label "New") — overlay góc trên-phải element, `visible` từ guidance state (tắt sau khi step đã xem).
  - `SpotlightOverlay` + `tooltip_geometry.dart` — dim background + khoét lỗ quanh target (CustomPaint), tooltip tự định vị responsive (ưu tiên dưới, flip trên, clamp màn hình), Skip/Next/Done, tap backdrop = next. `GuidanceHost` orchestrator: đo target qua GlobalKey, tuần tự steps, show-once.
  - `DisabledStateHelper` — wrap control disabled, tap → dialog/tooltip giải thích lý do + điều kiện unlock (vd: free-tier limit → nút "Unlock Pro").
  - State: `GuidanceController` (AsyncNotifier) persist qua bảng `app_settings` (`guidance.steps`/`guidance.tours`, comma-joined — theo rule project, không shared_preferences). Trigger: tour chỉ hiện 1 lần (seenTourIds); step ghi nhận riêng; Skip = completeStep tất cả steps (clear badge) + mark tour seen.
  - Wire demo: Home (`GuidanceHost` tour 2 steps: Cost card → View calendar + FeatureBadge "New" trên calendar); SubscriptionList FAB bọc `DisabledStateHelper` khi free-tier hard-block (11+). L10n EN+VI keys `guidance*`/`featureNew`/`disabledFreeLimit*`.
  - Verify: `flutter analyze` 0 issues; `flutter test` 199/199 pass (thêm `test/guidance_test.dart` 19 tests: tooltip geometry, controller persist/show-once, FeatureBadge, DisabledStateHelper dialog, SpotlightOverlay, GuidanceHost tour flow + skip clears steps).
  - Lưu ý: tour Home chỉ chạy khi có ≥1 subscription active (target cards tồn tại) — empty state không hiện tour, sẽ thử lại khi có data (intended).

## targetSdk 36 (2026-08-12)

- [2026-08-12] Xong: `android/app/build.gradle.kts` — set tường minh `targetSdk = 36` (Google Play yêu cầu API 36 từ 31/08/2026). Flutter 3.44.6 mặc định `flutter.targetSdkVersion = 36` (APK trước đó đã là 36), nhưng pin cứng để không phụ thuộc default Flutter đổi sau này. Verify: `flutter build apk --release` pass (61.7MB), aapt2 badging `targetSdkVersion:'36'`; `flutter analyze` 0 issues; `flutter test` 180/180 pass.

## Release APK http cleartext hardening (2026-08-12)

- [2026-08-12] Xong: Chuyển cơ chế cho phép http:// mọi domain từ chỉ `android:usesCleartextTraffic="true"` sang **`network_security_config.xml`** (`res/xml/`, base-config `cleartextTrafficPermitted="true"`) + tham chiếu `android:networkSecurityConfig="@xml/network_security_config"` trong manifest main — robust hơn, không bị library manifest merger override. Verify: `flutter build apk --release` pass (61.3MB), aapt2 dump merged manifest thấy INTERNET + POST_NOTIFICATIONS + usesCleartextTraffic=true + networkSecurityConfig=@0x7f110003; resource `xml/network_security_config` có trong APK. `flutter analyze` 0 issues; `flutter test` 180/180 pass.
- [2026-08-12] Fix môi trường: `material_color_utilities` (0.13.0, SDK 3.44.6 yêu cầu) bị MẤT khỏi pub-cache (ENOSPC truncate tái diễn) → build release fail với `Undefined name 'MaterialDynamicColors'` + `Failed to apply plugin flutter-plugin-loader`. Khôi phục bằng `flutter pub get` (tải lại package vào cache). Lưu ý: nếu build release fail lần nữa với 2 lỗi trên, chạy `flutter pub get` trước.

## AdMob thật + package com.subguard.app (2026-08-11)

- [2026-08-11] Xong: Đổi package về `com.subguard.app` — Android `namespace`/`applicationId` trong `android/app/build.gradle.kts` + move `MainActivity.kt` sang `com/subguard/app/` (xóa path cũ); iOS `PRODUCT_BUNDLE_IDENTIFIER` 6 chỗ trong `project.pbxproj` (`com.subguard.app` / `com.subguard.app.RunnerTests`); cập nhật comment `adb pm clear` trong `integration_test/device_ux_test.dart`.
- [2026-08-11] Xong: Thay AdMob TEST IDs bằng ID thật — app ID `ca-app-pub-6917313063209470~5291822252` vào `AndroidManifest.xml` (APPLICATION_ID) + `ios/Runner/Info.plist` (GADApplicationIdentifier); banner `.../7565917792`, interstitial `.../3877954222` vào `ads_config.dart` (cùng ID cho Android+iOS); rewarded `.../7247333533` lưu sẵn `AdConfig.rewardedUnitId` nhưng chưa wire flow. `google-services.json` đã có package_name `com.subguard.app` ✓.
- [2026-08-11] Verify: `flutter analyze` 0 issues; `flutter test` full suite green (180/180); `flutter build apk --debug` pass; APK badging confirm `package=com.subguard.app` + `MainActivity` đúng.
- [2026-08-11] Test trên device thật (Pixel 3a Android 12, wireless adb): AdMob SDK init OK (log `MAIN: ads supported, initializing` → dynamite module load, `Ads: Updating ad debug logging`), app launch không crash. Banner request được gửi tới ad unit thật `ca-app-pub-6917313063209470/7565917792` nhưng nhận **No fill (code 3)** — device `962FE07BFB1C8888075C15B8647EC8BE` chưa đăng ký test device trong AdMob console (log gợi ý `setTestDeviceIds`). KHÔNG phải lỗi cấu hình — cần đăng ký test device hoặc chờ ad unit active để thấy banner hiển thị. Không có crash/lỗi AdMob.
- [2026-08-11] Lưu ý môi trường: disk-full (ENOSPC) tái diễn 2 lần trong phiên (97%) — pub-cache bị truncate (`flutter_riverpod`/`vector_math` mất) → phải `flutter clean` + `rm -rf build android/.gradle` + `flutter pub get` lại. Integration test trên device mất ~3 phút build + install; `device_ux_test.dart` fail vì l10n resolution timing trên device (không liên quan AdMob); đã tạo+chạy+đã xóa `ads_diag_test.dart` tạm để chẩn đoán.

## Nav hardening + HTTP cleartext + SafeArea (2026-08-10)

- [2026-08-10] Xong: Release APK cho phép http:// mọi domain — thêm `INTERNET` permission + `android:usesCleartextTraffic="true"` vào main `AndroidManifest.xml` (verify: aapt2 dump APK thấy cả 2).
- [2026-08-10] Xong: Rà soát nav toàn diện — Categories chuyển từ raw `Navigator.push` sang GoRouter route `/more/categories` (có URL + back stack đúng); thêm `errorBuilder` recovery screen cho path không tồn tại (l10n `errorTitle`/`errorBody` EN+VI, nút Home).
- [2026-08-10] Xong: Fix deep-link edge case — top-level route `/paywall` & `/calendar` khi vào thẳng (web URL/cold start, không có back stack) giờ hiển thị nút Home thay vì dead-end; `GoRouter.maybeOf` giữ widget test không-router chạy được. Deep link trước onboarding vẫn được restore sau khi hoàn thành (đã có sẵn `_pendingDestination`).
- [2026-08-10] Xong: PopScope cho paywall/calendar/not-found — system back khi không có back stack → `context.go('/home')` thay vì thoát app.
- [2026-08-10] Xong: SafeArea cho các màn full-screen được push (paywall, calendar, settings, backup, categories, detail, add/edit) — bottom inset trên thiết bị có gesture bar không còn bị che.
- [2026-08-10] Xong: Web build không warning (chỉ note wasm informational); bundle JS 0 sqlite/8 localStorage.
- [2026-08-10] Test: thêm `test/navigation_deep_link_test.dart` 5 tests (not-found recovery, deep-link /calendar /paywall có Home, /more/categories back, deep-link trước onboarding). Verify: `flutter analyze` 0 issues, `flutter test` 180/180 pass, `flutter build apk --release` pass, `flutter build web` pass.
- [2026-08-10] Fix web bootstrap: `web/index.html` vẫn dùng legacy `window.flutterConfiguration` (deprecated, gây assertion → app web không boot được) → tạo `web/flutter_bootstrap.js` dùng API mới `_flutter.loader.load({config: {semanticsEnabled: true}})`. Verify qua CDP headless Chrome: boot hoàn chỉnh, không còn deprecated/assertion warning, semantics tree đọc được đầy đủ.
  - Web runtime test (CDP headless Chrome, click thật qua full flow): onboarding hoàn tất → Home render empty state → `/#/calendar` hiển thị calendar + nút Home → `/#/nonexistent-page` recovery "Page not found" + nút Home. Console sạch (chỉ 1 `Falling back to CPU-only rendering` do `--disable-gpu` của headless test, không phải lỗi app). Noto fonts warning trong Chrome thật chỉ xuất hiện 1 lần (transient/CDN hiccup) — không tái lập sau hot restart hay trên headless en/vi.
  - `flutter build web` sạch; bootstrap đã build chứa `semanticsEnabled`, không còn `window.flutterConfiguration`.
- [2026-08-10] Lưu ý môi trường: disk-full (ENOSPC) làm pub-cache bị truncate giữa chừng → phải `flutter pub get` lại để khôi phục flutter_riverpod/go_router trước khi chạy analyze/test.

## Storage platform split (2026-08-10)

- [2026-08-10] Xong: Tách storage theo platform — iOS/Android giữ SQLite (sqflite), **web chuyển từ sqflite-WASM sang browser localStorage**; giữ nguyên interface repository (SubscriptionRepository/CategoryRepository/SettingsRepository) + business logic. Kiến trúc: `StorageBackend` interface + factory conditional-import (`storage_backend_factory.dart` — stub=SQLite/web=localStorage); `LocalStorageStore` (JSON rows theo đúng shape `toMap()/fromMap()`) + `LocalStorageSeeder` (dùng chung seed data từ `seed_data.dart`); 3 repo localStorage (`local_storage_*_repository.dart`) mirror đúng semantics sqflite (default-category block, unassign khi delete, price-history cascade, upsert-by-id). `providers.dart`: 3 repo providers giữ nguyên tên, route qua `storageBackendProvider` (tests override cũ vẫn chạy). Web bỏ `sqflite_common_ffi_web` + WASM (bundle JS giờ 0 reference sqlite), thêm `web` package. Verify: analyze 0 issues, `flutter test` 175/175 pass (thêm `local_storage_repository_test` 12 tests), `flutter build web` pass. Lưu ý: `databaseProvider` giữ lại chỉ cho test override (lib không dùng nữa).

## M2.5 — Decision Engine Layer (`subtrack-decision-engine`)

- [2026-08-10] Xong: OpenSpec change `subtrack-decision-engine` (6 feature từ `.plan/plan2_final.md`): proposal + 4 spec (decision-engine, money-calendar, price-history, subscription-lifecycle) + design + 30 tasks; validate strict pass.
- [2026-08-10] Xong: Schema migration v2 — additive `ALTER TABLE` (`last_reviewed_at`, `review_interval_days DEFAULT 90`, `pending_cancellation`, `cancelled_at`, `previous_amount_minor`, `superseded_at`) + bảng `subscription_price_history` (FK cascade, index); test migrate v1→v2 bảo toàn dữ liệu (seed legacy row shape).
- [2026-08-10] Xong: Lifecycle PENDING_CANCELLATION — cancel ở detail (mở `cancellationUrl` rồi set status), auto-transition → CANCELLED (`cancelled_at = nextBillingDate`) trong `NotificationScheduler.reconcile()` (wired `loadAll` + `updateSubscription` ở providers), `PENDING_CANCELLATION` vẫn tính slot Free 10 (`paywallSlotCount`); thêm `url_launcher`.
- [2026-08-10] Xong: Review Queue — `ReviewQueueService` (trial ≤3d/renewal ≤1d high; price-changed/stale 90d medium), cap 3 + "Review all", Keep→`lastReviewedAt=today`/Cancel→pending/Later→session-hide, import set `last_reviewed_at = created_at` (không backlog giả).
- [2026-08-10] Xong: Today Money Brief (`TodayBriefService`) — next renewal + countdown, trial warning ≤3d, "Nothing due today"; thay Upcoming card cũ, là card đầu Home.
- [2026-08-10] Xong: Savings Counter (`SavingsCalculator`) — projected (pending+cancelled, trừ superseded) / realized (cycles sau cancelledAt) / pre-cancellation baseline, nhóm theo currency, "estimated"; re-subscribe cùng tên → `supersededAt` dừng realized.
- [2026-08-10] Xong: Money Calendar dot-only (`MoneyCalendarService` + screen + route `/calendar`) — chỉ render tháng đang xem, 1 ngày = 1 dot, tap ngày → list + total theo currency; Home card tháng + "View calendar".
- [2026-08-10] Xong: Price Change Detection — edit amount sub ACTIVE → dialog PRICE CHANGED (delta + %, yearly mới/cũ; đổi currency → không so sánh %, chỉ ghi history) + `recordPriceChange` vào `subscription_price_history` (cascade delete).
- [2026-08-10] Xong: Home "Money Command Center" 4 card (Monthly Cost ↓savings / Today / Needs Attention / Month + calendar), empty state giữ nguyên; overflow-safe MoneyText (Flexible/ellipsis) cho số VND dài; l10n EN+VI đầy đủ.
- [2026-08-10] Verify: `flutter analyze` 0 issues; `flutter test` 159/159 pass (thêm `decision_engine_test` 24 unit, `decision_engine_widget_test` 4 widget, lifecycle auto-transition, paywall slot count, price-history persist/cascade). Việc cần confirm với user: calendar hiện chỉ render charge từ hôm nay trở đi (tháng quá khứ trống) — deliberate per test.

## UI bugfix + AdMob (2026-08-09)

- [2026-08-09] Fix bug: onboarding preset tile tap làm gì cũng không (callback rỗng) — giờ tap toggle chọn (border primary + checkmark badge + đếm "N selected"), selection persist vào `app_settings` (`onboardingPresets`) và pre-fill form thêm đầu tiên (tên/category/icon/URL, không giá/cycle — đúng spec §6); preset bị consume sau khi save thành công.
- [2026-08-09] Fix bug: tab Subscriptions "Right overflowed by X pixels" — trailing Column (amount VND dài + status chip) giờ bị constrain maxWidth 110 + ellipsis (`MoneyText` thêm `maxLines`/`overflow`); áp phòng ngừa cho Home tiles.
- [2026-08-09] Fix bug: Settings "Appearance" mỗi chữ 1 dòng — SegmentedButton thoát khỏi ListTile trailing, render full-width dưới title.
- [2026-08-09] Fix bug: Categories tap không highlight — ListTile có `onTap` toggle `selected` (selectedTileColor + title primary + check cho default).
- [2026-08-09] Xong: AdMob (user duyệt amendment privacy — SDK mạng thứ 3 duy nhất): `google_mobile_ads ^9.0.0`; banner adaptive đáy Home + Subscriptions, interstitial mỗi 5 lần thêm sub (free tier), Pro xóa ads, non-personalized `npa=1`, no ATT; Android manifest APPLICATION_ID (TEST id), iOS Info.plist GADApplicationIdentifier + SKAdNetworkItems; web/test no-op qua `AdConfig.supported`. Copy About/paywall EN+VI cập nhật; spec privacy-compliance + privacy-labels.md amended; thêm widget tests (preset selection, long-amount no overflow, categories highlight, settings narrow-screen).

## M2 — Platform store layer (`subtrack-platform-store`)

- [2026-08-08] Xong: Phase A — Notifications (scheduler 7-bước, deterministic IDs, Trial Shield, timezone reconcile, reboot rescheduler qua workmanager; 19/19 tests).
- [2026-08-08] Xong: Phase B — i18n EN/VI (gen-l10n, runtime switch, preset names theo key, user data không localize; 6/6 tests; xóa `app_strings.dart`).
- [2026-08-08] Xong: Phase C — Backup & Transfer (codec versioned + validate, export share sheet, import Merge/Replace trong transaction, BackupScreen dưới More; 9/9 tests).
- [2026-08-08] Xong: Phase D — IAP & paywall (Lifetime Pro, ProEntitlementController persisted, free-tier 1–8/9–10 banner/11+ block, PaywallScreen + gate add flow; 9/9 tests).
- [2026-08-08] Xong: Phase E — Privacy & DoD (dependency/permission audit sạch, integration_test privacy skeleton, docs/privacy-labels.md, docs/dod-checklist.md).
- [2026-08-08] Fix môi trường build Android: JDK 11→21 (`org.gradle.java.home`), core library desugaring, file_picker 3.0.4→8.3.7 (jcenter/AGP9/Kotlin-built-in), share_plus 13→12 (win32 conflict), compileSdk 36 ép qua root build.gradle.kts; `flutter build apk --debug` pass, merged manifest chỉ có permissions hợp lệ.
- [2026-08-08] Verify: `flutter analyze` 0 issues; `flutter test` 116/116 pass; APK debug build OK.
- [2026-08-08] Web support: thêm platform web (`flutter create --platforms web`), sqflite WASM (`databaseFactoryFfiWeb` qua conditional import `database_factory.dart`), guard web cho notifications/timezone/IAP (no-op trên web), bật semantics trong `web/index.html`. Build web pass, test headless Chrome OK: load app, qua onboarding, 3 tabs (Home/Subscriptions/More) hoạt động, Settings/Backup render đúng, 0 exceptions. Lưu ý: notifications/workmanager/backup-file-IO/share là native-only — trên web là no-op hoặc giới hạn.
- [2026-08-08] Còn lại (cần device/store): backup reinstall restore (2.6), IAP sandbox (3.5), integration test network-disabled trên device (5.2).

## M1 — App surface (đã xong trước đó)

- Onboarding, dashboard, subscription list/detail/add-edit, categories, settings (theme/currency/categories), More tab, app router (bottom nav), money formatting, empty states.

## M0 — Domain core (đã xong trước đó)

- Models (Subscription, Category, settings), sqlite repository, billing calculator, preset catalog, settings controller.
