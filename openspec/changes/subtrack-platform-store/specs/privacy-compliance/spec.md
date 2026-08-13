## Purpose

Guarantees the app's privacy promises are real and verifiable: zero outbound network traffic, no analytics or tracking SDKs, and store privacy disclosures that match the UI exactly.

> **AMENDED 2026-08-09 (user-approved override):** Google AdMob
> (`google_mobile_ads`) is now the ONLY permitted third-party network SDK. It
> serves **non-personalized** banner + rare interstitial ads on the **free tier
> only** (`npa=1` requests, no ATT prompt, no IDFA usage); Lifetime Pro removes
> all ads. All requirements below are amended accordingly: "ads" is no longer a
> forbidden category, the forbidden-SDK list drops "ad SDK", the app copy and
> store disclosures disclose AdMob, and the zero-outbound rule now excludes the
> AdMob SDK's ad-serving traffic (alongside the store SDK). See
> `.project/working.md` + `docs/privacy-labels.md`.

## ADDED Requirements

### Requirement: No outbound network requests from app code (amended)

The app's own code SHALL make zero outbound network requests during normal operation — no analytics, telemetry, or app-backend calls. The only network traffic in the app SHALL be: (a) the platform store SDK communication used by IAP purchase/restore (StoreKit 2 / Play Billing), and (b) the Google AdMob SDK's ad-serving traffic on the free tier (banner + rare interstitial, non-personalized). Both are user-initiated or SDK-internal and excluded from the app's own outbound-request count. Ads SHALL never appear for Pro users, on the paywall screen, or on the onboarding Privacy Promise step.

#### Scenario: Fully functional without network

- **WHEN** network access is disabled
- **THEN** all core flows work — browse, add, edit, dashboard, search, backup export/import, notifications — and the app's own code performs no network requests (network monitor shows 0 app-initiated outbound requests)

#### Scenario: Store SDK is the only expected network use

- **WHEN** a user purchases or restores Pro
- **THEN** the only network activity is the platform store SDK's purchase/restore verification, and no other network use occurs

#### Scenario: No analytics SDK in the build

- **WHEN** the release build is inspected
- **THEN** no Firebase Analytics, Crashlytics, Sentry, PostHog, Amplitude, Mixpanel, or RECEIVE_SMS permission is present; the only third-party SDK is Google AdMob (google_mobile_ads), intentional per the 2026-08-09 amendment

### Requirement: Honest privacy copy (amended)

Marketing/UI copy SHALL disclose the AdMob integration and SHALL NOT claim absolute statements such as "data can never leave your device". Canonical lines (EN/VI in `app_en.arb`/`app_vi.arb`):
- "No in-app analytics or tracking SDK."
- "Non-personalized ads are served by Google AdMob on the free plan — upgrade to Pro to remove them."
- "Subscription data is stored locally on your device. The app does not require a backend or account."
The onboarding Privacy Promise keeps the locked storage wording; the About line discloses ads.

#### Scenario: Copy avoids overclaim

- **WHEN** privacy statements are reviewed
- **THEN** they match the locked wording and do not claim absolute impossibility of data leaving the device

### Requirement: Store disclosures match UI (amended)

Apple Privacy Nutrition Label and Google Play Data Safety answers SHALL match the actual app behavior and UI claims. With AdMob present (non-personalized, free tier only), disclosures SHALL declare the advertising identifier / ads as the one data item the ad SDK uses, and SHALL keep "no analytics/tracking SDK" claims limited to the app's own code. No SMS/contacts/location permissions.

#### Scenario: Data Safety reflects behavior

- **WHEN** the Google Play Data Safety form is prepared
- **THEN** it declares no data collection, consistent with the app's zero-network behavior

### Requirement: Runtime permissions minimal

The app SHALL request only the permissions it functionally needs (notification permission after the first subscription, per the notifications capability); it SHALL NOT request SMS, contacts, location or storage permissions.

#### Scenario: Permission list is minimal

- **WHEN** the app's requested permissions are enumerated
- **THEN** only notification-related permissions are present, and no SMS/contacts/location/storage permission is requested

### Requirement: Crash reporting default

If crash reporting is ever needed, the system SHALL rely on the platform's built-in crash/network reporting before adding any third-party SDK; no third-party crash SDK SHALL be added in MVP.

#### Scenario: No crash SDK dependency

- **WHEN** the dependency graph is inspected
- **THEN** no third-party crash-reporting SDK appears in MVP dependencies
