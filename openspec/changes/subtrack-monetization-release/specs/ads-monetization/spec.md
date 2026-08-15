## Purpose

AdMob ads for the free tier (Pro removes all ads), hardened for development and release: test-ads mode by default so the unapproved real account is never limited, a frequency + cooldown policy for interstitials, and banner layout constraints so the ad can never collapse the list or overlap the FAB.

## ADDED Requirements

### Requirement: Test ads are the default while the account is unapproved
The system SHALL resolve all ad units to Google's official sample/test IDs by default (`testAds = true`), so ads always fill and the real AdMob account is never touched while unapproved. Production SHALL flip to the real unit IDs with `--dart-define=TEST_ADS=false`.

#### Scenario: Fresh build uses sample IDs
- **WHEN** the app is built without the `TEST_ADS` define
- **THEN** every ad unit resolves to a `ca-app-pub-3940256099942544` sample ID and banners fill immediately

#### Scenario: Production build uses real IDs
- **WHEN** the app is built with `--dart-define=TEST_ADS=false`
- **THEN** the real `ca-app-pub-6917313063209470` unit IDs are used

### Requirement: Interstitials respect a frequency milestone and cooldown
The system SHALL consider showing an interstitial only every N-th subscription add (`frequency = 5`) AND only when the last show is at least `interstitialCooldown` (5 minutes) ago. The policy SHALL be a pure function (`shouldShowInterstitial`) with no platform-channel dependency, and load/show failures SHALL be silently ignored (ads never block the user flow).

#### Scenario: Show at the milestone after the cooldown
- **WHEN** the add counter hits 5 and no ad was shown in the last 5 minutes
- **THEN** the interstitial shows

#### Scenario: Milestone inside the cooldown is held back
- **WHEN** the add counter hits a milestone but an ad was shown 1 minute ago
- **THEN** the interstitial is not shown until the cooldown elapses

#### Scenario: Ad failures never block the add flow
- **WHEN** the ad fails to load or show
- **THEN** the subscription add completes normally with no error surfaced

### Requirement: The loaded banner is constrained to its AdSize
The system SHALL wrap the banner's `AdWidget` in a `SizedBox` sized to the loaded `AdSize`, so the platform-view placeholder cannot report infinite height and collapse sibling `Expanded` widgets. The banner SHALL render nothing while loading (no reserved space), and on screens with a FAB it SHALL sit in the Scaffold `bottomNavigationBar` slot so the FAB floats above it.

#### Scenario: List stays visible after the banner loads
- **WHEN** an AdMob banner finishes loading on the subscriptions screen
- **THEN** the list keeps its full height and all rows remain visible (regression: `banner_layout_test.dart`)

#### Scenario: FAB is never overlapped
- **WHEN** the banner is present on the subscriptions screen
- **THEN** the FAB "+" floats above it and remains fully tappable

#### Scenario: Banner renders nothing while loading
- **WHEN** the banner has not loaded yet
- **THEN** no space is reserved and the layout is unchanged

### Requirement: Ads are gated by platform and entitlement
The system SHALL not load ads on web, in widget tests, or for Pro users (`AdConfig.supported` false when `kIsWeb`/`FLUTTER_TEST`; `showAdsProvider` false for Pro).

#### Scenario: No ads in tests or on web
- **WHEN** running widget tests or the web build
- **THEN** no ad is loaded and no platform channel is touched

#### Scenario: Pro removes ads
- **WHEN** the user owns Lifetime Pro
- **THEN** banners and interstitials are hidden
