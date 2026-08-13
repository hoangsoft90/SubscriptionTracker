import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ads_config.dart';
import '../ads_controller.dart';

/// Anchored adaptive banner pinned at the bottom of a tab (free tier only;
/// Pro removes ads). Renders nothing on web and in widget tests, and nothing
/// while the ad is still loading — the layout never reserves space for ads.
class BannerAdView extends ConsumerStatefulWidget {
  const BannerAdView({super.key});

  @override
  ConsumerState<BannerAdView> createState() => _BannerAdViewState();
}

class _BannerAdViewState extends ConsumerState<BannerAdView> {
  BannerAd? _banner;
  bool _loaded = false;
  bool _loadStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // MediaQuery is read inside _load() — that is only safe AFTER initState
    // (reading an inherited widget in initState throws), so kick the load off
    // from here, once.
    if (!_loadStarted && AdConfig.supported && ref.read(showAdsProvider)) {
      _loadStarted = true;
      _load();
    }
  }

  Future<void> _load() async {
    final width = MediaQuery.sizeOf(context).width.floor();
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSizeWithOrientation(
      Orientation.portrait,
      width,
    );
    if (size == null || !mounted) return;
    final banner = BannerAd(
      adUnitId: AdConfig.bannerUnitId,
      size: size,
      request: AdRequest(extras: AdConfig.nonPersonalizedExtras),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _banner = null;
        },
      ),
    );
    _banner = banner;
    await banner.load();
  }

  void _disposeBanner() {
    _banner?.dispose();
    _banner = null;
    _loaded = false;
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pro purchase (or unsupported platform) hides the banner immediately.
    if (!ref.watch(showAdsProvider)) {
      _disposeBanner();
      return const SizedBox.shrink();
    }
    final banner = _banner;
    if (banner == null || !_loaded) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        color: Theme.of(context).colorScheme.surface,
        child: AdWidget(ad: banner),
      ),
    );
  }
}
