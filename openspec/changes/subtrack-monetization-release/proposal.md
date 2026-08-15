## Why

SubTrack is being readied for Play Store / App Store submission. Post-`subtrack-guidance` (2026-08-12), four areas needed work before release:

1. **Monetization** — AdMob ads were added (free tier only) but real units returned "No fill" and could be limited while the account is unapproved; the loaded banner also **collapsed the subscriptions list to zero height** (device-verified root cause), and the FAB "+" was overlapped by the banner.
2. **Multi-currency reporting** — the Home headline only summed the primary currency; subscriptions in other currencies were silently invisible. The list also rendered amounts as bare numbers with no currency code.
3. **Release infrastructure** — `com.subguard.app` already existed (taken), Google Play requires targetSdk 36 from 2026-08-31, the combined GH Actions workflow needed splitting into debug-APK (no keystore) and signed-AAB (keystore) jobs, and a privacy policy needed hosting (gh-pages).
4. **Display reliability** — the subscriptions tab could show a stale/empty list until restart (mutation racing the initial provider build), Home tab stayed empty after the first add, pull-to-refresh was missing on the subscriptions tab, and there was no notification-permission entry point in Settings.

## What Changes

- **Ads test mode by default** — `AdConfig.testAds` now defaults to `true` (Google sample ad IDs) so ads always fill and the real AdMob account is never limited while unapproved; flip with `--dart-define=TEST_ADS=false`. Interstitial frequency (every 5 adds) + 5-minute cooldown guard against rate limiting.
- **Banner layout fix** — the AdMob platform-view placeholder reports infinite height inside a Column, collapsing the `Expanded` list to h=0 (device root cause). `BannerAdView` now constrains `AdWidget` to the loaded `AdSize`; the banner also moved from the body `Column` into the Scaffold `bottomNavigationBar` slot so the FAB floats **above** it.
- **Multi-currency Home report** — exchange rates (units per 1 USD pivot) from a free live API (`open.er-api.com`) with a manual fallback editable in Settings. Home headline converts every active subscription to the primary currency (only when every currency has a rate — never truncates silently) plus a per-currency breakdown line; savings convert too. The subscriptions list shows the ISO code next to each amount.
- **Release infra** — package renamed `com.subguard.app` → `com.hoangsoft.subtrack` (Android namespace/applicationId/MainActivity, iOS bundle id, google-services.json); targetSdk 36 pinned; GH Actions split into `build-debug-apk.yml` (debug APK, no keystore, on push) and `build-release-aab.yml` (signed AAB from GitHub Secrets, manual); keystore pushed to repo secrets; privacy policy hosted on gh-pages.
- **Display reliability** — `SubscriptionListController.reload()` hardened null-safe (mutation racing the initial build can no longer crash / leave a stale list); `reload()` invalidates `dashboardControllerProvider` after every mutation (Home updates immediately); subscriptions list gained pull-to-refresh; Settings gained a notification-permission status + enable UI.

## Capabilities

### New Capabilities

- `ads-monetization`: test-ads default + real/sample ID resolution, interstitial frequency + cooldown policy, banner layout constraints (SizedBox AdSize), banner-in-bottomNavigationBar placement (FAB-safe).
- `multi-currency-report`: USD-pivot exchange-rate conversion (pure integer math), live fetch + manual fallback (Settings editor), converted Home headline + per-currency breakdown, currency codes in lists.
- `release-infra`: package rename, targetSdk 36, split GH Actions workflows (debug APK / signed AAB via secrets), privacy policy gh-pages hosting.
- `display-reliability`: null-safe reload, dashboard invalidation after mutations, pull-to-refresh on the subscriptions list, notification-permission Settings UI.

### Modified Capabilities

- (none — `openspec/specs/` is empty in this repo; all delta specs live in change directories.)

## Impact

- **Code**: `lib/core/money/exchange_rates.dart` (new — conversion math + live fetch), `lib/core/providers.dart` (exchange-rate providers + save helper), `lib/features/ads/` (ads_config, ads_controller, banner_ad_view), `lib/features/dashboard/` (controller + home_screen cost card), `lib/features/settings/presentation/settings_screen.dart` (exchange-rate editor + notification section), `lib/features/subscriptions/presentation/subscription_list_screen.dart` (currency code, pull-to-refresh), `lib/features/subscriptions/application/subscription_list_controller.dart` (null-safe reload), `lib/app/router/` (banner shell placement), Android/iOS platform config + package rename, `.github/workflows/` (2 files replacing 1).
- **Schema**: none (manual rates persisted as JSON in the existing `app_settings` key-value table).
- **Dependencies**: `http` added (live exchange-rate fetch).
- **Tests**: `test/exchange_rates_test.dart` (conversion math, defaults, live-fetch gating), `test/dashboard_controller_test.dart` (+3 multi-currency), `test/subscription_display_test.dart` (+currency code + refresh), `test/banner_layout_test.dart` (2 layout invariants), `test/ads_test.dart` (test-ads default), `test/ux_bugfix_widget_test.dart` (settings scroll with new section). Full suite 247/247 green, `flutter analyze` 0 issues.
