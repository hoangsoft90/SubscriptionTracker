> Retrospective change: the implementation below is already shipped (2026-08-15). Tasks are recorded as completed against the live codebase; verification numbers reflect the final state.

## 1. Store assets + privacy policy

- [x] 1.1 Privacy policy (EN + VI, `docs/privacy-policy.md` + `docs/privacy-policy.html`): Contact section no longer references the GitHub repository — replaced with the support email `haibasoftware@gmail.com` (mailto link in HTML); no GitHub URL remains in the policy (grep verified)
- [x] 1.2 Redeploy gh-pages: copy `docs/privacy-policy.html` → gh-pages `index.html`, push (`8bca378`) — live at https://hoangsoft90.github.io/SubscriptionTracker/ (HTTP 200, Pages build completed)
- [x] 1.3 Verify `icon.png` is 512×512 RGB (created earlier; matches app brand — teal gradient rounded square + white card)
- [x] 1.4 Generate `feature-graphic.png` (1024×500) with PIL from the app's brand: teal gradient, decorative soft circles, white rounded card containing the app icon (scaled from `icon.png`), "SubTrack" title + underline bar, subtitle, tagline, 3 feature bullets; verified every text line fits within the 1024px width

## 2. Banner shell placement

- [x] 2.1 `lib/app/router/app_router.dart` `_AppShell`: `bottomNavigationBar` becomes `Column(min) [if (showAds) BannerAdView(), NavigationBar(...)]` — banner sits directly above the nav bar on every tab (Home/Subscriptions/More)
- [x] 2.2 `lib/features/ads/presentation/banner_ad_view.dart`: removed the bottom `SafeArea` (NavigationBar below already consumes the system inset) — banner now flush, no gap
- [x] 2.3 Removed the banner + `showAds` watch + unused imports from `home_screen.dart` and `subscription_list_screen.dart` (banner no longer per-tab)
- [x] 2.4 FAB on Subscriptions still floats above the shell bottomNavigationBar column (never overlaps the banner); `banner_layout_test.dart` layout invariant unchanged

## 3. Code-review bugfixes

- [x] 3.1 Full code review of all 83 lib files (13k lines): domain, storage (sqflite + localStorage + migrations + seeders), notifications, ads, backup, IAP, guidance, router/nav, every presentation screen — no new crash paths (`.first`/`!`/casts all guarded, backup import wrapped, money is integer minor math, exchange conversion returns null on missing rate, scheduler deterministic ids)
- [x] 3.2 Paywall error copy: added `paywallError` key (EN: "Purchase couldn't be completed. Please try again." / VI: "Không thể hoàn tất giao dịch mua. Vui lòng thử lại."); `_purchase()` and `_restore()` now show it instead of `backupErrorInvalidFile`
- [x] 3.3 Paywall slots-used: `activeCount` now uses `paywallSlotCount(listState.subscriptions)` (ACTIVE + PENDING_CANCELLATION) so the counter always matches the add-form hard-block gate
- [x] 3.4 Exchange-rate editor: invalid-input error now localized via `settingsExchangeRatesInvalid(currency)` (EN + VI) instead of hardcoded English "invalid rate"
- [x] 3.5 L10n: added `paywallError` + `settingsExchangeRatesInvalid` to `app_en.arb`/`app_vi.arb`, regenerated `lib/l10n/` via `flutter gen-l10n`

## 4. Verification

- [x] 4.1 `flutter analyze` — 0 issues
- [x] 4.2 `flutter test` — 247/247 pass (l10n regeneration did not break any test)
- [x] 4.3 No secrets in any diff (grep for ghp_/api key/password before every commit); privacy email is a public support address, not a secret
- [x] 4.4 Commits pushed to `main`: `d4582f9` (code fixes + privacy email) + `1434f4a` (working.md); gh-pages `8bca378`
- [x] 4.5 `openspec validate --changes` — this change + prior changes pass
- [x] 4.6 Update `.project/working.md` per project conventions
