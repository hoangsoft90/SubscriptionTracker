> Retrospective change: the implementation below is already shipped (2026-08-12). Tasks are recorded as completed against the live codebase; verification numbers reflect the final state.

## 1. Guidance domain + state

- [x] 1.1 `domain/guidance_step.dart`: pure-Dart `GuidanceStep` (id, targetKey, title, body) + `GuidancePlacement` enum (auto/top/bottom/left/right) + `GuidanceLabels`/`GuidanceState` types — no Flutter imports (feature-first layering)
- [x] 1.2 `application/guidance_controller.dart`: `AsyncNotifier` reading/persisting `guidance.steps` + `guidance.tours` (comma-joined) in `app_settings` via `SettingsRepository` — same pattern as `onboardingPresets`
- [x] 1.3 Controller API: `hasCompletedStep`, `shouldShowTour`, `completeStep(stepId, {tourId, tourStepIds})` (marks tour seen when all its steps done), `markTourSeen` — typed `SettingsRepository` (no `dynamic`)

## 2. Guidance UI components

- [x] 2.1 `presentation/feature_badge.dart`: `FeatureBadge` overlay dot/"New" label (l10n) anchored top-right of any child, `visible` driven by guidance state; `clipBehavior: Clip.none`
- [x] 2.2 `presentation/tooltip_geometry.dart`: pure responsive placement (prefer below → flip above → clamp to screen, side placements left/right, guard when tooltip > screen) — unit-tested
- [x] 2.3 `presentation/spotlight_overlay.dart`: self-contained `Stack` + `CustomPaint` dim/spotlight-hole, tooltip card + diamond arrow siblings, backdrop tap advances, Skip/Next/Done + step counter
- [x] 2.4 `presentation/disabled_state_helper.dart`: wrap disabled control; tap → dialog with reason + unlock condition + optional action (e.g. Unlock Pro → paywall); inert when enabled
- [x] 2.5 `presentation/guidance_host.dart`: orchestrator — `GlobalKey` target measurement, sequential steps, re-show via `markNeedsBuild`, 1px fallback rect, `_skip()` completes every step (clears badges) + marks tour seen
- [x] 2.6 L10n: add `guidanceSkip/Next/Done/StepCounter`, `guidanceHomeCost*`, `guidanceHomeCalendar*`, `featureNew`, `disabledFreeLimit*` keys to `app_en.arb` + `app_vi.arb`; run `flutter gen-l10n`

## 3. Wire demo + tests

- [x] 3.1 Home: wrap body in `GuidanceHost` (tour `firstRunHome`, steps: Cost card → View calendar), `GlobalKey` targets, `FeatureBadge` "New" on calendar card (hidden once `home.calendar` step seen)
- [x] 3.2 Subscriptions list: FAB wrapped in `DisabledStateHelper` when free-tier hard block (11+) — disabled look + explanation + Unlock Pro
- [x] 3.3 `test/guidance_test.dart`: 19 tests — tooltip geometry, controller persistence/show-once, FeatureBadge, DisabledStateHelper dialog, SpotlightOverlay, tour flow, skip-clears-steps

## 4. Review bugfixes (7)

- [x] 4.1 FK-safe Replace All: `backup/import_service.dart` `_applyReplace` wipes subscriptions before categories; regression test on real in-memory sqlite (`test/backup_test.dart`) — fake repos don't enforce FK
- [x] 4.2 Monthly-equivalent headline: `dashboard_controller.dart` `monthlyTotal = yearlyTotal ~/ 12` + `monthlyByCurrency` synced, `_sumByCycle` removed; dashboard tests updated + monthly-equivalent test added
- [x] 4.3 Category display name: `subscription_detail_screen.dart` `_DetailBody` → ConsumerWidget resolving name via `categoryControllerProvider`, fallback `l10n.uncategorized`; new `test/subscription_detail_test.dart` (name + fallback) + CRUD widget test updated
- [x] 4.4 Locale-aware dates: `formatDate(BuildContext, DateTime)` — `vi` → DD/MM, else MM/DD (EN output unchanged); callers in list + detail updated
- [x] 4.5 Import reconcile: `backup_screen.dart` calls `onSubscriptionsChanged()` after apply (try/catch, best-effort)
- [x] 4.6 Lifecycle UI refresh: `core/providers.dart` `updateSubscription` hook invalidates list + dashboard providers after the automatic PENDING_CANCELLATION → CANCELLED transition (converges: transition is one-shot)
- [x] 4.7 StatusChip overflow: chip text `maxLines: 1` + ellipsis; tile trailing `ConstrainedBox(maxWidth: 110)`

## 5. Verification

- [x] 5.1 `flutter analyze` — 0 issues
- [x] 5.2 `flutter test` — 203/203 pass (199 before + 4 new: FK regression, monthly-equivalent, 2 detail widget tests)
- [x] 5.3 Code review (code-reviewer) — 2 follow-ups addressed: price-history FK verified as `ON DELETE CASCADE` (no deeper crash); import reconcile wrapped in try/catch so notification failures never block import UX
- [x] 5.4 Update `.project/working.md` per project conventions
