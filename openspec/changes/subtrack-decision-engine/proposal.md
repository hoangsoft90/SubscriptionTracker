## Why

SubTrack v1 is a passive subscription database: it tracks what you pay but gives no reason to open the app daily. The locked execution spec v5.0 (`.plan/plan2_final.md`, M2.5) closes the biggest gap: **Action + Progress**. The app shifts from "these are your subscriptions" to "these are the payments needing your attention today — and here is how you can reduce them", while keeping the core promises: local-first, no AI, no backend, no gamification.

## What Changes

- **Today Money Brief** — the second card on Home (below Monthly Cost), replacing the old Upcoming card: "Nothing due today ✓" / next renewal with countdown / trial-ending warning.
- **Review Queue** — "Needs Attention" card on Home (max 3 items, rest behind "Review all"): trial ending ≤3d, renewal ≤1d, unreviewed >90d (stale), price-changed-unseen. In-app only (no duplicate notifications with Trial Shield). Import sets `last_reviewed_at = created_at` so restored data never creates a fake backlog.
- **Stale Subscription Detection** — subscriptions not reviewed in 90 days surface in the Review Queue with calm copy ("Haven't reviewed X in 7 months. Still worth it?").
- **Savings Counter** — Projected Savings (sum of monthly-equivalents of PENDING_CANCELLATION + CANCELLED) and Realized Savings (starts counting only after the billing date passes), always labeled "estimated". Re-subscribing to a cancelled subscription stops its Realized Savings (`superseded_at`).
- **Money Calendar (dot-only)** — month view with at most 1 dot per day; tapping a day shows that day's renewals + total. Renders dots only for the visible month (no yearly precompute, no color heatmap).
- **Price Change Detection + History** — editing `amountMinor` of an active subscription records the **new** price in `subscription_price_history` (effective today) and keeps the previous amount on the subscription; detects price change, computes % only when currency is unchanged, and shows a blocking confirmation card ("PRICE CHANGED +$4.00/month · +25%") before the edit is persisted.
- **`PENDING_CANCELLATION` lifecycle state** — new `SubscriptionStatus` value between ACTIVE and CANCELLED: user taps Cancel → opens `cancellationUrl` → status becomes PENDING_CANCELLATION → auto-transitions to CANCELLED inside `NotificationScheduler.reconcile()` when `nextBillingDate < today`. PENDING_CANCELLATION still counts toward the free 10-subscription paywall limit (only CANCELLED/ARCHIVED are exempt).
- **Schema migration v2** — new columns (`last_reviewed_at`, `review_interval_days`, `pending_cancellation`, `cancelled_at`, `previous_amount_minor`, `superseded_at`) + new `subscription_price_history` table (FK cascade, index).
- **Dashboard data layer** — DashboardState gains brief/queue/savings/calendar data; Home layout is capped at 4 cards in this order: Monthly Cost, Today, Needs Attention, Month total.

## Capabilities

### New Capabilities
- `decision-engine`: Today Money Brief, Review Queue (incl. stale detection + snooze), Savings Counter (projected/realized + re-subscribe supersede), and the Home "Money Command Center" layout rules.
- `money-calendar`: dot-only month calendar rendering renewals per day with per-day totals.
- `price-history`: price change detection rules (currency-change exclusion), history persistence, and the PRICE CHANGED confirmation flow.
- `subscription-lifecycle`: the 4-state lifecycle (ACTIVE → PENDING_CANCELLATION → CANCELLED → ARCHIVED), automatic state transition in `reconcile()`, and paywall counting for PENDING_CANCELLATION.

### Modified Capabilities
- (none — `openspec/specs/` is empty in this repo; all delta specs live in change directories and this change introduces new capability paths only)

## Impact

- **Code**: new `lib/features/decision/` (review queue, savings, today brief logic) + `lib/features/calendar/` (money calendar controller) — plus changes to `SubscriptionStatus` (new enum value), `Subscription` model (new fields), `subscription_repository.dart` (new queries/columns), `core/storage/migrations.dart` (v2 migration), `core/notifications/notification_scheduler.dart` (state-transition scan in `reconcile()`), `features/backup/import_service.dart` (set `last_reviewed_at` on import), `features/paywall/` (PENDING_CANCELLATION counted), and `features/dashboard/` (controller + Home screen).
- **Schema**: `PRAGMA user_version` 1 → 2 (new columns + `subscription_price_history` table, additive, non-destructive).
- **Dependencies**: `url_launcher` added (opens the cancellation URL in the Cancel flow / review actions); calendar built on existing Flutter widgets + `intl`; no network calls beyond the OS browser — all features work offline.
- **Tests**: new unit tests for review queue scoring, savings calc, state transition, price history + calendar dot projection; updated controller/widget tests; migration 1→2 data-preservation test.
