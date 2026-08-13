## Purpose

Hardens SubTrack after a full post-launch code review: FK-safe backup restore, money totals that count every billing cycle, human-readable category names, locale-aware dates, immediate notification reconciliation after import, live UI refresh after lifecycle transitions, and overflow-safe status labels.

## ADDED Requirements

### Requirement: Backup Replace All is foreign-key safe
When the user restores a backup with "Replace All", the system SHALL delete existing rows in an order that never violates the enabled foreign-key constraint — subscription rows (which reference categories) SHALL be removed before categories. The operation SHALL complete without error on real SQLite when existing subscriptions reference existing categories.

#### Scenario: Replace All succeeds on real SQLite
- **WHEN** the database contains a subscription referencing an existing category and the user restores a backup with Replace All
- **THEN** the wipe-and-restore completes without a foreign-key violation

#### Scenario: Restored data matches the backup
- **WHEN** Replace All completes
- **THEN** the database contains exactly the subscriptions, categories and settings from the backup

### Requirement: Monthly cost counts every active billing cycle
The Home "Monthly" headline SHALL be the sum of the monthly-equivalent of every active subscription regardless of billing cycle (weekly, monthly, quarterly, yearly, custom), derived from each subscription's yearly cost divided by 12. A subscription charged yearly SHALL contribute its yearly amount / 12; only cancelled and archived subscriptions SHALL be excluded.

#### Scenario: Yearly-only subscriptions are counted
- **WHEN** the only active subscription charges $120 per year
- **THEN** the Monthly headline shows $10

#### Scenario: Mixed cycles sum correctly
- **WHEN** active subscriptions include monthly and yearly charges
- **THEN** the Monthly headline is the sum of their monthly equivalents (yearly cost ÷ 12)

### Requirement: Detail screen shows the category display name
The subscription detail screen SHALL show the category's display name resolved from the category list. If the referenced category no longer exists, the screen SHALL show a generic "Uncategorized" label. The raw category id/slug SHALL never be shown to the user.

#### Scenario: Known category shows its name
- **WHEN** a subscription references category id `streaming` whose name is "Streaming"
- **THEN** the detail screen shows "Streaming" and does not show the raw id

#### Scenario: Missing category falls back to Uncategorized
- **WHEN** a subscription references a category id that no longer exists (e.g. restored from a backup)
- **THEN** the detail screen shows "Uncategorized"

### Requirement: Date formatting is locale-aware
Short billing dates shown in the subscription list and detail SHALL be formatted by locale: day-first (`DD/MM`) when the app language is Vietnamese, and month-first (`MM/DD`) otherwise. The app SHALL never render a fixed month-first date for Vietnamese users.

#### Scenario: Vietnamese shows day-first
- **WHEN** the app language is Vietnamese
- **THEN** a billing date on 15 August renders as `15/08`

#### Scenario: English shows month-first
- **WHEN** the app language is English
- **THEN** the same billing date renders as `08/15`

### Requirement: Backup import reconciles scheduled notifications
After any successful import (Merge or Replace All), the system SHALL re-run the notification reconcile so reminders for removed/replaced subscriptions are cancelled immediately. A scheduling failure SHALL NOT block or fail the import — the import result is already applied and is never rolled back by notification housekeeping.

#### Scenario: Import cancels stale reminders
- **WHEN** the user imports a backup that removes subscriptions with pending reminders
- **THEN** those reminders are cancelled as part of the import flow

#### Scenario: Notification failure never blocks import success
- **WHEN** notification scheduling is unavailable during an import
- **THEN** the import still completes and the user sees the success message

### Requirement: Lifecycle transitions refresh the UI immediately
When the scheduler automatically transitions a subscription from PENDING_CANCELLATION to CANCELLED, the subscription list and dashboard SHALL refresh automatically so the user sees the new status without any further action.

#### Scenario: List reflects the automatic transition
- **WHEN** a pending-cancellation subscription's billing date passes and reconcile runs
- **THEN** the subscription list shows it as Cancelled without any user action

### Requirement: Status labels do not overflow the list
Status chips in the subscription list SHALL constrain their text to a single line that ellipsizes, so long labels (e.g. "Pending cancellation") never overflow the list tile on narrow screens.

#### Scenario: Long status label ellipsizes
- **WHEN** a subscription has status "Pending cancellation" and the tile width is constrained
- **THEN** the chip text is truncated with an ellipsis instead of overflowing the tile
