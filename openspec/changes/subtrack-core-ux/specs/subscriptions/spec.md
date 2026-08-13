## Purpose

Provides the core CRUD experience: list, search, sort, filter, add, edit and detail flows for subscriptions, fast enough (add under 25 seconds) that tracking feels frictionless, with an explicit trial toggle in the primary step.

> **AMENDED by `subtrack-decision-engine` (M2.5):** the status lifecycle now has a 4th value,
> `PENDING_CANCELLATION`, added between ACTIVE and CANCELLED (see the
> `subscription-lifecycle` spec). The requirements below that mention "three
> statuses" are superseded: the list filter chips and detail actions now cover
> all four statuses.

## ADDED Requirements

### Requirement: Add subscription in under 25 seconds

The system SHALL let a user add a subscription (name, amount, currency, billing cycle, start date) through a compact form where the "Free trial?" toggle is available in the primary step and the minimum required fields are collected on a single screen, so a user can complete the flow in under 25 seconds of interaction (the <25s target is verified manually as a DoD criterion).

#### Scenario: Fast add from empty state

- **WHEN** the user taps "Add subscription" from the empty state
- **THEN** the add form opens with the "Free trial?" toggle in the primary step and all minimum required fields (name, amount, currency, billing cycle, start date) on one screen with no forced multi-step wizard

#### Scenario: Preset pre-fills the form

- **WHEN** the user picks a preset from the catalog
- **THEN** the add form is pre-filled with the preset's name, category, icon and (validated) cancellation URL — with no price or cycle forced — and amounts remain user-entered

### Requirement: Trial fields in add/edit

When "Free trial?" is toggled on, the system SHALL show and require a trial end date distinct from the next billing date, and SHALL show a "Suggested, please verify" hint when pre-filled from a preset suggestion.

#### Scenario: Trial end date entered

- **WHEN** the user toggles "Free trial?" on and enters a trial end date
- **THEN** the subscription is saved with `isTrial = true` and the given `trialEndDate`, independent of `nextBillingDate`

### Requirement: Edit and detail screens

The system SHALL provide a detail screen showing all subscription fields (including status, category, notes, cancellation URL when present) and an edit screen that pre-fills every field for modification.

#### Scenario: Edit preserves untouched fields

- **WHEN** the user edits only the amount of an existing subscription
- **THEN** all other fields (name, cycle, dates, trial flag, category, notes) remain unchanged

### Requirement: Status lifecycle

The system SHALL support the statuses ACTIVE, CANCELLED, ARCHIVED — and, per the M2.5 `subscription-lifecycle` amendment, PENDING_CANCELLATION — via explicit user actions on the detail screen, and SHALL keep cancelled/archived subscriptions visible in the list (with status chip) while excluding them from dashboard totals.

#### Scenario: Cancel an active subscription

- **WHEN** the user cancels an active subscription
- **THEN** its status becomes PENDING_CANCELLATION per the M2.5 lifecycle (the cancel action always moves to pending-cancellation; CANCELLED is reached only via the automatic transition in `reconcile()`), it remains visible with a status chip, and dashboard totals exclude it

### Requirement: Search, sort and filter

The system SHALL provide search by subscription name, sorting (by name, amount, next billing date), and filtering by status in the Subscriptions list.

> **Implementation note:** the data/controller layer also supports a category
> filter (`SubscriptionFilter.categoryId`), but the list screen exposes only
> the status filter chips — there is no category-filter control in the M1 UI.

#### Scenario: Search narrows the list

- **WHEN** the user types a search term
- **THEN** the list shows only subscriptions whose name contains the term (case-insensitive)

#### Scenario: Filter by status

- **WHEN** the user filters by status ACTIVE
- **THEN** only active subscriptions are shown

### Requirement: User-entered names are never localized

Subscription names entered by the user SHALL be stored and displayed exactly as typed; the system SHALL NOT translate or re-render them when the app language changes (language switching arrives in M2).

#### Scenario: Custom name survives language switch

- **WHEN** the app language later changes from EN to VI
- **THEN** user-entered subscription names display unchanged

### Requirement: Deletion flow

The system SHALL let the user delete a subscription only after a confirmation step, and deletion SHALL remove the row from storage.

#### Scenario: Delete requires confirmation

- **WHEN** the user taps delete
- **THEN** a confirmation prompt is shown and the subscription is removed only after confirmation
