## Purpose

Schedules deterministic local renewal and trial-end notifications and keeps them consistent with the subscription data through a reconciliation pass, so users never miss a charge and stale notifications never linger.

## ADDED Requirements

### Requirement: Deterministic notification IDs

Each notification SHALL get an ID derived deterministically from `FNV-1a('$subscriptionId|${triggerAt.toIso8601String()}|${reminderType.name}') % 2147483647` — the concatenated input uses `|` separators between the three components, and `triggerAt` is the scheduled delivery time (the billing/trial date at the reminder hour) — so re-scheduling produces the same ID for the same event and cancel-by-ID is reliable.

#### Scenario: Same event yields same ID

- **WHEN** the scheduler runs twice for the same subscription, billing date and reminder type
- **THEN** both runs compute the same notification ID

### Requirement: Reconcile on data changes

The system SHALL run `NotificationScheduler.reconcile()` on: app open, subscription add/edit/delete, timezone change detection, and after reboot (via workmanager on Android). Reconcile SHALL: load active subscriptions, generate reminder events for the next 7–14 days, sort by trigger time grouping same-time events, cap at 50 events (iOS hard limit 64), cancel the app's own scheduled IDs, re-schedule the new list, and persist scheduler state.

#### Scenario: Edit moves next billing date

- **WHEN** a user edits a subscription so its next billing date changes
- **THEN** the old notification ID is cancelled and a new one is scheduled for the new date

#### Scenario: Delete cancels notifications

- **WHEN** a user deletes a subscription that had scheduled reminders
- **THEN** all its notification IDs are cancelled and no stale notification remains

#### Scenario: Notification count capped at 50

- **WHEN** pending reminders would exceed 50 events
- **THEN** the scheduler keeps only the first 50 by trigger time

### Requirement: No reliance on background refresh

Notification delivery SHALL NOT depend on background fetch/refresh; the OS delivers scheduled local notifications directly, and reconcile() keeps the schedule correct on the triggers listed above.

#### Scenario: Notifications fire without background refresh

- **WHEN** the app has not been opened for a week but a renewal reminder was scheduled
- **THEN** the OS still delivers the notification at the scheduled time

### Requirement: Notification permission requested at the right moment

The system SHALL NOT request notification permission at first launch or during onboarding; it SHALL request permission right after the user adds their first subscription, at the point a reminder is being set.

#### Scenario: No permission prompt at launch

- **WHEN** a user opens the app for the first time and completes onboarding
- **THEN** no notification permission prompt is shown

#### Scenario: Permission requested after first subscription

- **WHEN** a user adds their first subscription with a reminder configured
- **THEN** the notification permission prompt is shown at that moment

### Requirement: Trial Shield notifications

For a subscription with `isTrial = true` and a future `trialEndDate`, the system SHALL schedule two notifications — one 2 days before `trialEndDate` and one on `trialEndDate` itself — independent of `nextBillingDate`; if `trialEndDate` has passed, no trial notification is scheduled. `cancellationUrl` is optional and does not gate scheduling.

#### Scenario: Trial reminders fire around trial end

- **WHEN** a trial ends 2026-08-10
- **THEN** reminders are scheduled for 2026-08-08 and 2026-08-10, regardless of the subscription's next billing date

#### Scenario: Expired trial has no reminders

- **WHEN** a subscription's `trialEndDate` is in the past
- **THEN** no trial notifications are scheduled for it

### Requirement: Timezone-change reconciliation

On each app open, the system SHALL compare the current device timezone with the stored one; on change, SHALL run `reconcile()` for all active subscriptions and persist the new timezone.

#### Scenario: Travel changes timezone

- **WHEN** a user opens the app in a different timezone than last time
- **THEN** reconcile() re-runs and scheduled notification times reflect the new local time
