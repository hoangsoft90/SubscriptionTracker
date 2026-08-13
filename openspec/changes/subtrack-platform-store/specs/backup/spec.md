## Purpose

Exports and imports the user's data as a versioned, validated JSON backup with a preview step, Merge/Replace conflict handling, and share-based transfer to a new device — without any cloud or account.

## ADDED Requirements

### Requirement: Versioned JSON export

The system SHALL export a JSON file with format marker `subtrack_backup`, `schemaVersion`, `exportedAt` (ISO 8601 UTC), `appVersion`, `settings` (e.g. `primaryCurrency`), `categories` and `subscriptions` arrays, per the locked spec §2.6.

#### Scenario: Export produces valid versioned file

- **WHEN** the user exports a backup
- **THEN** the file has the `subtrack_backup` format marker, `schemaVersion`, complete `categories` and `subscriptions` arrays, and can be re-imported without loss

### Requirement: Import validation before preview

The system SHALL validate the chosen file's format marker and schema version; unsupported or newer schema versions SHALL be rejected with a clear error before any preview or mutation.

#### Scenario: Reject non-backup file

- **WHEN** the user picks a JSON file that is not a `subtrack_backup`
- **THEN** import is rejected with an error and no data is touched

#### Scenario: Reject future schema version

- **WHEN** the user picks a backup with a newer `schemaVersion` than the app supports
- **THEN** import is rejected with a clear message

### Requirement: Import preview

Before applying, the system SHALL show a preview: "Found N subscriptions, M categories" (and settings summary), so the user confirms what will be imported.

#### Scenario: Preview shown before import

- **WHEN** a valid backup is selected
- **THEN** the user sees a preview of the counts before any data is merged or replaced

### Requirement: Merge vs Replace All

The user SHALL choose between **Merge** (rows with IDs that already exist are skipped; new rows are inserted) and **Replace All** (existing data is removed first, then the backup's data is restored). The system SHALL confirm the destructive nature of Replace All before executing.

#### Scenario: Merge skips duplicate IDs

- **WHEN** a backup containing a subscription whose ID already exists is merged
- **THEN** the existing row is kept and the backup's row is skipped, with no duplicate created

#### Scenario: Replace All wipes and restores

- **WHEN** the user confirms Replace All
- **THEN** existing categories/subscriptions/settings are replaced by the backup contents

#### Scenario: Re-import does not duplicate

- **WHEN** the same backup is imported twice with Merge
- **THEN** no duplicates are created (existing IDs are skipped both times)

### Requirement: Transfer to a new device

The system SHALL let the user share the exported backup file via the OS share sheet, and on the new device import it to restore data — no phone-to-phone protocol is required.

#### Scenario: Export then reinstall then import

- **WHEN** a user exports, deletes the app, reinstalls, and imports the backup
- **THEN** categories, subscriptions and settings are restored 100% (per DoD)

### Requirement: Internal migrations stay separate

Internal SQLite schema migrations SHALL remain on `PRAGMA user_version` (M0 scaffold); the backup `schemaVersion` is a separate, data-format version.

#### Scenario: Backup survives app schema migration

- **WHEN** an app build with a newer internal `user_version` imports an older backup
- **THEN** import succeeds as long as the backup `schemaVersion` is supported, and internal migration runs normally
