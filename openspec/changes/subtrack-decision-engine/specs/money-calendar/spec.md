## Purpose

Provides a month calendar view showing when recurring charges happen, using a minimal dot-per-day indicator so users can see their charge pattern at a glance without the complexity of a budgeting heatmap.

## ADDED Requirements

### Requirement: Dot-only month calendar

The system SHALL render a month calendar where each day with at least one charge is marked with a single dot (no color heatmap, no per-subscription markers). A day SHALL show at most one dot regardless of how many subscriptions renew that day.

#### Scenario: Multiple renewals share one dot

- **WHEN** three subscriptions renew on the same day of the displayed month
- **THEN** that day shows exactly one dot

#### Scenario: Days without charges have no dot

- **WHEN** a day of the displayed month has no renewal
- **THEN** that day shows no dot

### Requirement: Per-day charge detail

The system SHALL, when the user taps a day with charges, show the list of subscriptions renewing that day (name + amount) and the day's total, grouped per currency without mixing currencies.

#### Scenario: Tap day shows renewals and total

- **WHEN** the user taps a day that has renewals
- **THEN** the system shows each renewing subscription's name and amount and a per-currency total for that day

#### Scenario: Tap day without renewals

- **WHEN** the user taps a day that has no charges
- **THEN** the system shows an empty detail state

### Requirement: Billing projection for calendar dots

The system SHALL compute the charge days for the displayed month only (not the whole year), using the billing engine's next-billing-date calculation for each active subscription (custom cycles by interval days, fixed cycles by anchor day with month-end clamping).

#### Scenario: Calendar renders only visible month

- **WHEN** the user views a month in the calendar
- **THEN** the system computes dots for that month's charges only, and never computes beyond the displayed month

#### Scenario: Anchor-day subscriptions appear correctly

- **WHEN** a subscription bills on the 31st and the displayed month has no 31st
- **THEN** its charge is shown on the last day of that month per the billing engine's clamping rule
