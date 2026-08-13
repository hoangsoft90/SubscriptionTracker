## Purpose

Persists subscriptions, categories and app settings in a local SQLite database with a versioned migration scaffold, exposed through an abstract typed repository layer so no other layer touches raw SQL.

## ADDED Requirements

### Requirement: Initial SQLite schema

The system SHALL create tables `categories`, `subscriptions` and `app_settings` with the fields and indexes defined in the locked execution spec: subscriptions store name (user data), `amount_minor` (int), `currency`, `billing_cycle`, `custom_interval_days`, calendar dates `start_date`/`next_billing_date` as `YYYY-MM-DD`, `billing_anchor_day`, `is_trial`, `trial_end_date`, `cancellation_url` (optional), `status` (ACTIVE|CANCELLED|ARCHIVED), `category_id` FK, `color`, `icon_emoji`, `reminder_days_before` (JSON array of ints — documented extension of the plan's SQL so the Dart model's `reminderDaysBefore` field persists, needed by M2 notifications), `notes`, `created_at`, `updated_at`; categories store `id`, `name`, `icon_emoji`, `color_hex`, `is_default`; settings store `key`/`value` pairs.

#### Scenario: Fresh database has all tables

- **WHEN** the app opens the database for the first time
- **THEN** tables `categories`, `subscriptions` and `app_settings` exist with the required columns and indexes (`idx_sub_next_billing`, `idx_sub_status`, `idx_sub_category`)

#### Scenario: Foreign key enforcement

- **WHEN** a subscription row references a `category_id` that does not exist
- **THEN** the write is rejected by the foreign key constraint

### Requirement: Versioned migrations via PRAGMA user_version

The system SHALL track schema version with `PRAGMA user_version` and run a sequential migration runner that applies pending migrations in order; the scaffold SHALL exist from the first app version so later versions add columns without destructive refactor.

#### Scenario: First launch applies schema v1

- **WHEN** a fresh install opens the database
- **THEN** `PRAGMA user_version` is 1 after the initial schema is applied

#### Scenario: Existing DB migrates forward

- **WHEN** a database at `user_version = 1` is opened by a build whose latest migration is version 2
- **THEN** only the v2 migration runs and existing data is preserved, with `user_version` ending at 2

#### Scenario: No destructive re-runs

- **WHEN** an already-migrated database is opened again
- **THEN** no migration re-runs and `user_version` stays unchanged

### Requirement: Abstract repository layer

The system SHALL expose repository interfaces (e.g. `SubscriptionRepository`, `CategoryRepository`, `SettingsRepository`) with typed operations (insert/update/delete/query) so UI and services never embed raw SQL; the default implementation SHALL use sqflite.

#### Scenario: Repository returns typed models

- **WHEN** a subscription is saved through the repository and re-fetched
- **THEN** the returned model matches all stored fields exactly, including `amountMinor`, calendar date strings, and status

### Requirement: Calendar dates persisted as local date strings

The system SHALL persist `start_date`, `next_billing_date` and `trial_end_date` as local calendar `YYYY-MM-DD` strings (not UTC timestamps), and SHALL round-trip them without timezone shift.

#### Scenario: Date round-trip preserves calendar day

- **WHEN** a subscription with `next_billing_date = 2026-08-31` is saved and re-fetched on a device in any timezone
- **THEN** the returned date is still 2026-08-31

### Requirement: Default seed data

The system SHALL seed the 11 default categories (with `is_default = 1`) and any default app settings (e.g. `primaryCurrency`) on first launch, idempotently.

#### Scenario: Default categories seeded once

- **WHEN** a fresh database is created
- **THEN** 11 default categories exist with `is_default = 1`, and re-opening the app does not duplicate them
