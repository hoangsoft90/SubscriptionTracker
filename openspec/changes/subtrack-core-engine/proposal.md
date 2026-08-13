## Why

SubTrack (subscription tracker, privacy-focused) is a greenfield Flutter app. M0 lays the foundation every later milestone depends on: exact money handling (never `double`), a calendar-correct billing engine, and a versioned SQLite storage layer. Without this milestone, M1 (UI) and M2 (notifications/backup/IAP) would be built on unverifiable arithmetic and unmigratable data — the exact failure modes the locked execution spec (`.plan/plan1_final_1.md`) calls out as red risks.

## What Changes

- Introduce `Money` value type storing `amountMinor` (int) + `currency` (ISO 4217) with per-currency decimals map — no floating-point anywhere in calculations.
- Introduce `BillingCalculator` implementing the "same day if possible, else last day of month" policy with `billingAnchorDay` for MONTHLY/QUARTERLY/YEARLY and `startDate + n × customIntervalDays` for CUSTOM cycles.
- Introduce SQLite schema (categories, subscriptions, app_settings) with `PRAGMA user_version` migration scaffold usable from v1.
- Introduce abstract Repository layer over sqflite for categories/subscriptions/settings, with unit tests for all of the above.
- App brand/name: **SubTrack**. No analytics/crash SDKs are added (privacy constraint).

## Capabilities

### New Capabilities

- `money`: Money value type, currency decimals, formatting-safe arithmetic on integer minor units.
- `billing-engine`: Calendar-date billing calculations (anchor day, month-end clamping, custom intervals) — the invariant-tested core of the app.
- `data-storage`: SQLite schema, `PRAGMA user_version` migrations, and the Repository layer exposing typed CRUD.

### Modified Capabilities

- (none — greenfield project, no existing specs)

## Impact

- **Code**: new `lib/` modules (domain models, repositories, calculators); no existing code touched.
- **Dependencies**: `flutter`, `sqflite`, `uuid`, `intl` (used later for formatting; `Money` only needs it at UI layer). Explicitly **no** analytics/crash SDKs.
- **Tests**: new unit test suites for Money, BillingCalculator (calendar/leap-year/end-of-month/custom/timezone-independent cases), and repository CRUD.
- **Schema**: initial `PRAGMA user_version = 1`; migration runner designed so future versions (M2 backup import, later P1 features) add columns without refactor.
