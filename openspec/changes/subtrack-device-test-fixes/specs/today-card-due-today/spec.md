## Purpose

Fixes a genuine UI bug found during device testing (2026-08-15): the Home "Today" card read "You're clear" while subscriptions were renewing **today**. `TodayBriefService.clear` only considered `nextRenewal` (strictly after today) and `trialEnding`, so a day whose only events were due-today renewals was classified as clear and the card rendered nothing about them.

## ADDED Requirements

### Requirement: Today brief exposes due-today subscriptions and is not "clear" when events happen today
`TodayBriefService` SHALL expose the list of ACTIVE subscriptions billing today (`dueToday`) and `clear` SHALL be false while any charge or trial event happens today (`!hasEventToday`).

#### Scenario: Renewal today is not clear
- **WHEN** an ACTIVE subscription has next billing date = today and `TodayBriefService.compute` runs
- **THEN** `brief.clear` is false, `brief.hasEventToday` is true and `brief.dueToday` contains that subscription

#### Scenario: Mixed due dates
- **WHEN** one subscription bills today and another bills later this month
- **THEN** `dueToday` contains only the today-billing subscription; the later one is not in `dueToday`

### Requirement: Home Today card renders due-today renewals
The `_TodayCard` on Home SHALL render a per-subscription row ("Next: {name} — in today ({date})" with the amount) for every subscription in `dueToday`, above the next-renewal row, and SHALL NOT show the "You're clear" message while `dueToday` is non-empty.

#### Scenario: Renewal today shows on the card
- **WHEN** the app has an ACTIVE subscription renewing today and Home is displayed
- **THEN** the Today card shows the subscription's "in today" row and the text "You're clear" is absent

#### Scenario: Truly clear stays clear
- **WHEN** no active subscription has an upcoming renewal, a due-today billing or a trial ending within 3 days
- **THEN** the Today card shows "You're clear" (unchanged behavior)
