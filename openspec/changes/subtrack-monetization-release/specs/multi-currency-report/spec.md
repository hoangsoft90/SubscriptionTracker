## Purpose

Home reports money in the user's primary currency even when subscriptions are stored in several currencies, without ever inventing a rate: a USD-pivot conversion core, live rates with a manual offline fallback, a converted headline plus a per-currency breakdown, and currency codes on list amounts.

## ADDED Requirements

### Requirement: Conversion goes through a USD pivot with exact integer minor math
The system SHALL express exchange rates as units of each currency per 1 USD and convert any currency to any other through that pivot. `convertMinorToPrimary` SHALL convert integer minor units exactly (via `10^decimals`) and SHALL return `null` when either rate is missing or non-positive — the caller then falls back to per-currency display instead of inventing a rate. Conversion is for REPORTING ONLY: stored amounts keep their own currency and are never mutated.

#### Scenario: Amount converts through the pivot
- **WHEN** a VND amount is converted to USD with rate `1 USD = 25400 VND`
- **THEN** the result equals the exact USD minor units (rounded at the target decimals)

#### Scenario: Missing rate yields null, never a made-up number
- **WHEN** a currency has no rate in the table
- **THEN** conversion returns null and the amount stays visible in its own currency in the breakdown

### Requirement: Live rates with a manual offline fallback
The system SHALL try a free live API (`open.er-api.com/v6/latest/USD`, no key, 6s timeout) first and SHALL fall back to manual rates editable in Settings (persisted as JSON in `app_settings` under `exchangeRates`), seeded with defaults for USD/EUR/GBP/VND/JPY/KRW. Widget tests SHALL never hit the network.

#### Scenario: Online uses live rates
- **WHEN** the device is online and the API responds
- **THEN** the live rates map is used

#### Scenario: Offline uses the manual fallback
- **WHEN** the live fetch fails or times out
- **THEN** the manual rates (user-edited or seeded defaults) are used

#### Scenario: Tests never hit the network
- **WHEN** running under `FLUTTER_TEST` or on web
- **THEN** no live fetch is attempted (`canFetchLive` false)

### Requirement: Home headline converts only when every active currency has a rate
The system SHALL show the converted Monthly/Yearly headline in the primary currency with a "≈ converted" note only when EVERY active subscription's currency has a rate; otherwise it SHALL fall back to the primary-only total (never a silently truncated conversion). Savings (projected/realized) SHALL convert the same way, and a per-currency breakdown SHALL keep every currency visible in either case.

#### Scenario: All currencies convertible → converted headline
- **WHEN** every active subscription has a rate and the primary currency is USD
- **THEN** the headline shows the sum of all subscriptions converted to USD, with the "≈ converted" note and a per-currency breakdown

#### Scenario: A currency lacks a rate → primary-only headline
- **WHEN** at least one active subscription's currency has no rate
- **THEN** the headline shows the primary-currency-only total and the breakdown still lists the unknown currency exactly

### Requirement: List amounts show their currency code
The system SHALL render subscription list amounts with their ISO currency code (e.g. "14.99 USD", "99,999 VND") — never a bare number.

#### Scenario: Mixed-currency list shows codes
- **WHEN** a list contains USD and VND subscriptions
- **THEN** each amount renders with its ISO code (regression: `subscription_display_test.dart`)
