## Why

M0 delivered the domain core (Money, BillingCalculator, storage). A tracking app lives or dies on its UX: the locked spec's #1 uninstall risk is "app chỉ CRUD → uninstall". M1 builds the screens and flows that make SubTrack useful on day one — onboarding under 25 seconds, a Cost Shock dashboard with a visible Trial badge, fast add/edit flows, and search/filter — all reinforcing the privacy positioning.

## What Changes

- Onboarding flow (3 steps): Privacy Promise → primary currency selection (device-locale default, USD fallback) → preset catalog (global & VN packs).
- 3-tab navigation (Home / Subscriptions / More) via go_router.
- Home (Dashboard): Monthly + Yearly cost (Cost Shock), "5-Year Cost at Current Prices" (secondary), Upcoming renewals (next 7 days), red Trial badge, top-3 most expensive. *(Superseded by M2.5 `subtrack-decision-engine`: Home is now the 4-card Money Command Center — Monthly Cost, Today, Needs Attention, Month total; Upcoming/Top-3/5-year are no longer rendered.)*
- Subscription List + Add/Edit/Detail screens; add flow < 25s with "Free trial?" toggle in the primary step; status lifecycle ACTIVE/CANCELLED/ARCHIVED.
- Search / sort / filter over subscriptions.
- Categories: 11 defaults (seeded in M0) + user custom categories with emoji/color.
- Dark mode + empty states.
- Riverpod state management; all user-entered subscription names remain raw user data (never localized).

## Capabilities

### New Capabilities

- `onboarding`: Privacy Promise, primary-currency selection, preset catalog picker (global/VN), completion gating.
- `dashboard`: Cost Shock monthly/yearly totals, 5-year projection label, upcoming renewals, red trial badge, top-3 list, empty state.
- `subscriptions`: list/search/sort/filter, add/edit/detail flows (<25s), status lifecycle, trial toggle.
- `categories`: custom category CRUD layered on the 11 seeded defaults.
- `theme`: dark mode (system + manual) and empty states across screens.

### Modified Capabilities

- (none — M1 depends on M0 capabilities but adds no requirement changes to them)

## Impact

- **Code**: new `lib/features/*` UI, Riverpod providers, go_router routes (10 screens total across app), localization keys scaffold (EN/VI strings are wired in M2 but keys defined here).
- **Depends on**: M0 (subtrack-core-engine) — Money, BillingCalculator, repositories, seed data.
- **Dependencies**: `flutter_riverpod`, `go_router`, `intl`, `uuid` (already). Settings (onboarding-done flag, theme mode, primary currency) persist via the M0 `app_settings` table — no extra storage dependency.
- **Tests**: widget tests for onboarding gating, dashboard totals rendering, add-flow, search/filter, dark-mode toggle, empty states.
- **Privacy**: no analytics/crash SDKs; onboarding copy uses exact spec wording ("Subscription data is stored locally on your device. The app does not require a backend or account.").
