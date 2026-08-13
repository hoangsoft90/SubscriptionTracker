## Context

SubTrack is a local-first Flutter app (M0–M2.5 complete: exact-money core, billing engine, SQLite/localStorage repositories, dashboard, notifications, backup, paywall). The app has no in-product guidance, and a full post-launch code review (3 review passes + direct verification) found 7 real bugs in money display, backup, notification lifecycle and list layout. See proposal.md — Why for motivation.

## Goals / Non-Goals

**Goals:**
- A reusable, self-contained guidance toolkit (`lib/features/guidance/`) that any screen can opt into with a few lines — no coupling to specific screens.
- Show-once semantics persisted through the existing `app_settings` table (no new schema, no new dependency).
- Ship the 7 verified bugfixes with regression tests that would have caught each one.

**Non-Goals:**
- No tooltip manager for every existing screen — only the Home tour + FAB helper demo are wired.
- No shared_preferences or any new storage dependency (project rule #8).
- No change to the backup file format/schema version, notification scheduling algorithm, or billing calculations.
- No new notification content from guidance (guidance is purely in-app).

## Decisions

### D1: Guidance state lives in `app_settings` as comma-joined keys
`GuidanceController` (AsyncNotifier) persists two settings keys: `guidance.steps` and `guidance.tours`, each a comma-joined list of ids (same pattern as the existing `onboardingPresets`). `completeStep(stepId, {tourId, tourStepIds})` adds the step, persists, and — when every step of the owning tour is now complete — also marks the tour seen, so the controller needs no separate end-of-tour call.
- **Alternatives considered:** shared_preferences (rejected — project rule #8); a dedicated table (rejected — overkill for two string lists).
- **Rationale:** reuses the existing settings repository/provider wiring and the established comma-join convention; show-once and badge-clearing both fall out of one write path.

### D2: Tour orchestration via `GuidanceHost` + `GlobalKey`, tooltip geometry as a pure function
`GuidanceHost` wraps the app body, holds `GlobalKey`s for targets, measures target rects with `RenderBox.localToGlobal`, and inserts a `Stack` overlay entry per step. Position math lives in `tooltip_geometry.dart` as pure, unit-tested functions: prefer below → flip above → clamp to screen (with a guard when the tooltip is larger than the screen). `SpotlightOverlay` draws the dim + spotlight hole with `CustomPaint` (one transparent circle via `BlendMode.clear`) and renders the tooltip card + diamond arrow as siblings, so the card is hit-testable while the dimmed backdrop absorbs taps that advance the tour.
- **Alternatives considered:** `OverlayEntry` with `CompositedTransformFollower` (rejected — over-engineered for sequential steps; a Stack entry is simpler to test and dispose).
- **Rationale:** pure geometry is trivially testable; measuring from the target key at show-time keeps positioning correct after layout/animation settles.

### D3: `DisabledStateHelper` wraps the control instead of mutating it
The helper takes `enabled` + explanation copy and builds the child as-is. When enabled it passes taps through; when disabled it shows the explanation dialog on tap (the child itself renders its disabled state, e.g. `onPressed: null`). This keeps the helper composable around any existing widget.
- **Rationale:** zero changes to the wrapped widget's API; the dialog path is a single shared builder.

### D4: Monthly Cost = yearly ÷ 12, derived from the existing yearly projection
`DashboardController.monthlyTotal` changed from "sum of monthly-cycle amounts" to `yearlyTotal(currency) ~/ 12`, reusing the existing per-cycle yearly projection (weekly×52, monthly×12, quarterly×4, yearly×1, custom `amount×365 ~/ days` with the ≤0-days fallback). Integer `~/` keeps minor units exact; the small truncation for weekly/custom is a documented display approximation. `monthlyByCurrency` mirrors the same conversion. `_sumByCycle` was removed (dead after the change).
- **Alternatives considered:** per-cycle conversion tables (rejected — duplicates the yearly projection logic and drifts).
- **Rationale:** the headline and the Yearly row always agree (`monthly ≈ yearly ÷ 12`), and every cycle participates.

### D5: Category name resolution in the detail screen
`_DetailBody` became a `ConsumerWidget` that watches `categoryControllerProvider`, resolves `sub.categoryId` → `name`, and falls back to the existing `l10n.uncategorized` key (already in EN+VI ARBs) when the category is missing (possible via backup restore).
- **Rationale:** display concern, resolved at the presentation layer; no domain change.

### D6: Locale-aware short dates without intl formatting changes
`formatDate` takes `BuildContext` and branches on `Localizations.localeOf(context).languageCode == 'vi'` → `DD/MM`, else `MM/DD` (preserving the previous no-year, zero-padded format). English output is byte-identical to the old code, so existing widget tests/l10n strings did not break; Vietnamese now reads correctly.
- **Rationale:** minimal and deterministic for the app's EN/VI scope; no dependency on MaterialLocalizations date styles.

### D7: Notification reconcile after import — best-effort
`BackupScreen` calls `notificationCoordinatorProvider.onSubscriptionsChanged()` after `apply()`, wrapped in try/catch. The listener in `SubTrackApp._wireNotificationTriggers` may trigger a second reconcile when providers are invalidated afterwards — that is idempotent and converges (reconcile is cheap; a no-op pass is harmless).
- **Rationale:** matches the fire-and-forget reconcile pattern used elsewhere; a scheduling failure must never fail an already-applied import.

### D8: Lifecycle transition invalidates UI via the scheduler's update hook
`NotificationScheduler.updateSubscription` (wired in `core/providers.dart`) now also invalidates `subscriptionListControllerProvider` and `dashboardControllerProvider` after persisting a transition. Loop safety: the transition is one-shot (PENDING_CANCELLATION → CANCELLED), the listener-triggered second reconcile finds nothing to transition, so the invalidation settles.
- **Alternatives considered:** a callback/stream from the scheduler into controllers (rejected — the provider wiring is the single seam and keeps the scheduler a plain class).
- **Rationale:** the UI (list, dashboard, free-tier slot count) reflects lifecycle transitions without waiting for another user action.

## Risks / Trade-offs

- [Overlay may briefly measure a stale target rect during scroll/animation] → `GuidanceHost` re-measures via `markNeedsBuild` and falls back to a 1px rect rather than throwing.
- [Tooltip larger than the screen] → clamp guards avoid `clamp(min>max)` crashes; content scrolls within the card.
- [monthlyTotal truncation (weekly/custom) makes monthly×12 ≠ yearly] → documented display approximation; money arithmetic itself stays integer-exact.
- [Second reconcile after import / after transition] → idempotent by design (reconcile recomputes the same schedule); no state drift.
- [`formatDate` non-vi fallback = MM/DD] → intentional for the EN/VI-only app; any future locale re-visits this.
- [Tour only runs when target cards exist (≥1 active subscription)] → empty Home shows no tour; it will offer again once data exists (show-once is per completed step, not per view).
