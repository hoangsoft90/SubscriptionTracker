## Context

SubTrack is a local-first Flutter app (M0–M2 complete: exact-money core, calendar billing engine, SQLite repositories, dashboard with Upcoming/Top-3 cards, notifications with `NotificationScheduler.reconcile()`, backup import, paywall free-tier counting). The locked M2.5 spec (see proposal.md — Why) adds a "decision engine" layer: Today Money Brief, Review Queue + stale detection, Savings Counter, dot-only Money Calendar, price-change detection/history, and a `PENDING_CANCELLATION` lifecycle state. All features must stay offline, integer-exact for money, and calendar-local for dates.

## Goals / Non-Goals

**Goals:**
- Additive schema v2 migration (new columns + `subscription_price_history` table) that preserves all existing data.
- Reuse existing `NotificationScheduler.reconcile()` as the single trigger for the automatic PENDING_CANCELLATION → CANCELLED transition (no new background jobs).
- Keep Home to the 4-card layout, replacing the old Upcoming card with the Today Brief.
- Compute Review Queue and calendar dots from in-memory subscription data only (no extra network, no yearly precompute).

**Non-Goals:**
- No notification for Review Queue items (Trial Shield already covers trial reminders).
- No color heatmap / budgeting features in the calendar.
- No AI advisor, streaks, gamification, or reminder-profile customization (pushed to P1).
- No change to backup file format or schema version marker (backup codec stays as-is; the new columns serialize through existing `Subscription.toMap`/`fromMap`).

## Decisions

### D1: Schema v2 migration is purely additive
`migrations.dart` appends `Migration(2, _migrationV2)`: `ALTER TABLE subscriptions ADD COLUMN` for `last_reviewed_at`, `review_interval_days` (default 90), `pending_cancellation` (0/1), `cancelled_at`, `previous_amount_minor`, `superseded_at`; plus `CREATE TABLE subscription_price_history` (FK cascade, `idx_price_history_sub`).
- **Alternatives considered:** separate tables for reviews (rejected — plan2_final §7 explicitly says `last_reviewed_at` alone is enough for v1).
- **Rationale:** additive ALTERs are non-destructive and match the existing migration runner contract; old backups still round-trip because new columns are nullable/defaulted.

### D2: `PENDING_CANCELLATION` as a new enum value, not a boolean-only signal
`SubscriptionStatus` gains `pendingCancellation('PENDING_CANCELLATION')`. The plan also lists a `pending_cancellation` column; we persist the enum as the source of truth (`status` column) and keep the column addition for backwards compatibility with the locked schema, mapping it from status. Actually, to avoid two sources of truth, the column is kept but derived from `status` in `fromMap`/`toMap` (status wins).
- **Alternatives considered:** boolean flag only (rejected — a 4th enum value is a natural fit for the existing status model, list filtering, and paywall counting).
- **Rationale:** `countByStatus`, list chips, and paywall counting all already key off `SubscriptionStatus`; adding a value requires the least new plumbing.

### D3: State transition lives inside `reconcile()`
`NotificationScheduler.reconcile()` (already invoked on app open, add/edit/delete, timezone change, reboot) gains a step: load all subscriptions, find `PENDING_CANCELLATION` with `nextBillingDate < today`, transition to `CANCELLED` with `cancelled_at = nextBillingDate`, persist, and recompute savings.
- **Alternatives considered:** a separate cron/background task (rejected — the app is local-first with no background guarantees beyond what notifications already use; reconcile is the existing single pass).
- **Rationale:** plan2_final §5 explicitly designates reconcile() as the trigger; zero new scheduling infrastructure.

### D4: Review Queue computed in-memory from repository data
A `ReviewQueue` service scores subscriptions against: trial ending ≤3d, next billing ≤1d, `previous_amount_minor` set (price changed, unacknowledged), and not-reviewed within `review_interval_days` (treating `created_at` as the initial review date when `last_reviewed_at` is null — stale detection compares `last_reviewed_at ?? created_at + interval`). Output is a sorted list capped at 3 for the Home card; "Review all" shows the full list. "Later" is a session-local hide (no extra column) per plan2_final §3.4. The service only scores ACTIVE subscriptions (cancelled/archived/pending-cancellation never enter the queue).
- **Alternatives considered:** a `snoozedUntil` column (rejected — plan2_final says session-local hiding is acceptable and simpler).
- **Rationale:** the queue is derived data over ≤ a few hundred rows; recomputing per build is trivial and keeps persistence minimal.

### D5: Savings Counter derived, not stored
Projected = monthly-equivalent of PENDING_CANCELLATION + CANCELLED (excluding superseded); Realized = for CANCELLED with `cancelled_at` in the past, count of completed billing cycles since `cancelled_at` (strictly before today, bounded loop) × amount-equivalent, per currency. Re-subscribe sets `superseded_at` on the old record when a new ACTIVE subscription matches the same name case-insensitively (`add()` in the list controller) — superseded rows stop both projected and realized contributions.
- **Alternatives considered:** persisting accumulated savings (rejected — derivable data invites drift; the plan requires recompute on transition anyway).
- **Rationale:** money stays integer-exact and always consistent with current state; the "estimated" label covers projection semantics.

### D6: Money Calendar computes dots for the visible month only
A `MoneyCalendarService` (consumed by `MoneyCalendarScreen`) takes a displayed month, walks active subscriptions, and uses the existing `BillingCalculator`/`DateUtils` projection to collect charge dates falling in that month — including occurrences earlier in the month (full-month view, not a forecast). One dot per day regardless of count; tapping a day lists renewals + per-currency total.
- **Alternatives considered:** precomputing a year of dots (rejected — plan2_final §6 performance rule), heatmap (rejected — v1 scope).
- **Rationale:** reuses the proven billing engine; O(subscriptions) per month render.

### D7: Price-change detection at edit time, confirmed in-app
In the add/edit flow, when an active subscription's `amountMinor` changes: write a `subscription_price_history` row (new price, effective today) and set `previous_amount_minor`; show the PRICE CHANGED summary (absolute + %, only when currency unchanged) as a confirm dialog before persisting. The dialog is **blocking**: dismissing it (Cancel) aborts the edit, so the new price is never silently saved; the user must confirm to persist.
- **Alternatives considered:** silent recording (rejected — the whole point of M2.5 is surfacing price increases).
- **Rationale:** keeps the edit form single-screen while adding one lightweight confirmation step.

## Risks / Trade-offs

- [Schema v2 on devices with existing v1 data] → additive ALTERs + migration test (v1 with seeded data → v2 preserves rows); `user_version` bumped only after success.
- [PENDING_CANCELLATION counting into free-tier may annoy users who cancel to dodge the paywall] → spec-required (plan2_final §5); the cancel flow still lets them archive, which does free a slot.
- [Derived savings could look "off" if billing dates are in the past for old cancellations] → Realized clamps to non-negative; copy always says "estimated".
- [Calendar dots for many weekly/custom subscriptions] → visible-month-only compute + one-dot-per-day cap keeps rendering bounded.
- [Import sets `last_reviewed_at = created_at`] → matches plan2_final §3.2; prevents fake stale backlog, verified by an import test.

## Migration Plan

1. Ship code with migration v2 (additive columns + new table). Existing installs upgrade in place on next `AppDatabase.open`; `flutter test` covers v1→v2.
2. No data backfill required — new columns are nullable/defaulted; `last_reviewed_at` for pre-existing rows is treated as unknown (falls into stale detection after 90 days, which is the desired behavior).
3. Rollback: the change is additive and non-destructive; downgrading just ignores the new columns (app code must tolerate nulls in `fromMap`).

## Open Questions

None — the locked execution spec answers the previously-open questions (transition trigger, re-subscribe savings, currency-change % exclusion, queue overload cap, calendar performance, paywall counting).
