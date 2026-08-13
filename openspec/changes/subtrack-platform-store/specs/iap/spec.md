## Purpose

Sells a one-time Lifetime Pro entitlement through the platform stores and enforces the free-tier limits (10 subscriptions) with a hard paywall at 11+, while remaining fully functional offline — the store is the source of truth, with no server.

> **AMENDED by `subtrack-decision-engine` (M2.5, plan2_final §5):** the
> slot count is computed from ACTIVE **plus** PENDING_CANCELLATION
> subscriptions (a pending-cancellation subscription is still an active
> charge); only CANCELLED/ARCHIVED free a slot. The hard-block threshold below
> is stated per the implementation: the free-tier state checks the *current*
> slot count before an add — 9–10 shows the banner, and the hard block engages
> once **11+ slot-consuming subscriptions already exist** (the 11th
> subscription is added while the banner shows "0 free slots left").

## ADDED Requirements

### Requirement: One-time Lifetime Pro product

The system SHALL offer a single non-consumable one-time purchase (Lifetime Pro, $4.99–$9.99) via `in_app_purchase` (StoreKit 2 on iOS, Play Billing Library 6+ on Android); there SHALL be no subscription/consumable pricing.

#### Scenario: Pro product listed

- **WHEN** the user opens the paywall
- **THEN** the Lifetime Pro product is shown with its store price

### Requirement: Free tier limits with staged messaging

With 1–8 subscriptions the system SHALL show no paywall interference; at 9–10 it SHALL still allow adding with a light banner "You have N free slots left" (N counts down to 0); once 11+ slot-consuming subscriptions (ACTIVE + PENDING_CANCELLATION) already exist, the system SHALL hard-block adding new subscriptions until Pro is purchased.

#### Scenario: No interference under 9 subscriptions

- **WHEN** the user has 8 subscriptions and adds a ninth
- **THEN** the add flow proceeds without any paywall prompt or banner

#### Scenario: Banner at 9–10 subscriptions

- **WHEN** the user has 9 subscriptions
- **THEN** adding still works and a light banner shows "You have N free slots left"

#### Scenario: Hard block once 11+ exist

- **WHEN** the user already has 11 slot-consuming subscriptions and tries to add another
- **THEN** the add is blocked and the user is directed to the Lifetime Pro paywall

### Requirement: Purchase flow

The system SHALL run the store purchase flow, validate the transaction with the platform, and grant Pro entitlement on success; the entitlement SHALL be persisted locally (the store remains the source of truth for restore).

#### Scenario: Successful purchase grants Pro

- **WHEN** a purchase succeeds and is validated
- **THEN** the user is Pro, the limit is lifted, and the state persists across launches

### Requirement: Restore without an app backend

The system SHALL provide a "Restore Purchase" action that restores the Pro entitlement via the platform store SDK (StoreKit 2 / Play Billing), with no app server or backend required.

#### Scenario: Restore requires no app backend

- **WHEN** a user taps "Restore Purchase" on a device where they previously purchased
- **THEN** the store SDK returns the prior purchase and the Pro entitlement is restored, without any app server being contacted

### Requirement: Entitlement check by slot-consuming subscription count

The system SHALL compute the free-slot state from the count of slot-consuming subscriptions (ACTIVE + PENDING_CANCELLATION per the M2.5 amendment) and the Pro entitlement, applying the free-tier rules on every add attempt; CANCELLED and ARCHIVED subscriptions do not consume a slot.

#### Scenario: Archived subscriptions do not consume a slot

- **WHEN** a user has 9 ACTIVE subscriptions plus several ARCHIVED ones
- **THEN** adding one more subscription succeeds (10 ACTIVE total), because archived rows do not count toward the limit

#### Scenario: Limit reached blocks further adds

- **WHEN** a user already has 11 slot-consuming subscriptions
- **THEN** attempting to add another is blocked and the user is directed to the Lifetime Pro paywall

### Requirement: No recurring billing

The system SHALL NOT offer any auto-renewing subscription product, consistent with the app's anti-subscription positioning.

#### Scenario: Only one product exists

- **WHEN** the user views available purchases
- **THEN** exactly one non-consumable Lifetime Pro product is available and no auto-renewing subscription appears
