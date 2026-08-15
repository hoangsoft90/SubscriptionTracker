# State (trạng thái hiện tại)

> Cập nhật lần cuối: 2026-08-15 (phiên: Ads + Multi-currency + Release infra + OpenSpec + Store polish + Store listing + enable_ads flag + Due-alert dialog).
> File này đổi thường xuyên — dùng ISO date `YYYY-MM-DD` cho mọi mục.
> Chi tiết theo ngày ở `working.md`; quy tắc code ở `ai-rules.md`.

## Milestone status

| Milestone | Change | Tasks | Trạng thái |
| --- | --- | --- | --- |
| M0 | `subtrack-core-engine` | 23/23 | ✅ Hoàn thành, đã review |
| M1 | `subtrack-core-ux` | 30 tasks | ✅ Hoàn thành (UI + tests + review) |
| M2 | `subtrack-platform-store` | 116/116 tests | ✅ Hoàn thành (notifications, backup, IAP, i18n, privacy) |
| M2.5 | `subtrack-decision-engine` | 30 tasks | ✅ Hoàn thành (brief, queue, savings, calendar, price-history, lifecycle) |
| — | Storage platform split (web localStorage) | 175/175 tests | ✅ Hoàn thành (2026-08-10) |
| — | Guidance + Review fixes | `subtrack-guidance` | ✅ Hoàn thành (2026-08-12) |
| — | Ads + Multi-currency + Release infra + Display reliability | `subtrack-monetization-release` | ✅ Hoàn thành (2026-08-15, retrospective) |
| — | Store polish (banner shell flush nav, privacy email, feature graphic, code-review fixes) | `subtrack-store-polish` | ✅ Hoàn thành (2026-08-15, retrospective) |
| — | Store listing (launcher label "Subscription Tracker", `chplay.md`, JotBird/tmpfiles sharing) | `subtrack-store-listing` | ✅ Hoàn thành (2026-08-15, retrospective) |
| — | Platform config (targetSdk 36, network_security_config, package `com.hoangsoft.subtrack`) | — | ✅ Hoàn thành (2026-08-11/15) |
| — | `enable_ads=false` mặc định (dart-define `ENABLE_ADS`) + Due-alert dialog (1 lần/ngày) | — | ✅ Hoàn thành (2026-08-15) |

## Test status (2026-08-15)

- **257/257 tests pass** ✓ (247 cũ + 10 mới: `due_alert_test.dart` — service 9 + dialog widget 1)
- `flutter analyze` — **No issues found** ✓
- GH Actions: tách 2 workflow — `build-debug-apk.yml` (debug APK, no keystore, push main) + `build-release-aab.yml` (release AAB ký thật từ GitHub Secrets, manual). Run debug mới nhất (chứa banner shell fix + 3 code-review fixes) đang build.
- OpenSpec: **8/8 changes validate pass** (7 cũ + `subtrack-store-listing`).

Phân bổ tests (chính):
- Core: `money_test`, `billing_calculator_test`, `data_storage_test`, `local_storage_repository_test` (web storage), `backup_test`, `notifications_test`, `l10n_test`, `ads_test` (8: cooldown/frequency policy + test-ads default true), **`exchange_rates_test`** (conversion USD-pivot, missing-rate null, sumConvertedTo, defaults), **`due_alert_test`** (10: service high-priority filter + dialog widget)
- Nav: `navigation_deep_link_test` (10)
- Controller: `subscription_list_controller_test`, `dashboard_controller_test` (+3 multi-currency), `free_tier_test`, `decision_engine_test`
- Widget: `m1_widget_test`, `m1_crud_widget_test`, `widget_harness`/`fakes`, `decision_engine_widget_test`, `ux_bugfix_widget_test`, `guidance_test` (19), `subscription_detail_test` (2), **`subscription_display_test`** (display/refresh/currency), **`banner_layout_test`** (2: ad placeholder collapse → SizedBox fix), **`real_db_add_flow_test`** (real sqflite integration), **`web_storage_flow_test`** (localStorage layer)
- `integration_test/`: `device_ux_test` (package `com.hoangsoft.subtrack`), `privacy_network_test`, `probe_test`

## Todo mở (next steps)

1. [x] **Commit** toàn bộ code — đã push lên `main` nhiều lần (mới nhất 2026-08-15).
2. [ ] Manual device tests còn lại (đã ghi trong platform-store tasks):
      backup reinstall restore (2.6), IAP sandbox (3.5), privacy network on-device (5.2).
3. [ ] Cài APK mới (package `com.hoangsoft.subtrack`, launcher label "Subscription Tracker")
      lên máy thật + test lại: add → 2 tab update ngay, pull-down giữ data, chờ ad
      load list vẫn hiển thị, FAB không bị banner che; banner chạm sát nav buttons
      (banner shell); paywall lỗi hiện đúng copy + slot count khớp gate; **ads tắt
      hoàn toàn (enable_ads=false)**; **due-alert dialog hiện đúng 1 lần/ngày khi có
      sub đến hạn hôm nay/mai hoặc trial ≤3 ngày**. Build cuối: commit (due-alert)
      → GH Actions run mới (Build Debug APK).
4. [ ] OCR (open-code-review) đang lỗi 401 config — cần user sửa; fallback hiện
      dùng code-reviewer + review mặc định.
5. [ ] Sync/archive OpenSpec change cũ vào `openspec/specs/` khi có nhu cầu.
6. [ ] Trước khi bật ads thật (test_ads=false): tạo AdMob app mới cho package
      `com.hoangsoft.subtrack` + thay ID trong `ads_config.dart`.
7. [ ] (publish store) Chạy workflow `build-release-aab.yml` (manual) để sinh AAB
      ký thật submit Play Store.

## Ghi chú phiên gần đây

- **2026-08-15 (enable_ads + Due-alert)**: `AdConfig.enabled` giờ đọc dart-define
  `ENABLE_ADS` mặc định **false** — ads tắt toàn bộ (main.dart không init AdMob,
  banner/interstitial no-op); bật lại sau này bằng `--dart-define=ENABLE_ADS=true`.
  Thêm **due-alert dialog** (1 lần/ngày khi mở app): `DueAlertService`
  (`lib/features/decision/due_alert.dart`, lọc HIGH-priority Review Queue — renewal
  hôm nay/mai + trial ≤3 ngày), `DueAlertDialog` (`decision/presentation/`, tap item
  → detail, View all → Home), wire trong `_AppShell` (`app_router.dart` — watch
  subscription list lần load đầu, gate theo `settings` key `dueAlertLastShown`
  YYYY-MM-DD persist TRƯỚC khi show, guard kIsWeb/FLUTTER_TEST như AdConfig). L10n
  keys `dueAlert*` EN+VI (7). Verify: analyze 0, **257/257 pass**. Xem `working.md`
  mục đầu 2026-08-15.
- **2026-08-15 (store-listing)**: Launcher label "subtrack" → "Subscription Tracker"
  (Android `android:label` + iOS `CFBundleDisplayName` + web title/manifest) — internal
  identifiers giữ nguyên (product id `subtrack_lifetime_pro`, `subtrack.db`, storage
  prefix, notification channel, in-app brand "SubTrack") để không mất dữ liệu/store
  linkage. Tạo `chplay.md` (root) — toàn bộ Play Console listing: App Name/Short/Full
  Description EN+VI, Finance + 5 tags, 4 screenshot ideas, feature graphic/icon notes,
  content checklist. Publish `chplay.md` lên JotBird
  (https://share.jotbird.com/soft-playful-moonbeam, 90-day TTL; lần đầu 403 Cloudflare
  → curl + UA trình duyệt OK); zip `icon.png`+`feature-graphic.png` lên tmpfiles.org
  (https://tmpfiles.org/wpw3SAjPUsGo/subtrack_store_assets.zip, tạm thời ~1h). OpenSpec
  retrospective `subtrack-store-listing` (2 specs: launcher-label, asset-sharing) —
  validate **8/8**. Commits `de03761` (launcher label + chplay.md) + `db8db5e`
  (openspec + working.md). JotBird key KHÔNG commit (grep 0 match). Xem `working.md`
  mục 2026-08-15 (mục đầu).
- **2026-08-15 (store-polish)**: Banner chuyển lên **shell** (`_AppShell`
  `bottomNavigationBar` = `Column [BannerAdView, NavigationBar]`) — nằm trực tiếp
  trên nav buttons, đều cả 3 tab, bỏ SafeArea gap; xóa banner khỏi Home/Subscriptions
  (FAB vẫn nổi trên). Privacy policy bỏ GitHub repo → email `haibasoftware@gmail.com`
  (EN+VI, md+html, gh-pages redeploy `8bca378`). Tạo `feature-graphic.png` 1024×500
  (PIL, brand teal) + verify `icon.png` 512×512. **Full code review 83 files → fix 3 lỗi:**
  paywall failure hiện nhầm copy backup → `paywallError` EN+VI; paywall "N/10 slots"
  đếm ACTIVE-only không khớp gate → `paywallSlotCount`; lỗi tỷ giá Settings hardcode
  English → `settingsExchangeRatesInvalid`. OpenSpec retrospective `subtrack-store-polish`
  (3 specs) — validate 7/7. Verify: analyze 0, 247/247. Commits `d4582f9` + `f8b3646`.
  Xem `working.md` mục 2026-08-15 (3 mục đầu).
- **2026-08-15**: Ads + Multi-currency + Release infra + Display reliability
  (retrospective OpenSpec `subtrack-monetization-release`):
  - `testAds` default true (tránh AdMob limit tài khoản chưa duyệt); interstitial
    frequency (mỗi 5 add) + cooldown 5 phút; banner fix layout (SizedBox AdSize —
    platform-view infinite height từng làm list collapse) + chuyển banner sang
    `bottomNavigationBar` (FAB không bị đè).
  - Multi-currency: `lib/core/money/exchange_rates.dart` (USD-pivot, exact int
    math, null khi thiếu rate), live API open.er-api.com + manual fallback trong
    Settings (`_ExchangeRatesSection`), Home headline convert về primary + breakdown
    từng currency + note "≈"; list hiển thị ISO code. Dep mới `http`.
  - Release infra: package `com.subguard.app` → `com.hoangsoft.subtrack` (Android
    + iOS + google-services.json + comments), targetSdk 36, tách 2 GH workflows,
    keystore vào GitHub Secrets (4 secrets), privacy policy trên gh-pages.
  - Display reliability: `reload()` null-safe (mutation race initial build),
    invalidate dashboard sau mọi mutation (Home update ngay), pull-to-refresh list,
    notification permission UI trong Settings.
  - Verify: analyze 0 issues, **247/247 tests pass**, validate openspec 6/6.
  Xem `working.md` mục 2026-08-15.
- **2026-08-13/14**: Home stale fix (invalidate dashboard sau mutation),
  notification permission UI, nav rà soát + safe back + web warnings sạch,
  privacy policy + gh-pages, ads test mode + cooldown + full code review
  (fix crash backup import + localStorage price-history), banner collapse root
  cause device (AdMob platform view infinite height), pull-to-refresh subscriptions.
  Xem `working.md` mục 2026-08-13/14.
- **2026-08-11**: Package `com.subguard.app` (ban đầu) + AdMob ID thật (app
  `ca-app-pub-6917313063209470~5291822252`; banner/interstitial trong `ads_config.dart`,
  App ID AndroidManifest + Info.plist). Test device thật: init OK, banner "No fill"
  (device chưa đăng ký test device — không phải lỗi cấu hình).
- **2026-08-10**: Nav hardening (categories → GoRouter, error recovery page, deep-link
  Home nút, PopScope), HTTP cleartext release APK, SafeArea màn full-screen,
  web bootstrap `flutter_bootstrap.js` (semanticsEnabled). M2.5 decision-engine toàn
  bộ (migration v2 + lifecycle + queue + brief + savings + calendar + price-history)
  + storage platform split (web localStorage, 175/175).
- **2026-08-09**: Fix 4 bug UI + thêm AdMob (amendment privacy user duyệt) — banner đáy
  + interstitial hiếm, free tier, non-personalized, Pro xóa ads; thêm
  `test/ux_bugfix_widget_test.dart`.
- **2026-08-08**: Hoàn thành M2 platform-store (notifications, backup, IAP, i18n,
  privacy; 116/116) + M1 UI toàn bộ + fix 2 production bugs do widget tests phát hiện
  (`billingCycle.name` crash → `dbValue`; `dynamic subscription` → `Subscription`).
  Cài 22 skills `flutter/agent-plugins` vào `.agents/skills/`.
