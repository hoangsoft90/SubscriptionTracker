## Why

After the store-listing polish (2026-08-15) the developer asked to re-enable **real ads** (`enable_ads=true`, `test_ads=false`) and verify them on a real phone, and later to produce a **signed release AAB** on GH Actions with the real keystore for Play Store submission. Both efforts surfaced real, non-obvious platform behavior that needed code/workflow fixes and is worth recording:

1. **AdMob refuses to serve real ads pre-publish** — debug builds of an unpublished app return `NO_FILL` (error code 3) by design (anti-fraud), regardless of correct app ID / ad unit IDs. The attempt to bypass via test-device registration failed because this dev phone's **advertising ID rotates continuously** (3 different test-device IDs in 16 hours: `C1D6...` → `9E19...` → `9552...`), so a hard-coded device ID is never matched.
2. **The first signed release AAB build failed** — `validateSigningRelease` could not find the keystore because `storeFile = file(...)` in the app module resolves relative to `android/app/`, while the keystore (local + CI decode) lives at `android/keystore/`.

## What Changes

- **Real ads confirmed on (default config)** — `AdConfig.enabled` defaults to `true` (`ENABLE_ADS`) and `AdConfig.testAds` defaults to `false` (`TEST_ADS`) → every build without a dart-define uses the REAL ad unit IDs (`ca-app-pub-6917313063209470...`). Debug APK builds are the exception: the debug workflow now passes `--dart-define=TEST_ADS=true` so the debug APK uses Google's sample ad IDs, which **always fill on any device** (no test-device registration needed) — the only reliable way to verify banner layout pre-publish. The release AAB workflow has no flag and keeps the real IDs.
- **Test-device registration documented as unreliable on this device** — `ads_config.dart` `testDeviceIds` carries the known IDs as a best-effort fallback, with comments explaining the advertising-ID rotation. Not relied upon as the mechanism to see ads.
- **`google-services.json` verified for `com.hoangsoft.subtrack`** — and clarified that it is Firebase config; AdMob reads the app ID from `AndroidManifest.xml` meta-data (`APPLICATION_ID`) and ad unit IDs from `ads_config.dart`, both verified correct.
- **Release AAB signing fixed** — `android/app/build.gradle.kts` now resolves `storeFile` via `rootProject.file(...)` so `storeFile=keystore/subtrack-release.jks` maps to `android/keystore/subtrack-release.jks`, matching local layout, `key.properties`, and the CI decode path. The signed release AAB workflow (`build-release-aab.yml`) decodes the keystore from `ANDROID_KEYSTORE_BASE64` (alias `upload`, passwords from secrets) and builds `flutter build appbundle --release`.
- **Keystore identity verified** — `android/keystore/subtrack-release.jks` (PKCS12), alias `upload`, store/key password `83793900`, SHA256 `B8:9E:20:44:3B:41:5C:4C:F5:A1:AA:57:F9:C2:8C:35:B9:B9:F0:6A:14:DE:2C:C5:1D:71:7D:EB:C5:A9:C0:15`, valid 2026-08-13 → 2053-12-29. The 4 signing secrets exist on the repo (`ANDROID_KEYSTORE_BASE64`, `ANDROID_STORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`).

## Capabilities

### New Capabilities

- `ads-real-ids-no-fill-strategy`: real ad IDs are the default; pre-publish real ads return NO_FILL by design; the debug workflow builds with sample ad IDs (always fill, any device) while release keeps real IDs; test-device registration is best-effort only because this dev phone's advertising ID rotates.
- `release-signing-keystore-path`: the release signing keystore path resolves against the Gradle root (`android/keystore/`), matching where the keystore lives locally and is decoded on CI, so `validateSigningRelease` succeeds.

### Modified Capabilities

- (none — `openspec/specs/` is empty in this repo; all delta specs live in change directories.)

## Impact

- **Code**: `lib/features/ads/ads_config.dart` (defaults + `testDeviceIds` comments), `lib/main.dart` (`Future<void> main()` + `updateRequestConfiguration` for test devices), `android/app/build.gradle.kts` (`storeFile = rootProject.file(...)`).
- **CI**: `.github/workflows/build-debug-apk.yml` (`--dart-define=TEST_ADS=true`), `.github/workflows/build-release-aab.yml` (unchanged — no flag, real IDs, keystore from secrets).
- **Schema**: none.
- **Dependencies**: none.
- **Tests**: `flutter analyze` 0 issues; `ads_test` + `banner_layout_test` **10/10 pass** on each ads-related change. `flutter test` full suite unaffected.
- **External**: debug APK builds triggered per push; signed release AAB build run `31923242287` (commit `0272a90`) re-triggered after the signing fix — artifact `subtrack-release-aab` for Play Store upload. Real ads fill only after store approval + ad-unit activation (hours–days).
