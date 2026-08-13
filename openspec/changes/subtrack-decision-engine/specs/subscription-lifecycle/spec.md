## Purpose

Extends the subscription lifecycle with a pending-cancellation state that separates "the user asked to cancel" from "the subscription has stopped billing", and transitions between states automatically so the savings figures stay accurate without manual bookkeeping.

## ADDED Requirements

### Requirement: Pending-cancellation state

The system SHALL support a `PENDING_CANCELLATION` status between ACTIVE and CANCELLED: when the user cancels a subscription, the system opens the cancellation URL (if present) and transitions the subscription to pending-cancellation; it SHALL NOT mark it cancelled while the paid cycle is still active.

#### Scenario: Cancel moves to pending-cancellation

- **WHEN** the user cancels an active subscription
- **THEN** its status becomes pending-cancellation and the cancellation URL is opened when present

### Requirement: Automatic transition to cancelled

The system SHALL automatically transition pending-cancellation subscriptions to cancelled when their next billing date is in the past, during the existing notification reconcile pass, setting the cancellation date to that billing date, and SHALL then recompute savings figures.

#### Scenario: Pending cancellation expires after billing date

- **WHEN** a pending-cancellation subscription's next billing date is before today
- **THEN** during reconcile the subscription becomes cancelled with cancellation date set to the billing date

#### Scenario: No manual step required

- **WHEN** a pending-cancellation subscription's billing date passes
- **THEN** the transition to cancelled happens automatically without any user action

### Requirement: Paywall counting for pending-cancellation

The system SHALL count pending-cancellation subscriptions toward the free-tier active-subscription limit, and SHALL exempt only cancelled and archived subscriptions from the count.

#### Scenario: Pending cancellation still counts toward free tier

- **WHEN** a user with the free tier has active-plus-pending-cancellation subscriptions reaching the free-slot count
- **THEN** the pending-cancellation subscriptions consume slots (the banner shows the reduced free-slot count), and once 11+ slot-consuming subscriptions exist, adding another is blocked until one is cancelled or archived
