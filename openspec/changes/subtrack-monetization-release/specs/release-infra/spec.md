## Purpose

Platform and release configuration to make SubTrack publishable to Google Play and the App Store: a unique package id, the required target SDK, split GitHub Actions workflows (debug APK without keystore; signed AAB with keystore from secrets), and a hosted privacy policy.

## ADDED Requirements

### Requirement: The app package is `com.hoangsoft.subtrack`
The system SHALL use `com.hoangsoft.subtrack` as the Android `namespace` and `applicationId` (was `com.subguard.app` — already taken), the Kotlin `MainActivity` SHALL live at `com/hoangsoft/subtrack/` with a matching package declaration, the iOS `PRODUCT_BUNDLE_IDENTIFIER` SHALL be `com.hoangsoft.subtrack` (app) and `com.hoangsoft.subtrack.RunnerTests` (tests), and `google-services.json` package_name SHALL match. AdMob comments SHALL note that the real ad-unit IDs were registered for the old package and must be re-registered for the new one before real ads go live.

#### Scenario: Android builds under the new package
- **WHEN** a debug or release Android build runs
- **THEN** the produced application id is `com.hoangsoft.subtrack` and `MainActivity` resolves

#### Scenario: iOS uses the matching bundle id
- **WHEN** the iOS project builds
- **THEN** the bundle identifier is `com.hoangsoft.subtrack`

### Requirement: targetSdk is pinned to 36
The system SHALL pin `targetSdk = 36` in `android/app/build.gradle.kts` (Google Play requires API 36 from 2026-08-31), independent of the Flutter default.

#### Scenario: Release builds target API 36
- **WHEN** any release build runs
- **THEN** the merged manifest declares `targetSdkVersion 36`

### Requirement: Debug APK and signed AAB are separate workflows
The system SHALL build ONLY the debug APK in `build-debug-apk.yml` (no keystore, triggers on push to `main` + manual dispatch, uploads `subtrack-debug-apk`). The system SHALL build ONLY the signed release AAB in `build-release-aab.yml` (manual dispatch only): decode the `ANDROID_KEYSTORE_BASE64` secret into `android/keystore/subtrack-release.jks`, write `android/key.properties` from `ANDROID_STORE_PASSWORD` / `ANDROID_KEY_ALIAS` / `ANDROID_KEY_PASSWORD`, and fail with a clear error if secrets are missing. The old combined workflow (`build-apk.yml`) SHALL be removed.

#### Scenario: Every push yields a fresh debug APK
- **WHEN** code is pushed to `main`
- **THEN** the debug APK workflow runs and uploads `subtrack-debug-apk` with no keystore required

#### Scenario: Release workflow without secrets fails clearly
- **WHEN** the release AAB workflow runs without `ANDROID_KEYSTORE_BASE64`
- **THEN** it fails with an actionable error explaining how to set the secrets

#### Scenario: Release workflow with secrets produces a signed AAB
- **WHEN** the release AAB workflow runs with all four secrets
- **THEN** a Play-Store-submittable AAB signed with `subtrack-release.jks` is uploaded

### Requirement: A privacy policy is hosted and referenced
The system SHALL publish a bilingual (EN/VI) privacy policy at the repository's GitHub Pages URL and use that URL in the store listings.

#### Scenario: Privacy policy is reachable
- **WHEN** the store listing links to the privacy policy
- **THEN** the gh-pages URL serves the bilingual policy document
