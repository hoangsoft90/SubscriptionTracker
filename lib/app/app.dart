import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/l10n.dart';
import '../core/providers.dart';
import '../features/settings/application/settings_controller.dart';
import '../features/subscriptions/application/subscription_list_controller.dart';
import '../features/subscriptions/domain/subscription.dart';
import '../l10n/app_localizations.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// Root widget: theme mode + router + locale consumed from Riverpod providers.
class SubTrackApp extends ConsumerWidget {
  const SubTrackApp({super.key});

  /// App-open trigger must fire exactly once per process (not per rebuild).
  static bool _appOpenFired = false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsControllerProvider).value;

    _wireNotificationTriggers(ref);

    return MaterialApp.router(
      title: 'SubTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings?.themeMode ?? ThemeMode.system,
      onGenerateTitle: (context) => context.l10n.appName,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      // null → follow the device locale; an explicit 'en'/'vi' overrides it.
      locale: settings?.localeCode == null
          ? null
          : Locale(settings!.localeCode!),
      routerConfig: router,
    );
  }

  /// Notification triggers (spec §2.4): reconcile on subscription data
  /// changes + request permission right after the first subscription; the
  /// app-open trigger runs once per process.
  void _wireNotificationTriggers(WidgetRef ref) {
    if (!_appOpenFired) {
      _appOpenFired = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(notificationCoordinatorProvider).onAppOpen();
      });
    }

    ref.listen(subscriptionListControllerProvider, (prev, next) {
      if (!next.hasValue || prev?.hasValue != true) return;
      final prevSubs = prev!.value!.subscriptions;
      final nextSubs = next.value!.subscriptions;
      if (_sameSchedule(prevSubs, nextSubs)) return;

      final coordinator = ref.read(notificationCoordinatorProvider);
      if (prevSubs.length != nextSubs.length) {
        // Permission is requested only when the FIRST subscription appears
        // (count goes 0 → 1) — never at launch or onboarding.
        coordinator.maybeRequestPermissionAfterFirstSubscription(
          totalSubscriptions: nextSubs.length,
        );
      }
      coordinator.onSubscriptionsChanged();
    });
  }

  /// True when the two lists would produce the same notification schedule
  /// (same ids, billing dates, trial dates and statuses).
  bool _sameSchedule(List<Subscription> a, List<Subscription> b) {
    if (a.length != b.length) return false;
    final byId = {for (final s in a) s.id: s};
    for (final s in b) {
      final prev = byId[s.id];
      if (prev == null) return false;
      if (prev.nextBillingDate != s.nextBillingDate ||
          prev.trialEndDate != s.trialEndDate ||
          prev.isTrial != s.isTrial ||
          prev.status != s.status) {
        return false;
      }
    }
    return true;
  }
}
