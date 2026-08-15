import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ads_config.dart';
import '../ads_controller.dart';

/// Anchored adaptive banner pinned directly above the NavigationBar in the
/// app shell (free tier only; Pro removes ads). Renders nothing on web and
/// in widget tests, and nothing while the ad is still loading — the layout
/// never reserves space for ads. No bottom SafeArea: the NavigationBar below
/// already handles the system bottom inset, so the banner sits flush.
class BannerAdView extends ConsumerStatefulWidget {
  const BannerAdView({super.key});

  @override
  ConsumerState<BannerAdView> createState() => _BannerAdViewState();
}

class _BannerAdViewState extends ConsumerState<BannerAdView> {
  BannerAd? _banner;
  AdSize? _size;
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
    _size = size;
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
    final size = _size;
    // The platform-view placeholder expands to fill ALL available space when
    // unconstrained (it reports infinite height inside a Column). Constraining
    // the AdWidget to the loaded banner's exact AdSize keeps the banner
    // from collapsing the surrounding layout — without this, the Expanded
    // list on the same screen gets h=0 and renders nothing while the data is
    // actually there (the "list sometimes empty" bug).
    if (size == null) return const SizedBox.shrink();
    // No SafeArea wrapper — the NavigationBar directly below in the shell
    // consumes the system bottom inset, so a bottom SafeArea here would
    // create a visible gap between the banner and the nav buttons.
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surface,
      child: SizedBox(
        width: size.width.toDouble(),
        height: size.height.toDouble(),
        child: AdWidget(ad: banner),
      ),
    );
  }
}
