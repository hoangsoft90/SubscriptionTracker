## 1. Schema migration v2

- [x] 1.1 Add `Migration(2, _migrationV2)` in `lib/core/storage/migrations.dart`: additive `ALTER TABLE subscriptions ADD COLUMN` for `last_reviewed_at` (TEXT), `review_interval_days` (INTEGER DEFAULT 90), `pending_cancellation` (INTEGER DEFAULT 0), `cancelled_at` (TEXT), `previous_amount_minor` (INTEGER), `superseded_at` (TEXT)
- [x] 1.2 Add `subscription_price_history` table (id, subscription_id, amount_minor, currency, effective_from, created_at, FK cascade ON DELETE, index `idx_price_history_sub`) in the same v2 migration
- [x] 1.3 Extend `Subscription` model (`fromMap`/`toMap`/`copyWith`): `lastReviewedAt`, `reviewIntervalDays`, `pendingCancellation` (derived from status), `cancelledAt`, `previousAmountMinor`, `supersededAt`; register `PENDING_CANCELLATION` in `SubscriptionStatus`
- [x] 1.4 Migration test: seed a v1 database with data → run migrations → v2 data preserved, new columns present, `user_version = 2`
- [x] 1.5 Run `flutter analyze` + targeted `flutter test test/data_storage_test.dart` — green

## 2. Lifecycle: PENDING_CANCELLATION state machine

- [x] 2.1 Extend `SubscriptionStatus` enum with `pendingCancellation('PENDING_CANCELLATION')` and wire `fromDb`
- [x] 2.2 Add cancel action in `subscription_detail_screen.dart`: opens `cancellationUrl` (when present) then sets status to pendingCancellation
- [x] 2.3 Extend `NotificationScheduler.reconcile()`: scan PENDING_CANCELLATION subs with `nextBillingDate < today` → transition to CANCELLED, set `cancelled_at = nextBillingDate`, persist
- [x] 2.4 Update paywall counting (`free_tier.dart` / entitlement logic) so PENDING_CANCELLATION counts toward the free 10 limit; only CANCELLED/ARCHIVED are exempt
- [x] 2.5 Unit tests: cancel flow, auto-transition in reconcile, paywall counting with pending-cancellation subs

## 3. Review Queue + stale detection

- [x] 3.1 New `ReviewQueueService` (pure scoring): trial ending ≤3d (high), next billing ≤1d (high), price changed & unacknowledged (`previousAmountMinor != null`) (medium), last reviewed > `review_interval_days` (medium); sorted by priority
- [x] 3.2 Cap Home card at 3 items; "Review all (N)" reveals the rest; "Later" hides item for the session (no new column)
- [x] 3.3 Review actions in UI: Keep → `lastReviewedAt = today`; Cancel → opens URL + pendingCancellation; Later → session hide
- [x] 3.4 Import service: set `last_reviewed_at = created_at` for every imported subscription (merge + replace)
- [x] 3.5 Unit tests: priority ordering, cap-at-3, stale detection boundary (90d), import no-fake-backlog, Keep/Later behavior

## 4. Today Money Brief

- [x] 4.1 Compute brief data: no-event-empty / next renewal (name, amount, "in N days" + date) / trial-ending warning (≤3d, post-trial price) — calendar-local dates
- [x] 4.2 Replace old Upcoming card with the Today Brief card as the first card on Home
- [x] 4.3 Unit + widget tests: "Nothing due today", next-renewal countdown, trial warning, timezone-independent local-date compute

## 5. Savings Counter

- [x] 5.1 Projected Savings: monthly-equivalent sum of PENDING_CANCELLATION + CANCELLED (excluding superseded)
- [x] 5.2 Realized Savings: for CANCELLED with `cancelled_at` in the past, elapsed cycles since cancellation (non-negative), shown with "estimated" label
- [x] 5.3 Re-subscribe rule: creating an active sub matching a CANCELLED sub name (case-insensitive) sets `superseded_at` on the old record and stops its Realized contribution
- [x] 5.4 Dashboard: show savings card (projected + realized) + monthly cost reduction (current vs pre-cancellation)
- [x] 5.5 Unit tests: projected sum, realized timing boundary, supersede-on-resubscribe, mixed currencies grouped

## 6. Money Calendar (dot-only)

- [x] 6.1 New `MoneyCalendar` controller: for a displayed month, compute charge days of active subs via `BillingCalculator`/`DateUtils` (visible month only)
- [x] 6.2 Month grid UI: one dot per day (max 1 regardless of count), no heatmap; tap day → renewals list + per-currency total
- [x] 6.3 Wire "View calendar" entry from the Home month card; back navigation returns to Home
- [x] 6.4 Unit + widget tests: dot placement (anchor-day clamp, weekly/custom), one-dot-per-day, empty day detail, per-currency totals

## 7. Price Change Detection + History

- [x] 7.1 On edit of an active sub's `amountMinor`: write `subscription_price_history` row (new price, effective today), set `previous_amount_minor`
- [x] 7.2 PRICE CHANGED confirm dialog in add/edit flow: absolute + % change and new yearly cost; % only when currency unchanged (currency change → record history only, no comparison)
- [x] 7.3 Repository: `insertPriceHistory` + cascade delete with subscription; history read for detail screen
- [x] 7.4 Unit tests: price-change detection, currency-change exclusion, history persistence, cascade delete

## 8. Dashboard layout + verification

- [x] 8.1 Cap Home at the 4-card layout (Monthly Cost, Today, Needs Attention, Month total + View calendar); remove old Upcoming/Top-3 cards
- [x] 8.2 Update `dashboard_controller.dart` state to feed brief, queue (capped), savings, month total; keep empty-state CTA when no subs
- [x] 8.3 L10n: add EN + VI strings for all new UI (today brief, queue, savings, calendar, price change)
- [x] 8.4 Run `flutter analyze` — no issues
- [x] 8.5 Run `flutter test` — full suite green (new + existing tests, incl. controller/widget tests for dashboard)
- [x] 8.6 Verify all new features work offline (no new network calls) — dependency/import audit in `pubspec.yaml` unchanged
