import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// AdMob configuration.
///
/// Spec amendment (user-approved 2026-08-09): AdMob is the ONLY third-party
/// network SDK in the app — serving **non-personalized** banner + rare
/// interstitial ads on the **free tier only**. Lifetime Pro removes all ads.
///
/// IDs below are the REAL AdMob app + ad unit IDs for `com.subguard.app`
/// (set up 2026-08-11). Same app ID is used on Android + iOS; the ad units
/// serve both platforms.
class AdConfig {
  AdConfig._();

  /// Master switch — flip to false to ship an ad-free build without touching
  /// screens (e.g. if the AdMob account is not ready).
  static const bool enabled = true;

  static const String _androidAppId = 'ca-app-pub-6917313063209470~5291822252';
  static const String _iosAppId = 'ca-app-pub-6917313063209470~5291822252';
  static const String _androidBanner = 'ca-app-pub-6917313063209470/7565917792';
  static const String _iosBanner = 'ca-app-pub-6917313063209470/7565917792';
  static const String _androidInterstitial =
      'ca-app-pub-6917313063209470/3877954222';
  static const String _iosInterstitial =
      'ca-app-pub-6917313063209470/3877954222';

  /// Rewarded ad unit — not wired into any flow yet (reserved for a future
  /// rewarded-earn feature; kept here so the ID is discoverable in one place).
  static const String rewardedUnitId =
      'ca-app-pub-6917313063209470/7247333533';

  /// Non-personalized ads request extra (keeps tracking minimal — consistent
  /// with the app's privacy positioning; no ATT prompt on iOS).
  static const Map<String, String> nonPersonalizedExtras = {'npa': '1'};

  /// AdMob is unsupported on web, and widget tests must never hit platform
  /// channels (they would throw MissingPluginException).
  static bool get supported =>
      enabled && !kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST');

  static bool get isAndroid => Platform.isAndroid;

  static String get appId => isAndroid ? _androidAppId : _iosAppId;
  static String get bannerUnitId => isAndroid ? _androidBanner : _iosBanner;
  static String get interstitialUnitId =>
      isAndroid ? _androidInterstitial : _iosInterstitial;
}
