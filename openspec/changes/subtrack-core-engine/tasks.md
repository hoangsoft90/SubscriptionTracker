## 1. Project scaffold

- [x] 1.1 Run `flutter create` for app (org e.g. `dev.subtrack`) with brand name SubTrack; add `.gitignore`/analysis options
- [x] 1.2 Add dependencies: `sqflite`, `sqflite_common_ffi` (dev/test), `uuid`, `intl`, and dev deps `flutter_lints`
- [x] 1.3 Verify `flutter analyze` passes on empty scaffold

## 2. Money core

- [x] 2.1 Implement `Money` class (`amountMinor` int, `currency`, `currencyDecimals` map, `parse()`, `format()` stub using intl)
- [x] 2.2 Implement integer-safe helpers: `add` (currency-checked), per-currency grouping, sum-by-currency
- [x] 2.3 Unit tests: parse decimal/zero-decimal currencies, format 2/0 decimals, integer sums without drift, mixed-currency rejection, grouping
- [x] 2.4 Run `flutter test test/money_test.dart` — all green

## 3. Calendar & BillingCalculator

- [x] 3.1 Implement `DateUtils` (local-midnight normalization, `YYYY-MM-DD` parse/format, addMonths clamping)
- [x] 3.2 Implement `BillingCycle` enum (WEEKLY/MONTHLY/QUARTERLY/YEARLY/CUSTOM) and `SubscriptionStatus` enum (ACTIVE/CANCELLED/ARCHIVED)
- [x] 3.3 Implement `BillingCalculator.nextBillingDate` with anchor-day preservation and month-end clamping; CUSTOM = start + n×interval; WEEKLY ignores anchor
- [x] 3.4 Implement projection helpers (monthly/yearly/5-year) on int minor units
- [x] 3.5 Unit tests: Jan 31→Feb 28→Mar 31, leap year 2028-02-29, Dec 31→Jan, custom 45-day, weekly ignores anchor, clamp-restore (Mar 28 is wrong, Mar 31 correct)
- [x] 3.6 Run `flutter test test/billing_calculator_test.dart` — all green

## 4. Data storage

- [x] 4.1 Implement `AppDatabase` (open, `PRAGMA foreign_keys = ON`, version from `PRAGMA user_version`)
- [x] 4.2 Implement `DatabaseMigrationRunner` with v1 migration = full locked schema (§6): categories, subscriptions (all columns + 3 indexes), app_settings
- [x] 4.3 Implement `Subscription`/`Category` models (`fromMap`/`toMap`, dates as `YYYY-MM-DD`)
- [x] 4.4 Implement abstract repositories + sqflite implementations: `SubscriptionRepository` (insert/update/delete/getAll/getById), `CategoryRepository`, `SettingsRepository`
- [x] 4.5 Implement idempotent seed of 11 default categories + default `primaryCurrency` setting
- [x] 4.6 Unit tests (sqflite_common_ffi in-memory): CRUD round-trip incl. date preservation, FK enforcement, seed idempotency, migration 1→2 forward without data loss, no destructive re-runs
- [x] 4.7 Run full `flutter test` — all green

## 5. Verification

- [x] 5.1 Run `flutter analyze` — no issues
- [x] 5.2 Run `flutter test` — full suite green (Money, BillingCalculator, repositories, migrations)
- [x] 5.3 Confirm no analytics/crash SDK dependency is present in `pubspec.yaml`
