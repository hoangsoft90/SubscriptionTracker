> Retrospective change: the implementation below is already shipped (2026-08-15 → 2026-08-16). Tasks are recorded as completed against the live codebase; verification numbers reflect the final state.

## 1. Real ads on — config + verification on device

- [x] 1.1 `lib/features/ads/ads_config.dart`: `AdConfig.enabled` default `false → true` (`ENABLE_ADS`); `AdConfig.testAds` default `true → false` (`TEST_ADS`) — real ad unit IDs (`ca-app-pub-6917313063209470...`) used by default. `test/ads_test.dart` updated to assert the new defaults. Commit `ee4b96d`. Verify: `flutter analyze` 0 issues; `ads_test` + `banner_layout_test` 10/10 pass.
- [x] 1.2 Device test (Pixel 3a, real phone, APK `ee4b96d` then `43a863c`): logcat consistently showed `Ad failed to load : 3` (NO_FILL) while `MAIN: ads supported, initializing` + `DynamiteModule` selected — SDK initialized fine, network OK, app ID valid; Google simply returned no ad.
- [x] 1.3 Corrected earlier hypothesis: the user did NOT register a package when creating the AdMob app (app unpublished), so "package mismatch com.subguard.app" was not the cause.
- [x] 1.4 Root cause: real ad units return NO_FILL on unpublished apps by design (AdMob anti-fraud; units need store presence + activation + traffic).
- [x] 1.5 First workaround — test-device registration: `lib/features/ads/ads_config.dart` `testDeviceIds = ['C1D6E94F7B5739F934186905CC65759A']` + `lib/main.dart` became `Future<void> main() async` with `MobileAds.instance.initialize()` + `updateRequestConfiguration(...)` (only when ads supported). Commit `43a863c`.
- [x] 1.6 Second workaround attempt — the advertising ID rotated: SDK suggested `9E19A0CAF5DAFB7BD0E3B151B5495FD7` at 21:48 (vs `C1D6...` at 17:21) → added both IDs to `testDeviceIds`. Commit `54b221a`.
- [x] 1.7 Final discovery (logcat 09:25, APK `54b221a`): the SDK suggested a **third** ID `9552D9D634D61C1B28761AD8007CAF65` — the device's advertising ID rotates continuously (3 IDs in 16h) → test-device registration is unreliable on this phone. Verified `google-services.json` = `com.hoangsoft.subtrack` (correct, but Firebase-only; AdMob reads manifest `APPLICATION_ID` + `ads_config.dart` IDs — both verified real/correct).
- [x] 1.8 Chosen strategy — debug workflow builds with sample IDs: `.github/workflows/build-debug-apk.yml` → `flutter build apk --debug --dart-define=TEST_ADS=true` (+ explanatory comment). Debug APK now always displays test ads (sample units fill on any device). Release AAB workflow has no flag → real IDs. Commit `eeeb923`.

## 2. Signed release AAB — keystore path fix

- [x] 2.1 Triggered `build-release-aab.yml` (workflow_dispatch, `eeeb923`) — first signed build with the real keystore. **Failed**: `Execution failed for task ':app:validateSigningRelease'. Keystore file '.../android/app/keystore/subtrack-release.jks' not found for signing config 'release'.`
- [x] 2.2 Root cause: `android/app/build.gradle.kts` `storeFile = file(keystoreProperties["storeFile"] as String)` resolves relative to the **app module** (`android/app/keystore/`); the keystore is decoded on CI (and kept locally) at `android/keystore/`. `key.properties` itself is read via `rootProject.file("key.properties")` — only `storeFile` was module-relative.
- [x] 2.3 Fix: `storeFile = rootProject.file(keystoreProperties["storeFile"] as String)` → `storeFile=keystore/subtrack-release.jks` maps to `android/keystore/subtrack-release.jks`, consistent with local layout, the in-file comment, `key.properties`, and the workflow decode step. Commit `0272a90`.
- [x] 2.4 Verified keystore identity: `android/keystore/subtrack-release.jks` (PKCS12, 2728 B), alias `upload`, store/key password `83793900`, SHA256 `B8:9E:20:44:3B:41:5C:4C:F5:A1:AA:57:F9:C2:8C:35:B9:B9:F0:6A:14:DE:2C:C5:1D:71:7D:EB:C5:A9:C0:15`, valid 2026-08-13 → 2053-12-29. Confirmed 4 secrets exist on the repo (`ANDROID_KEYSTORE_BASE64`, `ANDROID_STORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`).
- [x] 2.5 Re-triggered release AAB workflow for `0272a90` — run `31923242287` (in_progress at time of writing); debug APK run `31923240186` also queued from the push.

## 3. Verification

- [x] 3.1 `flutter analyze` — **No issues found** on every ads/config change (1.1, 1.5, 1.6, 1.8)
- [x] 3.2 `flutter test test/ads_test.dart test/banner_layout_test.dart` — **10/10 pass** on every ads change
- [x] 3.3 No secrets in any diff before commit (grep for ghp_/jb_/API_KEY/PASSWORD/83793900 — clean; keystore + `key.properties` remain gitignored)
- [x] 3.4 Commits pushed to `main`: `ee4b96d` (real ads defaults), `43a863c` (test-device registration), `54b221a` (second test-device ID), `eeeb923` (TEST_ADS=true debug workflow), `0272a90` (keystore path fix)
- [x] 3.5 `openspec validate --changes` — this change + prior changes pass
- [x] 3.6 Updated `.project/working.md` (sections: "Bật lại ads thật", "Test device registration — ads vẫn NO_FILL", "Test device ID đã đổi", "TEST_ADS=true cho debug workflow", "Fix release AAB signing") per project conventions
