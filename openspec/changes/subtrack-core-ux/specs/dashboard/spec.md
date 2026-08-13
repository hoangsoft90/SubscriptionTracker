## Purpose

Shows the user their recurring costs at a glance — monthly/yearly totals ("Cost Shock"), a calm 5-year perspective, upcoming renewals, and red trial warnings — so the app delivers insight, not just CRUD.

> **AMENDED by `subtrack-decision-engine` (M2.5):** the Home screen layout was
> replaced by the 4-card "Money Command Center" (Monthly Cost, Today, Needs
> Attention, Month total + View calendar — see the `decision-engine` spec).
> The Upcoming-7-days card, the Top-3 list and the 5-year projection below are
> **no longer rendered**; the red trial badge remains on list/detail tiles only
> (not on the Home screen). The requirements below that reference those cards
> are superseded by the M2.5 `decision-engine` spec.

## ADDED Requirements

### Requirement: Monthly and yearly cost totals

The Home tab SHALL show monthly and yearly totals computed from active subscriptions via integer arithmetic, grouped by primary currency, using the "calm financial awareness" tone (no fear-marketing phrasing such as "You wasted $1,055!").

#### Scenario: Totals reflect active subscriptions

- **WHEN** active subscriptions exist with monthly and yearly cycles
- **THEN** the dashboard shows a monthly total and a yearly total, both exact (no floating-point rounding) and in the primary currency

#### Scenario: Cancelled/archived excluded from totals

- **WHEN** a subscription has status CANCELLED or ARCHIVED
- **THEN** it is excluded from dashboard totals

### Requirement: 5-year projection with honest label

> **SUPERSEDED by M2.5 (`subtrack-decision-engine`):** the Home screen no longer renders the 5-year figure (the 4-card Money Command Center replaced it). Requirement retained below for the M1 change history only.

The system SHALL show a 5-year projection labeled "5-Year Cost at Current Prices" (or "If nothing changes: $X over 5 years"), presented as a secondary, non-predictive figure.

#### Scenario: Projection label is non-predictive

- **WHEN** the dashboard renders the 5-year figure
- **THEN** the label reads "5-Year Cost at Current Prices" and it is styled as secondary information, not a headline

### Requirement: Upcoming renewals (next 7 days)

> **SUPERSEDED by M2.5 (`subtrack-decision-engine`):** the Upcoming-7-days card was replaced by the Today Money Brief (see the `decision-engine` spec). Requirement retained below for the M1 change history only.

The system SHALL list subscriptions whose next billing date falls within the next 7 days, sorted by date, with each entry showing name, amount, and due date.

#### Scenario: Renewal within 7 days listed

- **WHEN** an active subscription's next billing date is 3 days from today
- **THEN** it appears in the Upcoming list with its name, amount and due date

#### Scenario: Renewal beyond 7 days hidden

- **WHEN** an active subscription's next billing date is 20 days from today
- **THEN** it does not appear in the Upcoming list

### Requirement: Red trial badge

> **AMENDED by M2.5 (`subtrack-decision-engine`):** the badge remains on the subscription's list/detail entries only; it is no longer rendered on the Home screen (the 4-card layout replaced the dashboard sections that carried it).

For a subscription with `isTrial = true` whose `trialEndDate` has not passed, the system SHALL show a red trial badge on the subscription's list/detail entries so users notice the trial end.

#### Scenario: Active trial shows red badge

- **WHEN** a subscription is a trial with a future `trialEndDate`
- **THEN** a red trial badge is shown next to its name

#### Scenario: Expired trial shows no badge

- **WHEN** a subscription's `trialEndDate` is in the past
- **THEN** no trial badge is shown (trial shield notification behavior is M2)

### Requirement: Top-3 most expensive

> **SUPERSEDED by M2.5 (`subtrack-decision-engine`):** the Top-3 card is no longer rendered on the Home screen (the 4-card Money Command Center replaced it). Requirement retained below for the M1 change history only.

The system SHALL show the top 3 active subscriptions by amount (minor units) in the primary currency on the Home tab.

#### Scenario: Top-3 ranked by amount

- **WHEN** 5 active subscriptions exist in the primary currency
- **THEN** the dashboard lists the 3 with the highest amounts in descending order

### Requirement: Dashboard empty state

When no active subscriptions exist, the system SHALL show an inviting empty state (reinforcing privacy positioning) instead of zero-filled charts, with a clear call to add the first subscription.

#### Scenario: No subscriptions yet

- **WHEN** the user has not added any subscription
- **THEN** the dashboard shows an empty state with a call-to-action to add one
