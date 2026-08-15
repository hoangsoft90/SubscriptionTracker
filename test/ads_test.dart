import 'package:flutter_test/flutter_test.dart';

import 'package:subtrack/features/ads/ads_config.dart';
import 'package:subtrack/features/ads/ads_controller.dart';

void main() {
  group('shouldShowInterstitial (cooldown + frequency policy)', () {
    final now = DateTime(2026, 8, 13, 12, 0, 0);

    test('never shows before the first milestone', () {
      for (var count = 0; count < 5; count++) {
        expect(
          shouldShowInterstitial(
            addCount: count,
            frequency: 5,
            now: now,
            lastShownAt: null,
            cooldown: AdConfig.interstitialCooldown,
          ),
          false,
          reason: 'count=$count',
        );
      }
    });

    test('shows at the exact milestone with no prior show', () {
      expect(
        shouldShowInterstitial(
          addCount: 5,
          frequency: 5,
          now: now,
          lastShownAt: null,
          cooldown: AdConfig.interstitialCooldown,
        ),
        true,
      );
    });

    test('shows at a later milestone once the cooldown has elapsed', () {
      expect(
        shouldShowInterstitial(
          addCount: 10,
          frequency: 5,
          now: now,
          lastShownAt: now.subtract(const Duration(minutes: 6)),
          cooldown: AdConfig.interstitialCooldown,
        ),
        true,
      );
    });

    test('holds back a milestone that lands inside the cooldown', () {
      expect(
        shouldShowInterstitial(
          addCount: 5,
          frequency: 5,
          now: now,
          lastShownAt: now.subtract(const Duration(minutes: 1)),
          cooldown: AdConfig.interstitialCooldown,
        ),
        false,
      );
      // Exactly at the cooldown boundary counts as elapsed (>=).
      expect(
        shouldShowInterstitial(
          addCount: 5,
          frequency: 5,
          now: now,
          lastShownAt: now.subtract(AdConfig.interstitialCooldown),
          cooldown: AdConfig.interstitialCooldown,
        ),
        true,
      );
    });

    test('non-milestone counts never show even after cooldown', () {
      expect(
        shouldShowInterstitial(
          addCount: 6,
          frequency: 5,
          now: now,
          lastShownAt: now.subtract(const Duration(hours: 1)),
          cooldown: AdConfig.interstitialCooldown,
        ),
        false,
      );
    });

    test('degenerate input is rejected', () {
      expect(
        shouldShowInterstitial(
          addCount: 0,
          frequency: 5,
          now: now,
          lastShownAt: null,
          cooldown: AdConfig.interstitialCooldown,
        ),
        false,
      );
      expect(
        shouldShowInterstitial(
          addCount: 5,
          frequency: 0,
          now: now,
          lastShownAt: null,
          cooldown: AdConfig.interstitialCooldown,
        ),
        false,
      );
    });
  });

  group('AdConfig test-ads mode', () {
    test('test ads are ON by default (avoids real-unit "No fill" limits)', () {
      // User decision 2026-08-15: while the app is being built/tested, all
      // ad units resolve to Google's official sample IDs so the real AdMob
      // account is never touched. Flip with --dart-define=TEST_ADS=false.
      expect(AdConfig.testAds, isTrue);
      expect(AdConfig.appId, contains('ca-app-pub-3940256099942544'));
      expect(AdConfig.bannerUnitId, contains('ca-app-pub-3940256099942544'));
      expect(
        AdConfig.interstitialUnitId,
        contains('ca-app-pub-3940256099942544'),
      );
      expect(AdConfig.rewardedUnitId, contains('ca-app-pub-3940256099942544'));
    });

    test('cooldown default is 5 minutes', () {
      expect(AdConfig.interstitialCooldown, const Duration(minutes: 5));
    });
  });
}
