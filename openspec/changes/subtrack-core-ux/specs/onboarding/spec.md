## Purpose

Walks a new user through three quick steps — the privacy promise, primary-currency selection, and the preset catalog — so they reach a useful state in under 25 seconds without creating an account.

## ADDED Requirements

### Requirement: Privacy Promise step first

On first launch, before any data entry, the system SHALL show a privacy screen stating: "Subscription data is stored locally on your device. The app does not require a backend or account." and SHALL NOT request notification permission, contacts, or any other permission on this screen.

#### Scenario: First launch shows privacy promise

- **WHEN** a user opens the app for the first time
- **THEN** the privacy promise screen is shown and no system permissions are requested

### Requirement: Primary currency default from device locale

The system SHALL default the primary currency from the device locale (e.g. `vi_VN` → VND), falling back to USD when the locale's currency cannot be determined, and SHALL let the user change it before completing onboarding.

#### Scenario: VN locale defaults to VND

- **WHEN** a user with locale `vi_VN` starts onboarding
- **THEN** the primary currency is preselected as VND and the user can change it

#### Scenario: Unknown locale falls back to USD

- **WHEN** a user's locale has no determinable currency
- **THEN** the primary currency is preselected as USD

### Requirement: Preset catalog offered on onboarding

The system SHALL offer preset subscription packs on onboarding — at least a global pack and a VN pack — where presets carry a localized display name key, category, generic icon, optional validated cancellation URL, and an optional trial-duration suggestion labelled "Suggested, please verify". Presets SHALL NOT hard-code prices or billing cycles.

#### Scenario: VN pack shows VN-relevant presets

- **WHEN** a user browses the preset catalog during onboarding
- **THEN** they can switch between global and VN packs, and picking a preset pre-fills the add form without prices

### Requirement: Onboarding completion gates the app

The system SHALL mark onboarding complete only after the user advances through the currency step and the final preset step (either "Skip, start empty" or "Start tracking"), and SHALL not show onboarding again on subsequent launches.

#### Scenario: Completed onboarding is skipped next launch

- **WHEN** a user has completed onboarding and relaunches the app
- **THEN** the app opens directly to the Home tab without showing onboarding

### Requirement: Primary currency is changeable later

The system SHALL allow the primary currency to be changed any time in Settings (More tab), without converting historical amounts — existing amounts keep their own currency and the dashboard groups by currency.

#### Scenario: Currency changed in settings

- **WHEN** a user changes the primary currency in Settings
- **THEN** existing subscription amounts are unchanged and the dashboard regroups totals by the new primary currency
