import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../paywall/entitlement_controller.dart';
import 'ads_config.dart';

/// True when banner/interstitial ads may render: the platform supports AdMob
/// AND the user is not Pro (Lifetime Pro removes all ads).
final showAdsProvider = Provider<bool>((ref) {
  if (!AdConfig.supported) return false;
  final isPro = ref.watch(proEntitlementControllerProvider).value ?? false;
  return !isPro;
});

/// Pure decision — no platform channels, fully unit-testable.
///
/// An interstitial may show only when the add counter hits the frequency
/// milestone AND the cooldown since the last show has elapsed. Keeping this
/// logic free of AdMob/Riverpod lets tests verify the rate-limiting rules
/// without a real ad instance.
bool shouldShowInterstitial({
  required int addCount,
  required int frequency,
  required DateTime now,
  required DateTime? lastShownAt,
  required Duration cooldown,
}) {
  if (addCount <= 0 || frequency <= 0) return false;
  if (addCount % frequency != 0) return false;
  final last = lastShownAt;
  if (last == null) return true;
  return now.difference(last) >= cooldown;
}

/// Owns the interstitial lifecycle. Ads are opportunistic: the ad is preloaded
/// in the background after each add so that one is already ready at every
/// [InterstitialAdsController.frequency]-th add (free tier only). Any load or
/// show failure is silently ignored — ads must never block the user's flow.
class InterstitialAdsController extends Notifier<int> {
  /// Show one interstitial per this many subscription adds (rare by design).
  static const int frequency = 5;

  InterstitialAd? _ad;
  bool _loading = false;
  bool _pendingShow = false;
  DateTime? _lastShownAt;

  @override
  int build() => 0;

  /// Call after each successful (non-edit) subscription save.
  Future<void> onSubscriptionAdded() async {
    if (!AdConfig.supported) return;
    if (ref.read(proEntitlementControllerProvider).value ?? false) return;
    final count = state + 1;
    state = count;
    if (shouldShowInterstitial(
      addCount: count,
      frequency: frequency,
      now: DateTime.now(),
      lastShownAt: _lastShownAt,
      cooldown: AdConfig.interstitialCooldown,
    )) {
      _showReadyAd();
    } else if (_ad == null && !_loading) {
      // Preload now so the next milestone has an ad ready to show.
      _load();
    }
  }

  void _showReadyAd() {
    final ad = _ad;
    _ad = null;
    if (ad == null) {
      // Not loaded yet (slow network / no fill) — show as soon as it lands.
      _pendingShow = true;
      if (!_loading) _load();
      return;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdDismissedFullScreenContent: (a) => a.dispose(),
      onAdFailedToShowFullScreenContent: (a, _) => a.dispose(),
    );
    _lastShownAt = DateTime.now();
    ad.show();
  }

  void _load() {
    if (_loading) return;
    _loading = true;
    try {
      // v9: load() returns Future<void> — the ad arrives via the callback.
      InterstitialAd.load(
        adUnitId: AdConfig.interstitialUnitId,
        request: AdRequest(extras: AdConfig.nonPersonalizedExtras),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _loading = false;
            _ad = ad;
            if (_pendingShow) {
              _pendingShow = false;
              _showReadyAd();
            }
          },
          onAdFailedToLoad: (_) => _loading = false,
        ),
      );
    } catch (_) {
      // No fill, offline, or a platform hiccup — never surface to the user.
      _loading = false;
    }
  }
}

final interstitialAdsControllerProvider =
    NotifierProvider<InterstitialAdsController, int>(
  InterstitialAdsController.new,
);
