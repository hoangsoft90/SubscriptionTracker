## Purpose

Makes the whole app available in English and Vietnamese with a runtime language switch, while guaranteeing that user-entered data (subscription names, notes, custom categories) is never translated or altered by the language change.

## ADDED Requirements

### Requirement: EN and VI locales

The system SHALL ship English and Vietnamese localizations covering all UI strings (onboarding, tabs, screens, statuses, preset display names, paywall, settings), switchable at runtime from Settings.

#### Scenario: Switch EN → VI

- **WHEN** the user changes the app language from English to Vietnamese
- **THEN** all UI strings render in Vietnamese immediately

#### Scenario: Default follows device

- **WHEN** the app launches on a `vi_VN` device
- **THEN** the UI defaults to Vietnamese (unless the user previously chose otherwise)

### Requirement: Preset names resolved by key

Preset display names SHALL be stored as localization keys and resolved per locale; they are not hard-coded strings.

#### Scenario: Preset name localized

- **WHEN** the locale is Vietnamese
- **THEN** preset display names (resolved from keys) render in Vietnamese

### Requirement: User data never localized

Subscription names, notes, custom category names and any other user-entered text SHALL be stored and displayed exactly as entered, unchanged by a language switch.

#### Scenario: Custom name survives language switch

- **WHEN** a user named a subscription "My Gym" in English and switches to Vietnamese
- **THEN** the name still displays "My Gym" (never translated to Vietnamese)

### Requirement: Locale-aware formatting

Amounts and dates SHALL be formatted with the active locale using `intl` (e.g. currency symbols/position, date order) while the underlying stored values stay unchanged.

#### Scenario: Currency format follows locale

- **WHEN** the locale is `vi_VN` and an amount is formatted
- **THEN** the formatted output follows Vietnamese number/currency conventions without altering the stored minor units
