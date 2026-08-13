## 1. App shell & navigation

- [x] 1.1 Add dependencies: `flutter_riverpod`, `go_router` (settings persist via M0 `app_settings` table — no shared_preferences)
- [x] 1.2 Create `app.dart` with MaterialApp (themeMode from settings), `router.dart` with StatefulShellRoute (3 tabs), theme light/dark
- [x] 1.3 Wire Riverpod ProviderScope at root; create `OnboardingController` (completion flag + primary currency from device locale with USD fallback)
- [x] 1.4 Route gate: show Onboarding until completed, then shell; widget test for gating

## 2. Onboarding

- [x] 2.1 Privacy Promise screen (exact spec copy; no permissions requested)
- [x] 2.2 Currency selection step (device-locale default; changeable)
- [x] 2.3 Preset catalog step: global + VN packs as const data (`Preset` model: displayNameKey, category, icon, cancellationUrl?, trialDurationSuggestionDays?)
- [x] 2.4 Persist completion + primary currency; test: relaunch skips onboarding; locale fallback USD

## 3. Subscriptions CRUD

- [x] 3.1 Subscriptions list screen: cards with icon/category chip/status chip, FAB add
- [x] 3.2 Add/Edit form (shared): name, amount (Money parse by currency decimals), cycle picker, dates, "Free trial?" toggle in primary step (trialEndDate vs nextBillingDate independent), notes, cancellation URL (category is preset pre-fill only — no standalone category picker in the form)
- [x] 3.3 Detail screen: all fields, status actions (cancel/archive/activate), delete with confirmation
- [x] 3.4 Preset pre-fill wiring (no price/cycle forced; trial hint "Suggested, please verify")
- [x] 3.5 Search (case-insensitive name), sort (name/amount/next billing), filter (status; category filter in controller/data, no UI control)
- [x] 3.6 `SubscriptionListController` (Riverpod) with CRUD actions via M0 repository
- [x] 3.7 Widget tests: add flow <25s path, edit preserves untouched fields, delete confirmation, search/filter

## 4. Dashboard (Home)

- [x] 4.1 `DashboardController`: totals (grouped by currency), 5-year secondary figure, upcoming 7 days, top-3, trial badges (computed with M0 helpers)
- [x] 4.2 Home screen: Cost Shock monthly/yearly headline, "5-Year Cost at Current Prices" secondary, Upcoming list, Top-3, red trial badges
- [x] 4.3 Empty state with CTA; widget tests: totals exclude cancelled/archived, upcoming window 7 days, top-3 ranking

> **Note (M2.5 `subtrack-decision-engine`):** the Upcoming/Top-3/5-year Home
> cards were replaced by the 4-card Money Command Center layout; the M2.5
> change supersedes the rendered Home output but the controller helpers above
> remain part of the M1 implementation history.

## 5. Categories & settings

- [x] 5.1 Category management screen: 11 defaults (non-deletable) + custom CRUD (name/emoji/color), deletion unassigns or prompts replacement
- [x] 5.2 Category assignment in add/edit (pre-fill + saved field); detail screen shows the category as text (no icon/color chip on list/detail in M1)
- [x] 5.3 More tab + Settings: change primary currency (no historical conversion), theme mode override (system/light/dark)
- [x] 5.4 Widget tests: default category protected, custom category delete reassigns safely, currency change regroups dashboard

## 6. Theme, i18n keys & accessibility

- [x] 6.1 Dark mode (ThemeMode from settings, persisted) across all screens
- [x] 6.2 Reusable EmptyState widget on dashboard/list/search
- [x] 6.3 Accessibility: semantic labels on icon buttons, contrast check in dark mode
- [x] 6.4 Localization keys scaffold (EN strings; `AppLocalizations` structure ready for M2 VI wiring); verify user-entered names never localized
- [x] 6.5 Widget tests: dark mode applies and persists, empty states render, a11y labels present

## 7. Verification

- [x] 7.1 `flutter analyze` — no issues
- [x] 7.2 `flutter test` — full suite green (M0 + M1)
- [ ] 7.3 Manual walkthrough: add from empty state <25s, dashboard totals match list, trial badge shows for active trial only *(still open — requires device/simulator)*
