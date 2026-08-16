# Working Log — SubTrack

> Nhật ký trạng thái. Chi tiết từng phiên (2026-08-08 → 2026-08-16) nằm trong
> git history của file này (mỗi phiên commit riêng) + OpenSpec changes
> (`openspec/changes/*`). ISO date `YYYY-MM-DD` cho mọi mục.

## Done

- **2026-08-16 · OpenSpec retrospective `subtrack-ads-release-infra`** — ghi toàn bộ ads saga + release signing fix (commit `db2736c`): 2 specs (ads-real-ids-no-fill-strategy, release-signing-keystore-path). `openspec validate --changes` **10/10 pass**.
- **2026-08-16 · Fix release AAB signing** (`0272a90`) — `android/app/build.gradle.kts`: `storeFile = rootProject.file(...)` (trước là `file(...)` resolve theo module app → `validateSigningRelease` không tìm thấy keystore). Re-trigger build run `31923242287`.
- **2026-08-16 · Chốt chiến lược ads** (`eeeb923`) — debug workflow build `--dart-define=TEST_ADS=true` (Google sample IDs **luôn fill mọi device**) → debug APK hiện test ads; **release AAB giữ ID thật** (không flag). Lý do: ads thật NO_FILL pre-publish (by-design) + Pixel 3a advertising ID xoay vòng (3 ID trong 16h: `C1D6`→`9E19`→`9552`) làm test-device registration vô ích.
- **2026-08-15 · Ads saga** — bật ads thật mặc định (`ENABLE_ADS` true / `TEST_ADS` false, commit `ee4b96d`); test-device registration (`43a863c`, `54b221a`); verify `google-services.json` = `com.hoangsoft.subtrack` (Firebase config — AdMob đọc manifest `APPLICATION_ID` + `ads_config.dart`).
- **2026-08-15 · Device test trên Pixel 3a thật** (`cae8c8e`) — add Netflix qua UI adb → **due-alert dialog hiện đúng** (Netflix+YouTube "renews today"); notification pipeline end-to-end OK (alarm 09:00 → `ScheduledNotificationReceiver`); **fix bug Today card** "You're clear" khi có renewal hôm nay → `TodayBrief.dueToday` + `clear` gồm `!hasEventToday`. OpenSpec `subtrack-device-test-fixes` (`2ec74ed`). 258/258 tests.
- **2026-08-15 · Due-alert dialog + enable_ads flag** (`f4ab599`) — `ENABLE_ADS` default false (tắt ads); dialog cảnh báo 1 lần/ngày (HIGH-priority: renewal hôm nay/mai + trial ≤3 ngày), gate `dueAlertLastShown`. 257/257 tests.
- **2026-08-15 · Store listing** (`db8db5e`, `5a79e6f`) — launcher label "Subscription Tracker" (Android/iOS/web, internal identifiers giữ nguyên); `chplay.md` (Play Console listing) publish JotBird (90-day TTL); zip icon+feature-graphic lên tmpfiles. OpenSpec `subtrack-store-listing`.
- **2026-08-15 · Store polish** (`d4582f9`, `f8b3646`) — banner chuyển lên shell (chạm sát nav buttons, đều 3 tab); privacy policy bỏ GitHub repo → `haibasoftware@gmail.com` (gh-pages redeploy); `feature-graphic.png` 1024×500; full code review 83 files → fix 3 lỗi (paywall copy, slots count, exchange-rate i18n). OpenSpec `subtrack-store-polish`.
- **2026-08-15 · Monetization release** (`f4329eb`, `593244d`) — ads (test default, interstitial cooldown, banner SizedBox fix); **multi-currency** (USD-pivot + live API + manual fallback); **package rename** `com.subguard.app` → `com.hoangsoft.subtrack`; **targetSdk 36**; **tách 2 GH workflows** (debug APK / release AAB ký keystore từ secrets); display reliability (reload null-safe, invalidate dashboard, pull-to-refresh, notification permission Settings). OpenSpec `subtrack-monetization-release`. 247/247 tests.
- **2026-08-13/14 · Display reliability** — fix Home tab stale (invalidate dashboard sau mutation), notification permission UI, nav rà soát + safe back + web sạch warning, privacy policy + gh-pages, ads test mode + cooldown + full code review (fix crash backup import + localStorage), banner collapse root cause (AdMob platform-view infinite height → SizedBox), pull-to-refresh subscriptions. `30a8334` → `9cdb776`.
- **Milestones** — M0 domain core, M1 app surface, M2 platform-store (notifications/i18n/backup/IAP/privacy), M2.5 decision-engine (brief/queue/savings/calendar/price-history/lifecycle), storage platform split (web localStorage), guidance (2026-08-12), onboarding preset fix + AdMob (2026-08-09). Toàn bộ hoàn thành + đã review.

## Doing

- **Release AAB signed** — run `31923242287` (commit `0272a90`, workflow `build-release-aab.yml`) đang build; khi xong tải artifact `subtrack-release-aab` để submit Play Console.
- **Debug APK** — push docs-only mới nhất (`db2736c`) trigger run debug mới (sample test ads).
- **Chờ xác nhận notification** — alarm Netflix 09:00 08-16 đã đến hạn; cần check trên phone (dumpsys notification) xác nhận bắn đúng.

## Todo

1. Tải release AAB từ run `31923242287` → upload Play Console (Internal testing → Production) + điền Store Listing theo `chplay.md`.
2. Verify notification Netflix 09:00 08-16 đã bắn (dumpsys notification) — user sẽ check lại.
3. Manual device tests còn lại: backup reinstall restore (2.6), IAP sandbox (3.5), privacy network on-device (5.2).
4. Sau publish + ad unit activate: xóa `AdConfig.testDeviceIds` (không còn cần test ads) + xác nhận ads thật fill.
5. OCR (open-code-review) đang lỗi 401 — cần user sửa config LLM; hiện fallback review mặc định.
6. Sync/archive OpenSpec change cũ vào `openspec/specs/` khi có nhu cầu.

## Issues

- **OCR 401 Invalid API key** — chưa dùng được; cần user sửa config (không tự cài/sửa).
- **AdMob NO_FILL pre-publish (by-design)** — ads thật chỉ fill sau khi app publish + ad unit activate (vài giờ → vài ngày); không phải lỗi code.
- **Pixel 3a advertising ID xoay vòng** — test-device registration không đáng tin trên máy này (đã chuyển sang sample IDs cho debug).
- `sqflite_common_ffi` không chạy trong widget tests (isolate) — dùng fakes/`WidgetHarness`.
- Dashboard Home dùng indexedStack giữ mọi branch alive — `find.text` có thể match nhiều nơi; dùng `findsWidgets`/scope.
- Môi trường: disk-full (ENOSPC) tái diễn → nếu build fail lỗi pub-cache truncate, chạy `flutter pub get` (hoặc `flutter clean`).

## Summary

SubTrack = Flutter app theo dõi subscription (local-first, sqflite + web localStorage), 3 tab (Home/Subscriptions/More), free-tier 10 slots + Lifetime Pro (IAP), AdMob banner/interstitial non-personalized free tier (Pro gỡ), local notifications 09:00 ngày billing + due-alert dialog 1 lần/ngày, multi-currency USD-pivot report, backup/import, i18n EN/VI, privacy policy trên gh-pages. Package `com.hoangsoft.subtrack`, targetSdk 36, launcher label "Subscription Tracker".

Đã sẵn sàng publish: `chplay.md` (full Play Console listing), keystore release (`subtrack-release.jks`, alias `upload`, SHA256 `B8:9E:20:44:...`, valid 2053) qua GitHub Secrets, workflow `build-release-aab.yml` build AAB ký thật (đang build run `31923242287`), debug workflow dùng sample test ads. Ads thật giữ nguyên ID (`ca-app-pub-6917313063209470...`), fill sau khi store duyệt + activate.

Code quality: `flutter analyze` 0 issues · **258/258 tests pass** · OpenSpec **10/10 changes validate** · CI: GH Actions build debug APK mỗi push main (sample ads) + release AAB manual (real ads, keystore từ secrets). Todo lớn còn lại: submit store + verify ads thật sau publish + manual device tests + OCR config.
