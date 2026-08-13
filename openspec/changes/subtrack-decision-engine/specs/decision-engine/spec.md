## Purpose

Turns the Home screen into a "Money Command Center" that surfaces the payments needing the user's attention today (Today Money Brief), items worth reviewing (Review Queue with stale detection), and the money saved by cancelling (Savings Counter) — all computed locally.

## ADDED Requirements

### Requirement: Today Money Brief card

The system SHALL render a "Today" card as the **second** card on the Home screen (below the Monthly Cost card, per the 4-card order in the "Home layout limit" requirement) that summarizes what needs attention today based on the device's local calendar date. When no renewal or trial event occurs today, the card SHALL show a positive empty state ("Nothing due today"); otherwise it SHALL show the single next event (name, amount, relative + absolute date) or a trial-ending warning with a review action.

#### Scenario: No events due today

- **WHEN** no active subscription has a billing or trial event on the device's local calendar date
- **THEN** the Today card shows the positive empty message and no subscription rows

#### Scenario: Next renewal shown with countdown

- **WHEN** an active subscription has its next billing date in the future and no event occurs today
- **THEN** the Today card shows that subscription's name, amount, and "in N days (weekday, date)" countdown

#### Scenario: Trial ending soon warning

- **WHEN** an active trial subscription has a trial end date within 3 days of the local calendar date
- **THEN** the Today card shows a warning with the subscription name, the post-trial price, and a review action

#### Scenario: Local calendar date used

- **WHEN** the device timezone changes between sessions
- **THEN** the Today card recomputes against the new local calendar date on the next open, without UTC conversion

### Requirement: Review Queue

The system SHALL maintain a "Needs Attention" queue of subscriptions ranked by priority, and SHALL show at most 3 items on the Home card with a "Review all (N)" action revealing the rest. Items SHALL be: trial ending within 3 days (high), renewal within 1 day (high), price changed and not yet acknowledged (medium), not reviewed in more than 90 days (medium). The queue SHALL be in-app only — it SHALL NOT schedule any notification.

#### Scenario: Queue priority ordering

- **WHEN** subscriptions match multiple queue conditions
- **THEN** the queue orders them high priority first (trial ending, renewal due) then medium (price changed, stale), and the Home card renders only the 3 highest

#### Scenario: Trial event not double-notified

- **WHEN** a subscription's trial is ending within 3 days
- **THEN** it appears in the in-app Review Queue but the system does not create a duplicate notification for the same event beyond the existing Trial Shield notifications

#### Scenario: Review action Keep

- **WHEN** the user reviews a queued subscription and chooses Keep
- **THEN** the subscription's last-reviewed date is set to today and it leaves the stale/queue conditions

#### Scenario: Review action Later

- **WHEN** the user reviews a queued subscription and chooses Later
- **THEN** the item is hidden from the queue without changing the last-reviewed date

#### Scenario: Review action Cancel

- **WHEN** the user reviews a queued subscription and chooses Cancel
- **THEN** the system opens the subscription's cancellation URL when present and transitions the subscription to the pending-cancellation state

### Requirement: Stale subscription detection

The system SHALL flag active subscriptions whose last-reviewed date is older than their review interval (default 90 days) as stale, add them to the Review Queue at medium priority, and SHALL phrase the message calmly without fear marketing ("Haven't reviewed X in N months. Still worth it?"). A never-reviewed subscription is treated as reviewed at its `created_at` for the interval comparison (so fresh subscriptions don't instantly go stale).

#### Scenario: Long-unreviewed subscription queued

- **WHEN** an active subscription has a last-reviewed date more than 90 days before today
- **THEN** it appears in the Review Queue with a stale-review message and medium priority

#### Scenario: Imported data does not create a fake backlog

- **WHEN** subscriptions are imported from a backup (merge or replace)
- **THEN** each imported subscription's last-reviewed date is set to its creation date so it is not immediately flagged as stale

### Requirement: Savings Counter

The system SHALL track and display two distinct savings figures, always labeled "estimated": Projected Savings (monthly-equivalent sum of all subscriptions in pending-cancellation or cancelled state) and Realized Savings (the sum that starts accumulating only for cancelled subscriptions after their billing date has passed since cancellation). The system SHALL show the monthly-cost reduction (current vs. pre-cancellation) on the dashboard.

#### Scenario: Projected savings shown

- **WHEN** at least one subscription is cancelled or pending-cancellation
- **THEN** the dashboard shows the estimated monthly-equivalent savings from those subscriptions

#### Scenario: Realized savings only after billing date passes

- **WHEN** a subscription is cancelled and the current date is before its billing date
- **THEN** it contributes nothing to Realized Savings; once the date passes, its contribution starts

#### Scenario: Re-subscribe stops old savings

- **WHEN** a new active subscription is created with the same name (case-insensitive) as a cancelled subscription
- **THEN** the old record is marked superseded and stops contributing to Realized Savings from the re-subscribe date, and the name is not shown in both active and savings lists simultaneously

### Requirement: Home layout limit

The system SHALL render at most 4 cards on the Home screen, in this order: Monthly Cost, Today, Needs Attention, and the month's total with a "View calendar" action. No additional Home cards SHALL be introduced beyond this set.

#### Scenario: Dashboard renders four-card layout

- **WHEN** the Home screen is rendered with data
- **THEN** it shows at most the four defined cards in the defined order
