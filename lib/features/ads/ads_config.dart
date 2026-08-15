import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// AdMob configuration.
///
/// Spec amendment (user-approved 2026-08-09): AdMob is the ONLY third-party
/// network SDK in the app — serving **non-personalized** banner + rare
/// interstitial ads on the **free tier only**. Lifetime Pro removes all ads.
///
/// IDs below are the REAL AdMob app + ad unit IDs, registered for the
/// original package `com.subguard.app` (set up 2026-08-11). The package has
/// since moved to `com.hoangsoft.subtrack` (2026-08-15) — BEFORE enabling
/// real (non-test) ads again, register a new AdMob app for the new package
/// and replace the IDs below. Same app ID is used on Android + iOS.
class AdConfig {
  AdConfig._();

  /// Master switch — ads are OFF by default (`enable_ads=false`, user decision
  /// 2026-08-15): ship an ad-free build without touching any screen. To turn
  /// ads back on later (`enable_ads=true`), build with
  /// `--dart-define=ENABLE_ADS=true` — no code change needed.
  static const bool enabled =
      bool.fromEnvironment('ENABLE_ADS', defaultValue: false);

  /// Test-ads mode. When true, ALL ad units resolve to Google's official
  /// sample/test IDs instead of the real ones, so ads always fill during
  /// development — real units return "No fill" until they have valid traffic
  /// and are active in the AdMob console, and test mode avoids that limit
  /// (fresh/unapproved accounts can be limited).
  ///
  /// NOW ON BY DEFAULT (user decision 2026-08-15): while the app is being
  /// built/tested, test ads are the safe default so the real AdMob account
  /// is never touched. Switch to production with
  /// `flutter build apk --dart-define=TEST_ADS=false`.
  static const bool testAds = bool.fromEnvironment('TEST_ADS', defaultValue: true);

  /// Real (production) ad unit IDs — registered for the original package
  /// `com.subguard.app` (set up 2026-08-11); needs re-registration for
  /// `com.hoangsoft.subtrack` before going live with real ads.
  static const String _androidAppId = 'ca-app-pub-6917313063209470~5291822252';
  static const String _iosAppId = 'ca-app-pub-6917313063209470~5291822252';
  static const String _androidBanner = 'ca-app-pub-6917313063209470/7565917792';
  static const String _iosBanner = 'ca-app-pub-6917313063209470/7565917792';
  static const String _androidInterstitial =
      'ca-app-pub-6917313063209470/3877954222';
  static const String _iosInterstitial =
      'ca-app-pub-6917313063209470/3877954222';

  /// Google's official sample/test ad unit IDs (always fill, never limited).
  static const String _testAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const String _testBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitial =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewarded = 'ca-app-pub-3940256099942544/5224354917';

  /// Rewarded ad unit — not wired into any flow yet (reserved for a future
  /// rewarded-earn feature; kept here so the ID is discoverable in one place).
  static String get rewardedUnitId =>
      testAds ? _testRewarded : 'ca-app-pub-6917313063209470/7247333533';

  /// Minimum time between two interstitial shows — AdMob discourages showing
  /// interstitials back-to-back (rate limiting / poor UX). A frequency-guarded
  /// ad that lands while still cooling down is held back until the next
  /// milestone (see InterstitialAdsController).
  static const Duration interstitialCooldown = Duration(minutes: 5);

  /// Non-personalized ads request extra (keeps tracking minimal — consistent
  /// with the app's privacy positioning; no ATT prompt on iOS).
  static const Map<String, String> nonPersonalizedExtras = {'npa': '1'};

  /// AdMob is unsupported on web, and widget tests must never hit platform
  /// channels (they would throw MissingPluginException).
  static bool get supported =>
      enabled && !kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST');

  static bool get isAndroid => Platform.isAndroid;

  static String get appId =>
      testAds ? _testAppId : (isAndroid ? _androidAppId : _iosAppId);
  static String get bannerUnitId =>
      testAds ? _testBanner : (isAndroid ? _androidBanner : _iosBanner);
  static String get interstitialUnitId => testAds
      ? _testInterstitial
      : (isAndroid ? _androidInterstitial : _iosInterstitial);
}
