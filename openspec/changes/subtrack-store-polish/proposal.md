## Why

After `subtrack-monetization-release` (2026-08-15) landed the release infrastructure, the app still needed store-facing polish and a final code-quality pass before Play Store / App Store submission:

1. **Store listing assets** — the privacy policy mentioned the GitHub repository (undesirable for a store-facing policy), and the store listing was missing a proper feature graphic. The app icon (512×512) existed but needed verification.
2. **Banner placement** — the AdMob banner sat in each tab's inner Scaffold `bottomNavigationBar`, floating loosely between content and the shell's `NavigationBar` with a bottom SafeArea gap — visually "chênh vênh", not flush with the nav buttons.
3. **Code review findings** — a full codebase review (83 files) found three real issues: the paywall showed backup-error copy on purchase/restore failure, the paywall "slots used" count disagreed with the add-form gate (ACTIVE vs ACTIVE + PENDING_CANCELLATION), and the exchange-rate editor showed a hardcoded English error instead of a localized one.

## What Changes

- **Store assets + privacy policy** — the privacy policy (EN + VI, markdown + HTML) no longer references the GitHub repository: the Contact section uses the support email (`haibasoftware@gmail.com`, updated from the earlier `hoangsoft90@gmail.com`). Redeployed to gh-pages. Verified `icon.png` is 512×512 and added `feature-graphic.png` (1024×500) generated from the app's icon brand (teal gradient, white card, "SubTrack" title + tagline + feature bullets).
- **Banner flush with the nav bar** — the banner moved from each tab's inner Scaffold into the app shell's `bottomNavigationBar` as a `Column [BannerAdView, NavigationBar]`, so it sits directly on top of the nav buttons on every tab. `BannerAdView` no longer applies a bottom `SafeArea` (the NavigationBar below already consumes the system inset), removing the gap. Removed the now-unused banner code from the Home and Subscriptions screens.
- **Code-review bugfixes** — paywall purchase/restore failure now shows a proper localized error (`paywallError` EN+VI) instead of "This file is not a SubTrack backup."; the paywall "N of 10 slots used" counter uses `paywallSlotCount` (ACTIVE + PENDING_CANCELLATION) so it always matches the add-form hard-block; the exchange-rate editor's invalid-input error is localized (`settingsExchangeRatesInvalid` EN+VI).

## Capabilities

### New Capabilities

- `store-assets-privacy`: GitHub-free privacy policy (email contact) hosted on gh-pages, 512×512 app icon verified, 1024×500 feature graphic generated from the brand.
- `banner-shell-placement`: banner rendered once in the app shell directly above the NavigationBar (flush, no SafeArea gap), removed from per-tab Scaffolds.
- `review-bugfixes`: paywall error copy, paywall slots-used consistency with the add gate, localized exchange-rate validation error.

### Modified Capabilities

- (none — `openspec/specs/` is empty in this repo; all delta specs live in change directories.)

## Impact

- **Code**: `lib/app/router/app_router.dart` (shell bottomNavigationBar Column), `lib/features/ads/presentation/banner_ad_view.dart` (no SafeArea), `lib/features/dashboard/presentation/home_screen.dart` + `lib/features/subscriptions/presentation/subscription_list_screen.dart` (banner removed), `lib/features/paywall/presentation/paywall_screen.dart` (error copy + slots count), `lib/features/settings/presentation/settings_screen.dart` (localized rate error), `lib/core/l10n/app_en.arb` + `app_vi.arb` + generated `lib/l10n/` (2 new keys), `docs/privacy-policy.md` + `.html`, `feature-graphic.png` (new).
- **Schema**: none.
- **Dependencies**: none.
- **Tests**: no new test files (existing suite covers the touched behavior — `banner_layout_test.dart` pins the layout invariant, l10n regenerated without breaking any test). Full suite 247/247 green, `flutter analyze` 0 issues.
