# Working Log — SubTrack

Format: `- [YYYY-MM-DD] status: mô tả` (ISO dates).

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
