## Purpose

Calculates the next billing date for recurring subscriptions using calendar-local dates with a "same day if possible, else last day of month" policy, so billing never drifts or breaks at month ends, year ends, or leap years.

## ADDED Requirements

### Requirement: Next billing date uses calendar dates, not UTC timestamps

The billing engine SHALL operate on calendar dates (local `YYYY-MM-DD`), not absolute UTC timestamps; all inputs and outputs are dates, and the engine SHALL NOT perform UTC conversion when computing dates.

#### Scenario: Engine ignores timezone when computing next date

- **WHEN** computing the next billing date for a subscription whose current billing date is 2026-01-31
- **THEN** the result is 2026-02-28 regardless of the device timezone

### Requirement: Same-day-if-possible month-end clamping

For MONTHLY, QUARTERLY and YEARLY cycles, when the anchor day does not exist in a target month, the next billing date SHALL be the last day of that month, and the anchor day SHALL NOT drift (e.g. Jan 31 → Feb 28 → Mar 31, never Mar 28).

#### Scenario: January 31 rolls into February

- **WHEN** a monthly subscription has billing date 2026-01-31
- **THEN** the next billing date is 2026-02-28

#### Scenario: Month-end clamps back to anchor

- **WHEN** a monthly subscription has billing date 2026-02-28 (clamped from Jan 31 anchor)
- **THEN** the next billing date is 2026-03-31 (anchor day restored, not 2026-03-28)

#### Scenario: Leap year February

- **WHEN** a monthly subscription has billing date 2028-01-31
- **THEN** the next billing date is 2028-02-29 (leap year), and the following is 2028-03-31

#### Scenario: December to January year boundary

- **WHEN** a monthly subscription has billing date 2026-12-31
- **THEN** the next billing date is 2027-01-31

### Requirement: Quarterly and yearly anchor clamping

QUARTERLY and YEARLY cycles SHALL follow the same anchor-day and month-end-clamping rules as MONTHLY.

#### Scenario: Yearly subscription on Feb 29

- **WHEN** a yearly subscription has billing date 2028-02-29
- **THEN** the next billing date is 2029-02-28 (non-leap year clamps to last day), and the following is 2030-02-28 (anchor 29 not restorable — last day of Feb 2030)

### Requirement: Custom cycle by interval days

For a CUSTOM cycle, the next billing date SHALL be `startDate + n × customIntervalDays`, ignoring `billingAnchorDay`.

#### Scenario: Custom 45-day interval

- **WHEN** a subscription started 2026-01-01 with a custom interval of 45 days
- **THEN** the next billing date is 2026-02-15 (startDate + 45 days), regardless of any anchor day

### Requirement: Anchor day never mutates into a new anchor

After month-end clamping, the engine SHALL preserve the original anchor day internally so subsequent months restore it; the anchor SHALL NOT become the clamped day.

#### Scenario: Anchor preserved through clamp

- **WHEN** a subscription with anchor day 31 is billed Feb 28 and the engine is asked for the following month
- **THEN** the following billing date is Mar 31 (anchor 31 preserved, not 28)

### Requirement: Billing anchor only applies to fixed calendar cycles

`billingAnchorDay` SHALL apply only to MONTHLY, QUARTERLY and YEARLY cycles; for WEEKLY and CUSTOM cycles it SHALL be ignored.

#### Scenario: Weekly cycle ignores anchor

- **WHEN** a weekly subscription with an anchor day set is billed
- **THEN** the next billing date is exactly 7 days later, ignoring the anchor

### Requirement: Monthly projection helper

The engine SHALL provide an annualized projection (e.g. monthly cost × 12, yearly cost as-is, weekly × 52) operating on integer minor units, plus a 5-year projection multiplier, for use by the dashboard (M1).

#### Scenario: Projection uses integer math

- **WHEN** projecting a monthly USD 999-minor subscription over 12 months
- **THEN** the yearly projection is exactly 11988 minor units
