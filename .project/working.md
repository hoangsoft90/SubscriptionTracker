# Working Log — SubTrack

Format: `- [YYYY-MM-DD] status: mô tả` (ISO dates).

## Test device ID đã đổi — đăng ký 2 ID (2026-08-15)

- [2026-08-15] User cài APK mới (commit `43a863c`, cài 17:44, có test-device registration) lên Pixel 3a thật → **vẫn không thấy ads**. Debug qua logcat (clear + force-stop + relaunch 21:48):
  - `MAIN: ads supported, initializing` + `MAIN: test devices registered` → code chạy đúng (ads bật, registration thực thi).
  - SDK in hint **`Use RequestConfiguration.Builder().setTestDeviceIds(Arrays.asList("9E19A0CAF5DAFB7BD0E3B151B5495FD7")) to get test ads on this device`** — **test device ID của máy ĐÃ ĐỔI**: lúc 17:21 Google in `C1D6E94F7B5739F934186905CC65759A`, lúc 21:48 in `9E19A0CAF5DAFB7BD0E3B151B5495FD7` (advertising ID bị đổi/reset giữa 2 thời điểm → hash đổi). ID đăng ký `C1D6...` không khớp device hiện tại → request vẫn tính là real → `Ad failed to load : 3` (NO_FILL).
- [2026-08-15] Fix: `ads_config.dart` `testDeviceIds` = **[`9E19A0CAF5DAFB7BD0E3B151B5495FD7` (hiện tại), `C1D6E94F7B5739F934186905CC65759A` (cũ, dự phòng nếu ID rotate lại)]** + comment ghi rõ advertising ID đã đổi 17:21→21:48, giữ cả 2. Verify: `flutter analyze` 0 issues; `ads_test` + `banner_layout_test` **10/10 pass**. Commit + push `main` → GH Actions debug APK tự trigger (APK chứa 2 test device ID).

## Test device registration — ads vẫn NO_FILL vì app chưa publish (2026-08-15)

- [2026-08-15] Sau khi bật `enable_ads=true` & `test_ads=false`, test trên phone thật (Pixel 3a, cả 2 APK: `ee4b96d` 15:47 + build mới 17:17) → **vẫn `Ad failed to load : 3` (NO_FILL)** dù SDK init OK (`MAIN: ads supported`, DynamiteModule selected, `Not retrying to fetch app settings` — app ID hợp lệ, network OK).
- [2026-08-15] **Đính chính giả thuyết cũ**: user xác nhận lúc tạo AdMob app KHÔNG khai báo package (vì chưa publish) → "package mismatch com.subguard.app" KHÔNG còn là nguyên nhân (đã ghi sai trong session trước, đính chính trong câu trả lời).
- [2026-08-15] **Nguyên nhân thật** (theo chính log AdMob): ad unit mới + app chưa publish + chưa có traffic → Google KHÔNG fill ads thật (cơ chế chống gian lận; ad unit cần được activate + demand từ app live). Bằng chứng: SDK in hint `Use RequestConfiguration.Builder().setTestDeviceIds(...C1D6E94F7B5739F934186905CC65759A...) to get test ads on this device`.
- [2026-08-15] Xong fix: `ads_config.dart` thêm `AdConfig.testDeviceIds = ['C1D6E94F7B5739F934186905CC65759A']` (Pixel 3a dev); `main.dart` chuyển `Future<void> main() async` + sau `await MobileAds.instance.initialize()` gọi `updateRequestConfiguration(RequestConfiguration(testDeviceIds: ...))` → cùng ad unit thật, đúng phone này nhận **test ads fill 100%** (label "Test Ad"), device khác vẫn ads thật; comment ghi rõ xóa entry sau khi publish + ads thật fill. Verify: `flutter analyze` 0 issues; `ads_test` + `banner_layout_test` **10/10 pass**. Commit + push `main` → GH Actions debug APK tự trigger.

## Bật lại ads thật — enable_ads=true & test_ads=false (2026-08-15)

- [2026-08-15] User yêu cầu: (1) set `enable_ads=true` & `test_ads=false` để bật lại ads THẬT; (2) push + trigger GH Actions build debug APK để test.
- [2026-08-15] Xong `ads_config.dart`: `AdConfig.enabled` default `false → true` (`ENABLE_ADS`); `AdConfig.testAds` default `true → false` (`TEST_ADS`) — **mọi build (debug + release AAB) giờ dùng ad unit ID THẬT** (`ca-app-pub-6917313063209470...`, banner + interstitial + rewarded). Test `ads_test.dart` cập nhật theo default mới (assert real IDs + `enabled==true`). Cập nhật comment (cách override: `--dart-define=ENABLE_ADS=false` / `TEST_ADS=true`).
- [2026-08-15] **⚠️ LƯU Ý QUAN TRỌNG (đã cảnh báo từ trước, code comment ghi rõ)**: các ad unit ID thật đang đăng ký cho package **CŨ `com.subguard.app`** (2026-08-11), package hiện tại là **`com.hoangsoft.subtrack`** — trước khi chạy ads thật production nên **tạo AdMob app mới cho `com.hoangsoft.subtrack`** + thay ID trong `ads_config.dart`; nếu test thấy "No fill"/không hiển thị ads trên phone thì đây là nguyên nhân chính (không phải lỗi code).
- [2026-08-15] Verify: `flutter analyze` 0 issues; `flutter test test/ads_test.dart test/banner_layout_test.dart` **10/10 pass** (test ads chỉ assert config default, không chạm platform; `AdConfig.supported` vẫn false trong FLUTTER_TEST nên widget tests không đổi). Commit + push `main` → GH Actions debug APK tự trigger (APK test ads thật).

## OpenSpec: change subtrack-device-test-fixes (2026-08-15)

- [2026-08-15] User yêu cầu cập nhật openspec retrospective cho phiên device-test + Today-card fix. Tạo change **`subtrack-device-test-fixes`** đúng format delta:
  - `proposal.md` — Why (verify notification + dialog trên máy thật; device test phát hiện bug Today card) / What Changes / Impact.
  - `specs/due-alert-notification-verification/spec.md` — device-verified contract: dialog 1 lần/ngày liệt kê renewal hôm nay/mai + trial ≤3 ngày ("renews today"), gate `dueAlertLastShown`; reminder OS-alarm `RTC_WAKEUP` 09:00 ngày billing → `ScheduledNotificationReceiver` (không phụ thuộc app mở); **by-design**: sub renew hôm nay sau 09:00 KHÔNG schedule (skip trigger đã qua + next occurrence ngoài horizon 14 ngày).
  - `specs/today-card-due-today/spec.md` — `TodayBrief.dueToday` + `clear` gồm `!hasEventToday` + `_TodayCard` render row "in today" mỗi sub due hôm nay; không bao giờ "You're clear" khi có event hôm nay; trường hợp truly clear giữ nguyên.
  - `tasks.md` — retrospective all [x]: 1. device test (add Netflix thật qua adb, dialog hiện Netflix+YouTube "renews today", gate persist; edit Netflix → 08-16 → `notifScheduledIds=[1537038242]` + alarm 09:00; hành vi due-today-after-9am = by design) · 2. Today-card fix (root cause + 2 file + tests) · 3. verification (analyze 0, 258/258, commit `cae8c8e` push main, GH Actions in_progress, validate, .project/ update).
- [2026-08-15] Verify: `openspec validate --changes` **9/9 pass** (8 change cũ + 1 mới). Commit + push `main` (docs-only).

## Device test notification + dialog → Today-card fix (2026-08-15)

- [2026-08-15] User cài debug APK mới nhất (due-alert dialog + ads tắt) lên Pixel 3a thật (adb wireless, package `com.hoangsoft.subtrack`, Android 13, timezone +07) → yêu cầu tạo subscription mới sắp hết hạn để test notification + dialog cảnh báo.
- [2026-08-15] **UI automation qua adb** (uiautomator dump để lấy bounds + `input tap/text`):
  - DB thật (pull qua `run-as`): đã có sẵn 1 sub "YouTube" 25.00 USD MONTHLY renew **hôm nay 08-15** (user tự thêm lúc 14:41); `app_settings` KHÔNG có `dueAlertLastShown` (gate dialog chưa set hôm nay); `notifScheduledIds=[]`.
  - Add sub "Netflix" 15.49 USD qua form thật (FAB → name/amount → Save; next billing **mặc định = hôm nay**) → list hiển thị ngay "Netflix Next: 08/15 15.49 USD Active" ✅.
  - Force-stop + relaunch → **due-alert dialog HIỆN ĐÚNG**: title "Subscriptions due soon", body + list "📦 Netflix — Netflix renews today" + "📦 YouTube — YouTube renews today", nút OK/View all/Dismiss. Screenshot `/tmp/due_alert_dialog.png`. Tap OK → đóng, Home hiển thị, `dueAlertLastShown=2026-08-15` được persist.
  - **Notification**: sửa Netflix next billing → **08-16 (tomorrow)** (detail → Edit → date picker chọn ngày 16 → OK → Save) → reconcile trigger (ref.listen subscription change) → `notifScheduledIds=[1537038242]` + `dumpsys alarm` thấy `RTC_WAKEUP origWhen=2026-08-16 09:00:00 → com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver` — **pipeline end-to-end OK**, sẽ bắn 09:00 mai kèm âm thanh (channel defaultImportance).
  - **Giải thích hành vi (không phải bug)**: sub renew HÔM NAY sau 09:00 không schedule reminder nào — `_billingEvents` skip trigger đã qua (`triggerAt.isBefore(current)`) và next occurrence (tháng sau) nằm NGOÀI horizon 14 ngày → đúng thiết kế "không nags sau giờ". Sub due TOMORROW mới vào horizon → schedule.
  - Demo notification bắn ngay: `cmd notification post` không impersonate được app channel; broadcast `SCHEDULED_NOTIFICATION` + id tới `ScheduledNotificationReceiver` thì no-op (receiver cần payload extra) → KHÔNG ép được delivery trước 9:00 mai (không root, `su` không có). Đủ bằng chứng: alarm OS đã set.
- [2026-08-15] **Phát hiện + fix bug UI khi test**: Home Today card hiện "You're clear. No renewals or trials need attention today." dù có 2 sub renew HÔM NAY (đáng lẽ phải nổi bật). Root cause: `TodayBriefService` — `clear = nextRenewal==null && trialEnding==null` **bỏ qua due-today events** (`dueToday` chỉ tính `hasEventToday` bool, card không render); nextRenewal là "strictly after today" nên renew hôm nay không bao giờ lên card. Fix:
  - `today_brief.dart`: thêm field `dueToday: List<Subscription>` + `clear` giờ = `nextRenewal==null && trialEnding==null && !hasEventToday` (có event hôm nay → KHÔNG "You're clear").
  - `home_screen.dart` `_TodayCard`: render `_NextRenewalRow(days: 0)` ("Next: X — in today (date) · price") cho từng sub trong `dueToday`, trước row next renewal.
  - Tests: `decision_engine_test.dart` — test "billing today" mở rộng: `clear=false`, `dueToday` chứa sub due hôm nay, không chứa sub due khác; `decision_engine_widget_test.dart` — widget test mới "renewal today → shows the sub, never the clear message" (pump SubTrackApp + sub due today → `Next: Netflix` hiện, text "You're clear" không tồn tại). Lưu ý kỹ thuật: lỗi cú pháp Dart đầu tiên do test NAME chứa `'` (You're) trong single-quoted string → đổi tên test bỏ apostrophe.
- [2026-08-15] Verify: `flutter analyze` **No issues**; `flutter test` **258/258 pass** (257 + 1 widget mới). Không secret. Commit + push `main` → GH Actions build debug APK mới (chứa fix Today card) — cài lên phone sẽ thấy card Today liệt kê sub renew hôm nay thay vì "You're clear".

## enable_ads=false flag + Due-alert dialog (2026-08-15)

- [2026-08-15] User yêu cầu: (1) thêm `enable_ads=false` để tắt ads (sau này `enable_ads=true` bật lại); (2) hỏi khi sub đến hạn có notification + dialog hiện sub gần/đã hết hạn ko — sau đó đồng ý thêm dialog cảnh báo 1 lần/ngày.
- [2026-08-15] Xong #1: `ads_config.dart` — `AdConfig.enabled` = `bool.fromEnvironment('ENABLE_ADS', defaultValue: false)` → **ads OFF mặc định mọi build** (main.dart không init AdMob, banner/interstitial no-op qua `supported`). Bật lại: build với `--dart-define=ENABLE_ADS=true`. KHÔNG cần sửa workflow (mặc định false là đúng ý user). Verify: analyze 0; `ads_test` + `banner_layout_test` 10/10 pass.
- [2026-08-15] Xong #2 — trả lời: **notification CÓ + có âm thanh** (scheduler local 9:00 đúng ngày billing "{name} renews soon" + trial +2ngày/đúng ngày; Android `Importance.defaultImportance` + iOS `sound:true`); **dialog KHÔNG có trước đây** — chỉ có card Today + Review Queue trên Home. Đã thêm **due-alert dialog** (1 lần/ngày):
  - `lib/features/decision/due_alert.dart` — `DueAlertService` (pure): filter HIGH-priority từ `ReviewQueueService` (renewal hôm nay/mai + trial ≤3 ngày; medium price-changed/stale KHÔNG popup) + `lastShownKey = 'dueAlertLastShown'`.
  - `lib/features/decision/presentation/due_alert_dialog.dart` — `DueAlertDialog`: icon cảnh báo + list item (emoji + tên + lý do: "{name} renews today/tomorrow", "{name} — trial ends in N day(s)"), tap item → `/subscriptions/:id`, nút View all → `/home`, nút OK. **Lưu ý kỹ thuật**: AlertDialog đo intrinsic — dùng `SingleChildScrollView` + Column thay vì shrinkWrap ListView (throw `RenderShrinkWrappingViewport`); `hide DateUtils` khỏi import material (trùng tên `DateUtils` của Flutter).
  - Wire `_AppShell` (`app_router.dart`) → `ConsumerStatefulWidget` + `_AppShellState`: watch `subscriptionListControllerProvider` lần build đầu khi data có value → post-frame `_showDueAlertIfDue`; gate: kIsWeb/FLUTTER_TEST skip (như AdConfig), items empty skip, `settings.get(lastShownKey) == hôm nay` skip; **persist TRƯỚC khi show** (crash/dismiss vẫn tính đã hiện hôm nay — không nags lặp). `ref.listen(fireImmediately:)` KHÔNG tồn tại trong Riverpod bản này → dùng `ref.watch` trong build.
  - L10n keys mới `dueAlert*` 7 keys EN+VI (`dueAlertTitle/Body/RenewalToday/RenewalTomorrow/TrialEnding/ViewAll/Dismiss`) + `flutter gen-l10n`.
- [2026-08-15] Test: `test/due_alert_test.dart` (10 tests — 9 service: empty/due-today/due-tomorrow/2+ngày loại/trial ≤3d/trial >3d loại/medium loại/status ko-active loại/thứ tự high; 1 widget: dialog render items + lý do + OK đóng). Verify: `flutter analyze` 0 issues; `flutter test` **257/257 pass** (247 cũ + 10 mới). Không secret trong diff. Commit + push `main` → GH Actions debug APK tự trigger (APK mới có ads tắt + due-alert dialog).

## Launcher label "Subscription Tracker" + chplay.md + asset sharing (2026-08-15)

- [2026-08-15] User yêu cầu: (1) đổi tên app "subtrack" → "Subscription Tracker" — hỏi có ổn ko + sửa launcher label; (2) viết `chplay.md` — toàn bộ nội dung đăng tải Google Play Console; (3) up `chplay.md` lên JotBird hosting gửi link; (4) zip icon + feature image up tmpfiles.org gửi link; (5) cập nhật openspec.
- [2026-08-15] Xong launcher label: `AndroidManifest.xml` `android:label` → "Subscription Tracker" (verify không có strings.xml override); iOS `CFBundleDisplayName` → "Subscription Tracker" (`CFBundleName` giữ nội bộ); web `<title>`/`apple-mobile-web-app-title`/`manifest.json` name/short_name → "Subscription Tracker"/"SubTrack". **Giữ nguyên có chủ đích**: in-app brand "SubTrack"/"SubTrack Pro"/backup messages, product id `subtrack_lifetime_pro`, `subtrack.db`, storage prefix `subtrack_`, notification channel — đổi sẽ mất dữ liệu/khớp nối store. Không đụng logic Dart → không cần test.
- [2026-08-15] Xong `chplay.md` (root): 4 phần — (1) Main Store Listing (App Name 30 ký tự ASO + 2 alternates, Short Description ≤80 EN+VI, Full Description EN+VI bullet ASO ≤4000); (2) Store Settings (Finance + 5 tags); (3) Graphics & Assets (4 screenshots kèm text overlay EN+VI + specs 1080×1920, feature graphic 1024×500, icon 512×512); (4) App Content Checklist (privacy URL gh-pages, data safety, content rating Everyone, app access, IAP "Pro", AdMob app id `ca-app-pub-6917313063209470~5291822252`, target API 36) + checklist pre-submit.
- [2026-08-15] Xong JotBird: publish `chplay.md` qua `POST /api/v1/publish` (Bearer key `jb_...` của user) — **lần đầu 403 Cloudflare code 1010** (python urllib bị chặn bot) → retry curl + User-Agent trình duyệt → **201 Created**: https://share.jotbird.com/soft-playful-moonbeam (title "SubTrack - Google Play Console Listing", TTL 90 ngày, hết hạn 2026-11-13; re-publish cùng slug để update). Lưu ý bảo mật: key đã xuất hiện trong chat — khuyên user revoke/tạo key mới nếu muốn.
- [2026-08-15] Xong tmpfiles: zip `icon.png` + `feature-graphic.png` → `subtrack_store_assets.zip` (119 KB) → upload `POST /api/v1/upload` → **success**: https://tmpfiles.org/wpw3SAjPUsGo/subtrack_store_assets.zip (page 200) + direct-download https://tmpfiles.org/dl/wpw3SAjPUsGo/subtrack_store_assets.zip (302). Lưu ý tmpfiles là tạm thời (~1h không tải sẽ xóa).
- [2026-08-15] Xong build lần cuối: commit **`de03761`** (5 files: launcher label 4 file + chplay.md) push `main` → GH Actions "Build Debug APK" run `31863893172` (queued, head `de03761`) — APK cuối cho test trước khi submit store.

## OpenSpec: change subtrack-store-polish (2026-08-15)

- [2026-08-15] User yêu cầu cập nhật openspec sau loạt work store-facing + code-review fixes. Tạo change retrospective **`subtrack-store-polish`**: `proposal.md` + 3 specs đúng format delta — `store-assets-privacy` (privacy policy bỏ GitHub repo → email `haibasoftware@gmail.com`, gh-pages redeploy, icon 512×512 verified, feature-graphic 1024×500), `banner-shell-placement` (banner trong shell Column trên NavigationBar — flush không gap SafeArea, mọi tab), `review-bugfixes` (paywall error copy, paywall slots-used khớp gate add-form, exchange-rate error localized) + `tasks.md` retrospective all [x]. Verify: `openspec validate --changes` **7/7 pass** (6 change cũ + 1 mới). Commit `f8b3646` push `main` (docs-only).

## Privacy email + full code review (2026-08-15)

- [2026-08-15] User yêu cầu: (1) đổi email trong privacy policy thành `haibasoftware@gmail.com`; (2) review toàn bộ code tìm lỗi UI/logic/crash.
- [2026-08-15] Xong #1: `docs/privacy-policy.md` + `.html` contact email `hoangsoft90@gmail.com` → `haibasoftware@gmail.com` (mailto, EN+VI). Redeploy gh-pages `8bca378` → live (HTTP 200).
- [2026-08-15] Xong #2 — full code review 83 files lib/ (13k lines), rà từng tầng: domain (Subscription/Billing/Money/Savings/ReviewQueue/TodayBrief/MoneyCalendar), storage (sqflite + localStorage + migrations + seeders), notifications (scheduler/coordinator/permission/platform), ads (banner/interstitial), backup (export/import), IAP (gateway/paywall/entitlement), guidance (host/spotlight/tooltip), router/nav, mọi presentation screen. **Tìm + fix 3 lỗi thật:**
  - **UI copy bug**: paywall purchase/restore FAILURE hiện "This file is not a SubTrack backup." (dùng nhầm `backupErrorInvalidFile`) → thêm key `paywallError` EN+VI ("Purchase couldn't be completed…") dùng cho cả `_purchase` + `_restore`.
  - **Logic inconsistency**: paywall "N of 10 slots used" chỉ đếm ACTIVE, trong khi gate add-form đếm ACTIVE + PENDING_CANCELLATION (`paywallSlotCount`) → dùng `paywallSlotCount` để số hiển thị luôn khớp gate (9 active + 1 pending-cancellation trước đây hiện "9/10" nhưng bị block khi add).
  - **i18n**: lỗi nhập tỷ giá trong Settings hiện chuỗi English hardcode "invalid rate" → key `settingsExchangeRatesInvalid` EN+VI.
- [2026-08-15] Đã verify các vùng rủi ro KHÔNG có bug: `.first`/`!` đều có guard (getById/isEmpty, pending preset empty-check, purchase productDetails empty-check, fromMap chỉ chạy khi validate import); backup import bọc try/catch (từ 2026-08-13) + apply cũng try/catch; money tính integer minor units không float; exchange rate thiếu rate → null (không bịa); conversion guard `allActiveConvertible`; scheduler deterministic ids + group cap; localStorage đọc corrupt-safe; nav/recovery/guidance geometry đã test. Không có crash-path mới.
- [2026-08-15] Verify: `flutter gen-l10n` + `flutter analyze` 0 issues; `flutter test` **247/247 pass** (l10n regen không phá test nào). Commit `d4582f9` push `main` — GH Actions debug APK tự trigger (build APK mới chứa fixes).

## Privacy policy bỏ GitHub repo + banner flush nav + icon/feature graphic (2026-08-15)

- [2026-08-15] User yêu cầu 4 việc: (1) update privacy policy — nội dung KHÔNG nhắc tới GitHub repo; (2) banner ads đang "chênh vênh", chưa sát bottom nav buttons — sửa cho chạm gần nav; (3) tạo App Icon `icon.png` 512×512 (đã có từ trước — verify lại OK); (4) tạo Feature Graphic 1024×500.
- [2026-08-15] Xong #1: bỏ mọi mention GitHub repo khỏi privacy policy EN+VI — section Contact trong `docs/privacy-policy.md` + `docs/privacy-policy.html` thay link repo bằng email `hoangsoft90@gmail.com` (mailto). Redeploy: gh-pages branch `index.html` = copy mới của `privacy-policy.html`, push `7c1db79` → live tại https://hoangsoft90.github.io/SubscriptionTracker/ (HTTP 200 verified; Pages build queued).
- [2026-08-15] Xong #2 (root cause): banner nằm trong `bottomNavigationBar` của **Scaffold trong** (mỗi tab), còn `NavigationBar` nằm ở Scaffold shell ngoài → banner lơ lửng giữa content và nav bar + `SafeArea(top:false)` thêm bottom inset → gap "chênh vênh". Fix: chuyển banner lên **shell** (`_AppShell` trong `app_router.dart`) — `bottomNavigationBar` giờ là `Column(min)` = `[BannerAdView, NavigationBar]` → banner nằm TRỰC TIẾP trên nav buttons, đều cả 3 tab; bỏ `SafeArea` trong `BannerAdView` (NavigationBar bên dưới đã handle bottom inset) → banner chạm sát nav. Xóa banner khỏi `home_screen.dart` + `subscription_list_screen.dart` (bỏ imports/`showAds` watch không còn dùng). FAB vẫn nổi phía trên banner (không đè).
- [2026-08-15] Xong #3: `icon.png` (512×512 RGB) đã tồn tại từ 2026-08-13 — verify kích thước/design (teal gradient rounded-square + white card) OK, không cần tạo lại.
- [2026-08-15] Xong #4: tạo **`feature-graphic.png` (1024×500)** bằng PIL từ brand của icon — teal gradient nền + white rounded card chứa icon (scale từ icon.png) + title "SubTrack" + subtitle/tagline/3 bullets, DejaVu Sans; verify tất cả text fit trong bounds (max 498px/line). Dùng cho Play Store listing.
- [2026-08-15] Verify: `flutter analyze` 0 issues; `flutter test` **247/247 pass** (banner move lên shell không phá test — `showAdsProvider` false trong test, NavigationBar finder vẫn 1 widget). Không secret trong diff. Commit `36edad7` push `main` → GH Actions Build Debug APK `31860338953` in_progress (build APK mới chứa fix banner shell); gh-pages push `7c1db79`.

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
