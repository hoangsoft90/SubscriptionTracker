## Purpose

The first signed release AAB build on GH Actions (2026-08-16) failed at `validateSigningRelease`: `Keystore file '/home/runner/work/SubscriptionTracker/SubscriptionTracker/android/app/keystore/subtrack-release.jks' not found for signing config 'release'`. `android/app/build.gradle.kts` resolved `storeFile` with `file(...)` — relative to the **app module** (`android/app/`), while the keystore is decoded on CI (and kept locally) at `android/keystore/`.

## ADDED Requirements

### Requirement: Release signing resolves the keystore against the Gradle root
The release `signingConfig` SHALL resolve `storeFile` with `rootProject.file(...)` so `storeFile=keystore/subtrack-release.jks` (from `android/key.properties`) maps to `android/keystore/subtrack-release.jks` — the location where the keystore lives locally and where the CI workflow decodes it from `ANDROID_KEYSTORE_BASE64`.

#### Scenario: Signed release AAB build succeeds on CI
- **WHEN** `build-release-aab.yml` decodes the keystore to `android/keystore/subtrack-release.jks`, writes `android/key.properties` (alias `upload`, store/key passwords from secrets), and runs `flutter build appbundle --release`
- **THEN** `validateSigningRelease` finds the keystore and the AAB is signed with the real keystore (no fallback to the debug key)

#### Scenario: Keystore location is consistent everywhere
- **WHEN** checking the keystore path in local `key.properties`, the `build.gradle.kts` comment, and the workflow decode step
- **THEN** all three refer to `android/keystore/subtrack-release.jks` (Gradle-root relative)

### Requirement: Keystore identity is known and recorded
The release keystore SHALL be `android/keystore/subtrack-release.jks` (PKCS12, 2728 bytes), alias `upload`, store/key password `83793900`, SHA256 `B8:9E:20:44:3B:41:5C:4C:F5:A1:AA:57:F9:C2:8C:35:B9:B9:F0:6A:14:DE:2C:C5:1D:71:7D:EB:C5:A9:C0:15`, valid 2026-08-13 → 2053-12-29. The keystore file and `key.properties` SHALL stay gitignored; CI consumes them via the four GitHub Secrets (`ANDROID_KEYSTORE_BASE64`, `ANDROID_STORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`).

#### Scenario: Keystore details for Play Console
- **WHEN** uploading the release AAB to Play Console
- **THEN** the signing fingerprint matches `B8:9E:20:44:...` and the alias/passwords are those above — do not change secrets or keystore without re-registering Play App Signing
