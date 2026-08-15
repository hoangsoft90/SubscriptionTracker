> Retrospective change: the implementation below is already shipped (2026-08-12 → 2026-08-15). Tasks are recorded as completed against the live codebase; verification numbers reflect the final state.

## 1. Ads monetization (test mode + interstitial policy + banner layout)

- [x] 1.1 `ads_config.dart`: `testAds = bool.fromEnvironment('TEST_ADS', defaultValue: true)` — test ads ON by default (avoid AdMob limiting the real account while unapproved); sample IDs for banner/interstitial/rewarded/app; production flips with `--dart-define=TEST_ADS=false`
- [x] 1.2 `ads_controller.dart`: pure `shouldShowInterstitial` (frequency every 5 adds + 5-min cooldown via `AdConfig.interstitialCooldown`); controller tracks `_lastShownAt`, preloads after each add, holds back in-cooldown shows; all failures silent
- [x] 1.3 `banner_ad_view.dart`: wrap `AdWidget` in `SizedBox(width, height)` with the loaded `AdSize` — stops the platform-view placeholder's infinite-height from collapsing sibling `Expanded` widgets (device-verified root cause)
- [x] 1.4 Move banner from body `Column` to Scaffold `bottomNavigationBar` on Home + Subscriptions — FAB "+" floats above it, never overlapped
- [x] 1.5 Tests: `test/ads_test.dart` (interstitial policy 6 tests + test-ads default), `test/banner_layout_test.dart` (2 layout invariants: unconstrained ad slot collapses the list; SizedBox-constrained keeps it)

## 2. Multi-currency report

- [x] 2.1 `lib/core/money/exchange_rates.dart` (new): rates as units-per-1-USD pivot; `convertMinorToPrimary` (exact integer minor math, null on missing/non-positive rate), `sumConvertedTo`, `fetchLiveRates` (open.er-api.com, 6s timeout, empty map on failure), `defaultManualExchangeRates` (USD/EUR/GBP/VND/JPY/KRW), `canFetchLive` false under `FLUTTER_TEST`/web
- [x] 2.2 `providers.dart`: `exchangeRatesProvider` (live wins, manual fallback), `manualExchangeRatesProvider`, `saveManualExchangeRates` (JSON in `app_settings` under `exchangeRates`)
- [x] 2.3 `dashboard_controller.dart`: `monthlyTotalConverted` / `yearlyTotalConverted` / `allActiveConvertible` / `savingsConverted`
- [x] 2.4 `home_screen.dart` `_CostCard`: converted headline (only when every active currency has a rate — else primary-only fallback, never truncated silently) + "≈ converted" note + per-currency breakdown Wrap (ISO codes); savings convert too
- [x] 2.5 `settings_screen.dart` `_ExchangeRatesSection`: manual "1 USD = X" editor for EUR/GBP/VND/JPY/KRW, saves via `saveManualExchangeRates`, invalidates both providers
- [x] 2.6 `subscription_list_screen.dart`: tile `MoneyText` gets `currencyCode: true` (maxWidth 110→140) — list never shows a bare number
- [x] 2.7 L10n: `dashboardConvertedNote` + `settingsExchangeRates*` keys (EN + VI, ARB) + `flutter gen-l10n`
- [x] 2.8 Dependency: `http ^1.5.0` (live fetch)
- [x] 2.9 Tests: `test/exchange_rates_test.dart` (conversion via pivot, missing-rate null, sumConvertedTo, defaults, canFetchLive gating), `test/dashboard_controller_test.dart` +3 (converted totals, not-all-convertible fallback, converted savings), `test/subscription_display_test.dart` +1 (currency code shown)

## 3. Release infrastructure

- [x] 3.1 Package rename `com.subguard.app` → `com.hoangsoft.subtrack` (user-chosen via ask_user — old package already exists): `build.gradle.kts` namespace + applicationId; `MainActivity.kt` moved to `com/hoangsoft/subtrack/`; iOS `PRODUCT_BUNDLE_IDENTIFIER` 6 spots (`com.hoangsoft.subtrack` + `.RunnerTests`); `google-services.json` package_name; `integration_test/device_ux_test.dart` `adb pm clear` comment; `ads_config.dart` + manifest comments note AdMob re-registration requirement for the new package
- [x] 3.2 `targetSdk = 36` pinned in `android/app/build.gradle.kts` (Play requirement from 2026-08-31)
- [x] 3.3 `.github/workflows/build-debug-apk.yml` (new): debug APK only, no keystore, push main + manual
- [x] 3.4 `.github/workflows/build-release-aab.yml` (new): signed release AAB, manual only, keystore from secrets (`ANDROID_KEYSTORE_BASE64` → `android/keystore/subtrack-release.jks`, writes `android/key.properties` from `ANDROID_STORE_PASSWORD`/`ANDROID_KEY_ALIAS`/`ANDROID_KEY_PASSWORD`), clear error if secrets missing
- [x] 3.5 Delete old combined `build-apk.yml`
- [x] 3.6 Set 4 GitHub Secrets via `gh secret set` (verified with `gh secret list`): keystore base64 + store password + alias + key password
- [x] 3.7 Privacy policy hosted on gh-pages (docs/privacy-policy.html, bilingual) — live at https://hoangsoft90.github.io/SubscriptionTracker/
- [x] 3.8 Verify: no `com.subguard.app` references left in code (only historical comments); `flutter analyze` 0 issues; `flutter test` 247/247 pass; **no local APK build** (user rule — verification via GH Actions)

## 4. Display reliability

- [x] 4.1 `subscription_list_controller.dart`: `reload()` null-safe — no `state.value!`; rebuilds full state from fresh rows if the initial build hasn't completed (fixes crash/stale-list-until-restart when a mutation races the first load)
- [x] 4.2 `reload()` invalidates `dashboardControllerProvider` after every mutation → Home updates immediately after the first add (commit `30a8334`)
- [x] 4.3 `subscription_list_screen.dart`: `RefreshIndicator` on the subscriptions list (`AlwaysScrollableScrollPhysics`, onRefresh = `reload()`) — pull-down always reflects persisted data (was missing before)
- [x] 4.4 Settings notification section: `NotificationPlatform.permissionStatus()` + `openNotificationSettings()` (app_settings); `NotificationPermissionService.status()` + `enableFromSettings()` (first ask → OS prompt, later → OS settings); Settings UI shows Bật/Tắt + enable button; l10n `settingsNotifications*`
- [x] 4.5 Tests: `subscription_display_test.dart` (4 display/refresh scenarios + currency code), `real_db_add_flow_test.dart` (real sqflite integration: add → both tabs update, restart persists), `web_storage_flow_test.dart` (localStorage layer), `subscription_list_controller_test.dart` (null-safe reload regression), `notifications_test.dart` + `settings_notifications_test.dart`

## 5. Verification

- [x] 5.1 `flutter analyze` — 0 issues
- [x] 5.2 `flutter test` — 247/247 pass (final state across all capabilities)
- [x] 5.3 `openspec validate --changes` — this change + 5 prior changes pass
- [x] 5.4 No secrets in any diff (grep for ghp_/api key/password/keystore base64 before every commit); keystore + `key.properties` remain gitignored
- [x] 5.5 Update `.project/working.md` per project conventions
