## Purpose

Re-enabling real ads (`enable_ads=true`, `test_ads=false`) and trying to verify them on a real phone (2026-08-15 → 2026-08-16) surfaced two AdMob platform behaviors that shaped the final ads configuration: real ad units return `NO_FILL` pre-publish by design, and this dev phone's advertising ID rotates so test-device registration cannot be relied on. The resulting strategy keeps real IDs for release builds while making the debug APK use Google's sample ad IDs (guaranteed fill).

## ADDED Requirements

### Requirement: Real ad IDs are the default for all builds
`AdConfig.enabled` SHALL default to `true` (`ENABLE_ADS`) and `AdConfig.testAds` SHALL default to `false` (`TEST_ADS`) so every build without a dart-define uses the real AdMob app ID + ad unit IDs (`ca-app-pub-6917313063209470...`).

#### Scenario: Release AAB uses real ads
- **WHEN** `flutter build appbundle --release` runs without `--dart-define=TEST_ADS`
- **THEN** `AdConfig.testAds` is `false` and the banner/interstitial use the real ad unit IDs, ready for the published store app

#### Scenario: Real ads do not fill pre-publish
- **WHEN** the app is not yet published (or its ad units are not yet activated) and a real ad unit is requested
- **THEN** the SDK logs `Ad failed to load : 3` (NO_FILL) — expected AdMob anti-fraud behavior, not a code bug

### Requirement: Debug APK builds use sample ad IDs so ads always display
The debug APK workflow SHALL pass `--dart-define=TEST_ADS=true`, resolving ad units to Google's sample IDs which fill on any device, so the banner layout can be verified on a real phone pre-publish without test-device registration.

#### Scenario: Debug APK shows a banner
- **WHEN** a debug APK built from the debug workflow is installed on a phone with ads supported
- **THEN** the banner loads (sample ad unit) and displays — no NO_FILL, no test-device registration required

#### Scenario: Release build is unaffected by the debug flag
- **WHEN** the release AAB workflow builds
- **THEN** no `TEST_ADS` dart-define is passed and the real ad IDs are used

### Requirement: Test-device registration is best-effort only
`AdConfig.testDeviceIds` MAY list known device IDs, but the ads strategy SHALL NOT depend on test-device registration because the dev phone's advertising ID rotates (3 different IDs in 16 hours: `C1D6...` → `9E19...` → `9552...`), which changes the computed test-device ID. `main.dart` SHALL still call `updateRequestConfiguration` with the listed IDs when ads are supported.

#### Scenario: Device advertising ID rotates
- **WHEN** the AdMob SDK initializes and the device is not recognized as a registered test device
- **THEN** it prints `Use RequestConfiguration.Builder().setTestDeviceIds(...) to get test ads on this device` with the current ID, and real units still return NO_FILL — the debug workflow's sample-ID build remains the reliable verification path

### Requirement: google-services.json is not the AdMob configuration
The `google-services.json` for `com.hoangsoft.subtrack` (project `subscriptiontracker-94c6d`) SHALL be verified correct, but the AdMob configuration SHALL be sourced from the `APPLICATION_ID` meta-data in `AndroidManifest.xml` and the ad unit IDs in `ads_config.dart` — google-services.json is Firebase config and does not control ad serving.

#### Scenario: Verify AdMob app ID source
- **WHEN** checking why ads do not fill
- **THEN** confirm the manifest meta-data `com.google.android.gms.ads.APPLICATION_ID` = `ca-app-pub-6917313063209470~5291822252` and the ad unit IDs in `ads_config.dart`, not google-services.json
