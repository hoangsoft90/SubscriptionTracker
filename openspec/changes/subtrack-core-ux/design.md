## Context

M0 delivered Money, BillingCalculator, repositories and the seeded SQLite schema (see proposal.md — Why for motivation). M1 turns that into the app surface: onboarding, Home dashboard, subscription CRUD, search/filter, categories and theming. No existing UI code; routing and state management are introduced here.

## Goals / Non-Goals

**Goals:**
- Onboarding gating (privacy → currency → presets) with device-locale currency default.
- 3-tab navigation with Home Cost Shock dashboard (monthly/yearly, 5-year secondary, upcoming 7 days, red trial badge, top-3).
- Fast add/edit/detail flows with trial toggle in primary step; search/sort/filter; status lifecycle.
- Custom categories over the 11 seeds; dark mode; empty states; accessibility basics.
- All currency display via `Money.format()` (intl) — never raw ints in widgets.

**Non-Goals:**
- No notifications (M2 — trial-shield notification firing, permission timing).
- No backup/import/transfer (M2).
- No IAP/paywall (M2).
- No full i18n wiring (M2); M1 defines localization keys and structure so M2 can wire EN/VI.
- No multi-currency conversion.

## Decisions

### D1: go_router with a stateful shell
3 tabs via `StatefulShellRoute.indexedStack` (Home / Subscriptions / More) plus pushed routes for Add/Edit/Detail/Onboarding. 10 screens total (per spec §6 IA).
- **Alternatives considered:** auto_route (codegen — rejected, extra build step); Navigator 1.0 (rejected — deep-link/deeplink and nested nav get messy for onboarding gate).
- **Rationale:** go_router is in the locked dependency list; indexedStack preserves tab state (scrolling, search input) across tab switches.

### D2: Riverpod (flutter_riverpod) for state
`NotifierProvider`s: `OnboardingController` (completes onboarding, sets primary currency), `SubscriptionListController` (loads from repository, exposes search/sort/filter state, CRUD actions), `CategoryController`, `SettingsController` (theme mode + primary currency), `DashboardController` (computes totals/projection/upcoming/top-3 via BillingCalculator + repositories).
- **Alternatives considered:** Bloc (rejected — heavier boilerplate for this app size); setState + manual DI (rejected — cross-screen state like totals after edit needs shared state).
- **Rationale:** Riverpod is in the locked stack; repository interfaces from M0 slot in as constructor dependencies (testable via provider overrides).

### D3: Single source of truth for currency formatting
All widget formatting goes through `Money.format(locale)`; dashboard grouping uses the `sumByCurrency` helper from M0 + primary currency from settings for the headline number.
- **Rationale:** keeps the int-only invariant visible at the boundary; M2 backup/CSV will reuse the same formatter.

### D4: Preset catalog is data, not code
`Preset` model per spec §6: `displayNameKey` (localization key, resolved via intl), `category`, `icon`, `cancellationUrl?` (validated), `trialDurationSuggestionDays?` labelled "Suggested, please verify". Two packs (global/VN) shipped as const data lists. Picking a preset pre-fills the add form; price/cycle are never preset.
- **Alternatives considered:** hard-coding prices/cycles (rejected — spec forbids: prices/trials vary by market).
- **Rationale:** presets remain user-editable by construction since they only pre-fill.

### D5: Dashboard computations as pure helpers over repositories
`DashboardController` reads active subscriptions once, then uses M0's projection helpers + date comparisons (local-midnight "today") to build: monthly/yearly totals (grouped by currency), 5-year secondary figure, upcoming (next 7 days sorted), top-3, trial badges. No new business logic — pure aggregation.
- **Rationale:** keeps billing invariants in the tested M0 calculator; dashboard is a thin projection.

### D6: Theme mode via ThemeMode + app_settings
`SettingsController` persists `themeMode` (system/light/dark) and the onboarding-completed flag in the `app_settings` table (M0) through `SettingsRepository`; `MaterialApp.themeMode` consumes the value. Empty states as reusable widgets (`EmptyState`).
- **Alternatives considered:** `shared_preferences` (rejected — would add a second storage path when the M0 `app_settings` table already exists and is the single settings source).
- **Rationale:** one storage path for all settings (theme, onboarding, primary currency, later locale/Pro entitlement); keeps state queryable and consistent with `SettingsRepository`.

**Project layout (additions to M0):**
```
lib/
  app.dart, router.dart, theme.dart
  features/onboarding/ (screens, controller, presets/)
  features/dashboard/ (home_screen, widgets/, controller)
  features/subscriptions/ (list, detail, add_edit screens, controller)
  features/categories/ (manage screen, controller)
  features/settings/ (more_tab, settings_screen)
  core/l10n/ (keys scaffold — full EN/VI in M2)
```

## Risks / Trade-offs

- [Add-flow friction kills the 25s target] → presets pre-fill; trial toggle visible in primary step; keyboard types optimized (number pad for amounts); QA walkthrough in DoD.
- [Dashboard totals diverge from list] → both read the same repository snapshot through Riverpod; widget tests assert totals after edit/delete.
- [Dark-mode contrast issues] → theme uses Material 3 color scheme from seed; contrast checked in the accessibility scenario.
- [Tab state lost on navigation] → indexedStack shell preserves it; verify with widget tests.
- [Scope creep into notifications/backup] → explicitly out of M1 scope; tasks stop at theming.

## Migration Plan

N/A — UI layer on top of M0 schema; no schema change in M1. (Settings rows for theme/onboarding are plain `app_settings` upserts, no migration.)

## Open Questions

None — screens, flows and copy constraints are locked in the execution spec. Language keys are scaffolded but wiring is deferred to M2 by design.
