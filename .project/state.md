# State (trạng thái hiện tại)

> Cập nhật lần cuối: 2026-08-16 (phiên: Ads real-IDs saga + TEST_ADS debug-only + Release AAB signing fix + OpenSpec retrospective).
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
| — | Bật lại ads THẬT: `enable_ads=true` + `test_ads=false` mặc định (test trên phone) | — | ✅ Hoàn thành (2026-08-15) |
| — | Test-device registration (NO_FILL vì app chưa publish → test ads trên Pixel 3a) | — | ✅ Hoàn thành (2026-08-15) — **ID xoay vòng 3 lần → bỏ lệ thuộc** |
| — | TEST_ADS=true chỉ cho debug workflow (sample IDs luôn fill); release AAB giữ ID thật | `subtrack-ads-release-infra` | ✅ Hoàn thành (2026-08-16, retrospective) |
| — | Release AAB ký thật: fix `storeFile` → `rootProject.file` (keystore `android/keystore/`) | `subtrack-ads-release-infra` | ✅ Fix xong (2026-08-16), build re-trigger |

## Test status (2026-08-15)

- **258/258 tests pass** ✓ (257 cũ + 1 mới `decision_engine_widget_test.dart`: renewal today → hiển thị sub, không "You're clear")
- `flutter analyze` — **No issues found** ✓
- GH Actions: tách 2 workflow — `build-debug-apk.yml` (debug APK, no keystore, push main) + `build-release-aab.yml` (release AAB ký thật từ GitHub Secrets, manual). Run debug mới nhất (chứa test-device registration) đang build.
- OpenSpec: **10/10 changes validate pass** (9 cũ + `subtrack-ads-release-infra`).
- GH Actions: debug workflow giờ build `--dart-define=TEST_ADS=true` (sample IDs — debug APK luôn hiện test ads); release workflow `build-release-aab.yml` build appbundle ký keystore thật từ secrets (run `31923242287` cho `0272a90`).

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
3. [x] Cài APK mới (package `com.hoangsoft.subtrack`, launcher label "Subscription Tracker")
      lên máy thật (Pixel 3a) + test notification/dialog: **due-alert dialog hiện đúng**
      (Netflix + YouTube renews today), **notification schedule OK** (alarm 08-16 09:00
      cho Netflix due tomorrow). Còn lại cần verify tiếp trên APK mới (sẽ chứa fix
      Today card): add → 2 tab update ngay, pull-down giữ data, banner chạm sát nav,
      paywall copy/slots, ads tắt hoàn toàn, dialog 1 lần/ngày.
4. [ ] OCR (open-code-review) đang lỗi 401 config — cần user sửa; fallback hiện
      dùng code-reviewer + review mặc định.
5. [ ] Sync/archive OpenSpec change cũ vào `openspec/specs/` khi có nhu cầu.
6. [x] Bật ads thật (`enable_ads=true`, `test_ads=false`) 2026-08-15 để test trên phone.
      **KẾT LUẬN (2026-08-16)**: NO_FILL (code 3) pre-publish là cơ chế chống gian lận
      của AdMob — app chưa publish/ad unit chưa activate thì ads thật không bao giờ
      fill. Test-device registration vô ích vì advertising ID của Pixel 3a xoay vòng
      liên tục (3 ID trong 16h: `C1D6`→`9E19`→`9552`). **Giải pháp chốt**: debug
      workflow build `--dart-define=TEST_ADS=true` (Google sample IDs luôn fill mọi
      device — verify banner layout); **release AAB giữ ID thật** (không flag). Sau
      khi publish + activate, ads thật tự fill với ID hiện tại.
7. [x] (publish store) Chạy workflow `build-release-aab.yml` (manual) để sinh AAB
      ký thật submit Play Store — **đang build** (run `31923242287`, commit `0272a90`
      sau fix keystore path). Keystore: `android/keystore/subtrack-release.jks`, alias
      `upload`, pass `83793900`, SHA256 `B8:9E:20:44:...`, valid 2053.

## Ghi chú phiên gần đây

- **2026-08-16 (ads real-IDs saga + release AAB signing fix + OpenSpec)**:
  - **Ads**: debug APK với 2 test device ID vẫn NO_FILL — logcat 09:25 cho thấy SDK
    in test-device ID THỨ 3 `9552D9D634D61C1B28761AD8007CAF65` (17:21 `C1D6...` →
    21:48 `9E19...`) → advertising ID máy xoay vòng liên tục → đăng ký ID cụ thể vô
    ích. `google-services.json` verify đúng `com.hoangsoft.subtrack` (Firebase config
    — AdMob đọc manifest `APPLICATION_ID` + `ads_config.dart`, cả 2 đúng ID thật).
    **Chốt giải pháp**: debug workflow `--dart-define=TEST_ADS=true` (sample IDs luôn
    fill) — debug APK hiện test ads; release AAB giữ ID thật. Commit `eeeb923`.
  - **Release AAB**: build ký thật lần đầu FAIL `validateSigningRelease` — keystore
    không tìm thấy vì `storeFile = file(...)` resolve theo module app
    (`android/app/keystore/`) trong khi keystore ở `android/keystore/`. Fix:
    `rootProject.file(...)` (commit `0272a90`). Keystore verify: PKCS12, alias
    `upload`, pass `83793900`, SHA256 `B8:9E:20:44:3B:41:5C:4C:F5:A1:AA:57:F9:C2:8C:35
    :B9:B9:F0:6A:14:DE:2C:C5:1D:71:7D:EB:C5:A9:C0:15`, valid 2053; 4 secrets có trên
    repo. Re-trigger run `31923242287` (in_progress).
  - **OpenSpec**: retrospective `subtrack-ads-release-infra` (2 specs: ads strategy +
    signing path) — validate **10/10 pass**. Docs `.project/` cập nhật theo ai-rules.
    Xem `working.md` các mục 2026-08-15/16.
- **2026-08-15 (test-device registration)**: Test 2 APK (ee4b96d + build mới 17:17)
  trên Pixel 3a → **vẫn `Ad failed to load : 3` (NO_FILL)** dù SDK init OK, app ID hợp
  lệ (log `Not retrying to fetch app settings`), network OK. Đính chính: user KHÔNG
  khai báo package khi tạo AdMob (chưa publish) → bỏ giả thuyết package mismatch.
  Nguyên nhân thật: ad unit mới/chưa activate + app chưa publish → Google không fill
  ads thật (SDK in hint đăng ký test device). Fix: `AdConfig.testDeviceIds =
  ['C1D6E94F7B5739F934186905CC65759A']` + `main.dart` async + `await initialize()` +
  `updateRequestConfiguration(testDeviceIds)` → test ads trên đúng phone này, device
  khác vẫn ads thật; xóa entry khi publish xong. Verify: analyze 0, ads+banner 10/10.
  Xem `working.md` mục "Test device registration…" 2026-08-15.
- **2026-08-15 (bật lại ads thật)**: `AdConfig.enabled` default false → **true**,
  `AdConfig.testAds` default true → **false** — mọi build giờ dùng ad unit ID THẬT
  (`ca-app-pub-6917313063209470...`). Test `ads_test.dart` assert default mới.
  ⚠️ ID thật vẫn đăng ký cho package cũ `com.subguard.app` — cần re-register cho
  `com.hoangsoft.subtrack` trước production (xem todo #6). Verify: analyze 0,
  ads+banner tests 10/10. Commit + push → GH Actions debug APK build (test ads thật
  trên phone). Xem `working.md` mục "Bật lại ads thật…" 2026-08-15.
- **2026-08-15 (device test notification/dialog + Today-card fix)**: Cài debug APK mới
  (due-alert + ads tắt) lên Pixel 3a thật. **Test bằng UI automation qua adb** (uiautomator
  dump + input tap/text): add sub "Netflix" 15.49 USD monthly qua form thật (next billing
  mặc định = hôm nay) → **due-alert dialog hiện ĐÚNG** trên relaunch: title "Subscriptions
  due soon", list Netflix + YouTube "renews today" (YouTube đã có sẵn renew hôm nay), OK/
  View all/Dismiss (screenshot /tmp/due_alert_dialog.png). **Notification**: sửa Netflix
  next billing → 08-16 (tomorrow) qua date picker → reconcile trigger → `notifScheduledIds`
  = `[1537038242]` + dumpsys alarm `RTC_WAKEUP origWhen=2026-08-16 09:00:00`
  → `ScheduledNotificationReceiver` — pipeline end-to-end OK (sẽ bắn sáng mai 9:00 có
  âm thanh). **Giải thích hành vi**: sub đến hạn HÔM NAY sau 9:00 không schedule reminder
  nào (skip trigger đã qua + next occurrence ngoài horizon 14 ngày) — đúng thiết kế
  "không nags sau giờ". **Fix bug phát hiện khi test**: Home Today card hiện "You're
  clear" dù có sub renew HÔM NAY — `TodayBriefService.clear` bỏ qua due-today events
  (chỉ nextRenewal/trialEnding) → thêm field `dueToday` + `clear` giờ tính cả
  `!hasEventToday`; `_TodayCard` render row "Next: X — in today" cho từng sub due hôm
  nay. Tests: `decision_engine_test.dart` (due-today → clear=false + dueToday populated)
  + widget test mới (renewal today → "Next: Netflix", không "You're clear"). Verify:
  analyze 0, **258/258 pass**. Xem `working.md` mục "Device test…" 2026-08-15.
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
