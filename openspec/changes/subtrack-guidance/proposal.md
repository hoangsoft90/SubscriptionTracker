## Why

New users of SubTrack land on a dense Home dashboard and a list with a free-tier limit they don't yet understand. Post-launch review also surfaced correctness bugs in money display, backup, and notification lifecycle that undermine trust. This change adds **In-app Guidance & User Onboarding** so first-run users learn the key screens (and why a button is disabled), and hardens the reviewed areas with a set of verified bugfixes.

## What Changes

- **FeatureBadge** — a small dot / "New" label overlaid on the corner of any element (icon, button, card), visible only until the associated guidance step has been seen; disappears forever once seen (no repeat spam).
- **Spotlight & Tooltip** — a full-screen overlay that dims the background, cuts a spotlight "hole" around a target element (via `GlobalKey`), and renders a positioned tooltip card with title/body and **Skip / Next / Done** actions. Tooltip position is computed responsively: preferred below the target, flips above when there is no room, clamped to the screen, and flipped left/right for side placements. Tapping the dimmed backdrop advances to the next step.
- **DisabledStateHelper** — wraps a disabled control (e.g. the free-tier-blocked FAB); tapping it shows a short dialog explaining *why* it is disabled and *how* to unlock it, with an optional action button (e.g. "Unlock Pro").
- **GuidanceHost + GuidanceController (state)** — an orchestrator that runs a sequential tour (Step 1 → Step 2 → Finish) over `GlobalKey` targets; completion state (`guidance.steps`, `guidance.tours`) persists in the **`app_settings` table** (project rule: no `shared_preferences`). Tours show **once** per user (seen-tour ids); Skip marks every step complete so badges clear and the tour never re-triggers.
- **Wire demo**: a 2-step first-run tour on Home (Monthly Cost card → View calendar) with a "New" badge on the calendar card; the Subscriptions list FAB is wrapped in `DisabledStateHelper` when the free-tier hard block (11+ subscriptions) applies.
- **Review bugfixes (7)** — documented as capability `review-bugfixes`:
  1. Backup **Replace All** now wipes subscriptions before categories (FK order, `PRAGMA foreign_keys = ON`) — previously crashed on real sqlite.
  2. Home **Monthly Cost** is now the monthly-equivalent of *every* cycle (`yearly ÷ 12`), not just monthly-cycle subscriptions.
  3. Subscription **detail screen shows the category name**, resolved via the category controller (fallback "Uncategorized"), not the raw id/slug/UUID.
  4. **Date formatting is locale-aware** (`DD/MM` for Vietnamese, `MM/DD` otherwise) — was hard-coded MM/DD.
  5. **Backup import triggers notification reconcile** so stale reminders for replaced/removed rows are cancelled immediately (best-effort).
  6. The scheduler's automatic `PENDING_CANCELLATION → CANCELLED` transition now **invalidates the list + dashboard providers** so the UI reflects it without waiting for another data change.
  7. **StatusChip ellipsizes** inside a constrained width so long labels ("Pending cancellation") no longer overflow the list tile.

## Capabilities

### New Capabilities
- `in-app-guidance`: FeatureBadge, Spotlight & tooltip overlay (responsive positioning), DisabledStateHelper, GuidanceHost tour orchestration, and the `app_settings`-backed show-once persistence rules.
- `review-bugfixes`: the seven post-review correctness requirements above (FK-safe replace-all, monthly-equivalent totals, category-name resolution, locale-aware dates, import reconcile, lifecycle UI invalidation, chip overflow).

### Modified Capabilities
- (none — `openspec/specs/` is empty in this repo; all delta specs live in change directories and this change introduces new capability paths only)

## Impact

- **Code**: new `lib/features/guidance/` (domain `GuidanceStep`, application `GuidanceController`, presentation `feature_badge.dart`, `spotlight_overlay.dart`, `tooltip_geometry.dart`, `disabled_state_helper.dart`, `guidance_host.dart`) + l10n keys `guidance*`, `featureNew`, `disabledFreeLimit*` (EN+VI, ARB). Wire: `home_screen.dart` (tour + badge), `subscription_list_screen.dart` (DisabledStateHelper FAB).
- **Bugfix files**: `backup/import_service.dart`, `backup/presentation/backup_screen.dart`, `dashboard/application/dashboard_controller.dart`, `subscriptions/presentation/subscription_detail_screen.dart`, `subscriptions/presentation/subscription_list_screen.dart`, `core/notifications/notification_scheduler.dart` (via `core/providers.dart` wiring).
- **Schema**: none (guidance state reuses the existing `app_settings` key-value table).
- **Dependencies**: none added.
- **Tests**: `test/guidance_test.dart` (19 tests: tooltip geometry, controller persistence/show-once, all three components, tour flow, skip clears steps); `test/subscription_detail_test.dart` (category-name resolution + fallback); FK regression on real sqlite, monthly-equivalent total test, updated CRUD widget test. Full suite 203/203 green, `flutter analyze` 0 issues.
