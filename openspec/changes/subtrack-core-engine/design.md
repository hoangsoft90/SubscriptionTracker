## Context

Greenfield Flutter app (brand **SubTrack**). The locked execution spec (see `.plan/plan1_final_1.md` — "Why" in proposal.md) mandates integer money, calendar-date billing, and a versioned SQLite scaffold. There is no existing code; M0 defines the domain core and persistence that M1 (UI) and M2 (notifications/backup/IAP) build on.

## Goals / Non-Goals

**Goals:**
- Exact money arithmetic (int minor units, per-currency decimals).
- Deterministic, timezone-independent billing-date calculation with anchor-day preservation.
- Migratable SQLite schema (`PRAGMA user_version`) + typed repository layer.
- 100% unit test coverage of Money, BillingCalculator and repository CRUD/migration behavior.

**Non-Goals:**
- No UI, no routing, no state management wiring yet (M1).
- No notifications/backup/IAP (M2).
- No multi-currency conversion or exchange rates (not in MVP).
- No analytics/crash SDKs of any kind (hard privacy constraint).

## Decisions

### D1: Money as int minor units + currency (not double, not decimal package)
`Money { int amountMinor; String currency; }` with `currencyDecimals = {USD:2, EUR:2, GBP:2, VND:0, JPY:0, KRW:0}`. Parsing/formatting lives in this type; arithmetic is plain int.
- **Alternatives considered:** `double` (rejected — §2.1 of the spec; floating drift on sums); `decimal` package (rejected — extra dependency, no need since per-currency decimals are fixed at 0 or 2 in the supported set; keep scope minimal).
- **Rationale:** matches the locked spec exactly; int addition is exact; formatting only happens at the UI layer via `intl`.

### D2: BillingCalculator as pure function over calendar dates
`DateTime nextBillingDate({required DateTime current, required BillingCycle cycle, int? customIntervalDays, int billingAnchorDay})` operating on local-midnight dates. Policy: "same day if possible, else last day of month"; anchor day stored/restored across clamps. CUSTOM = `start + n × intervalDays`.
- **Alternatives considered:** computing in UTC (`DateTime.toUtc` arithmetic) — rejected, causes day-drift at month ends (spec §2.3, red risk).
- **Rationale:** pure function → trivially unit-testable; no clock/timezone injected → deterministic tests (leap year, Dec→Jan, clamp-restore).

### D3: `DateTime` normalized to local midnight for domain
Dates are stored as `YYYY-MM-DD` strings in SQLite and normalized to `DateTime(y, m, d)` (local) in the domain. No `toUtc()` anywhere in the billing path.
- **Rationale:** calendar dates, not instants; string storage avoids serializer timezone shifts and matches the backup format (M2).

### D4: Migration runner from day one
A `DatabaseMigrationRunner` reads `PRAGMA user_version`, applies migrations 1..N inside a transaction (each migration = a function receiving the `Database`), then writes the new `user_version`. Schema v1 includes the full locked schema from §6 of the spec.
- **Alternatives considered:** `sqflite_common_ffi`'s `onCreate`/`onUpgrade` only — rejected because it hardcodes version deltas per path and becomes painful once backup-import (M2) or P1 columns arrive.
- **Rationale:** the spec §2.6 explicitly requires the scaffold from v1; sequential runner is the simplest thing that satisfies "add columns later without refactor".

### D5: Abstract repository interfaces, sqflite implementation
`SubscriptionRepository` / `CategoryRepository` / `SettingsRepository` abstract classes with a `Sqflite*Repository` implementation; `RepositoryProvider` supplies the `Database`. Models are plain Dart classes with `fromMap`/`toMap` (dates as strings).
- **Alternatives considered:** direct SQL in features (rejected — M2 backup import + migrations must not duplicate SQL); codegen (drift) (rejected — adds build_runner overhead; schema is small and locked).
- **Rationale:** keeps SQL in one layer, testable with `sqflite_common_ffi` in-memory database.

### D5.1: Schema deviation note — `reminder_days_before` column (documented)
The locked plan's Dart model (§6) includes `List<int> reminderDaysBefore`, but its SQL schema omits the column. The v1 migration adds `reminder_days_before TEXT` (JSON-encoded int array) so the model can persist reminder preferences for M2 notifications. This is a deliberate, documented extension of the plan's SQL; the delta spec `data-storage` reflects it.

### D6: Testing strategy
Unit tests for Money (parse/format/sum/group), BillingCalculator (all spec edge cases incl. Jan 31→Feb 28→Mar 31, leap 2028-02-29, Dec 31→Jan, custom 45-day, weekly ignoring anchor, clamp-restore), and repositories using `sqflite_common_ffi` in-memory DB (CRUD round-trip, FK enforcement, seed idempotency, migration 1→2 forward).

**Project layout (new, Flutter-standard):**
```
lib/
  core/money/money.dart
  core/calendar/date_utils.dart
  features/subscriptions/domain/... (models, status enum, billing_cycle enum)
  features/subscriptions/data/ (repositories, sqflite impl, migrations)
  features/categories/data/
  core/storage/database.dart, migrations.dart
test/ (money_test, billing_calculator_test, repositories_test, migrations_test)
```

## Risks / Trade-offs

- [Migration bugs could corrupt data] → migrations run inside transactions; migration tests (1→2 with seeded data) in CI; `user_version` written only after success.
- [Anchor-day logic complexity] → single pure function + exhaustive calendar table tests (the spec lists exact expectations).
- [Int-only Money surprises formatting edge cases] → parse/format are centralised in `Money`; UI (M1) must use `Money.format()` via `intl`, never raw ints.
- [sqflite on desktop/tests needs ffi] → dev/test only use `sqflite_common_ffi`; production path stays plain `sqflite` (Android/iOS).

## Migration Plan

N/A — no deployed schema exists. "Migration plan" here is the scaffold itself: v1 = full locked schema; future changes append v2, v3… in `migrations.dart`.

## Open Questions

None — schema, cycles and calendar rules are fully locked in the execution spec.
