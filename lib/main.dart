import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'app/app.dart';
import 'core/notifications/reboot_rescheduler.dart';
import 'core/storage/database_factory.dart';
import 'features/ads/ads_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('MAIN: start');
  // Web has no sqflite plugin — install the WASM-backed factory first.
  // On native this is a no-op (the plugin registers itself).
  configureDatabaseFactory();
  debugPrint('MAIN: db factory done');
  // Android-only: periodic WorkManager task re-runs notification reconcile
  // after device reboot (iOS restores scheduled notifications itself).
  // No-op on web (see guard inside).
  RebootRescheduler.initialize();
  debugPrint('MAIN: reboot rescheduler called');
  // AdMob SDK init (free-tier banner + rare interstitial; Pro removes ads).
  // No-op on web and in widget tests (see AdConfig.supported).
  if (AdConfig.supported) {
    debugPrint('MAIN: ads supported, initializing');
    await MobileAds.instance.initialize();
    debugPrint('MAIN: ads init called');
    // Register physical test devices so real unit IDs fill with test ads
    // while the app is still unpublished (AdMob returns NO_FILL otherwise).
    // Test ads appear only on these exact devices; other devices get real ads.
    if (AdConfig.testDeviceIds.isNotEmpty) {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: AdConfig.testDeviceIds),
      );
      debugPrint('MAIN: test devices registered');
    }
  } else {
    debugPrint('MAIN: ads not supported');
  }
  runApp(const ProviderScope(child: SubTrackApp()));
  debugPrint('MAIN: runApp called');
}
