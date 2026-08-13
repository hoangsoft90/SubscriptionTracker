import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:subtrack/app/app.dart';
import 'package:subtrack/core/l10n/l10n.dart';
import 'package:subtrack/features/settings/application/settings_controller.dart';
import 'package:subtrack/features/subscriptions/domain/billing_cycle.dart';
import 'package:subtrack/features/subscriptions/domain/subscription.dart';
import 'package:subtrack/features/subscriptions/domain/subscription_status.dart';
import 'package:subtrack/l10n/app_localizations.dart';

import 'm1_widget_test.dart' show pumpUntilFound;
import 'widget_harness.dart';

void main() {
  test('EN and VI lookups return the right strings (spec §localization)', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final vi = lookupAppLocalizations(const Locale('vi'));

    expect(en.tabSubscriptions, 'Subscriptions');
    expect(vi.tabSubscriptions, 'Đăng ký');
    expect(en.settingsTitle, 'Settings');
    expect(vi.settingsTitle, 'Cài đặt');
    expect(en.dashboardEmptyCta, 'Add subscription');
    expect(vi.dashboardEmptyCta, 'Thêm đăng ký');
  });

  test('preset display names resolve per locale by stable key', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final vi = lookupAppLocalizations(const Locale('vi'));
    // Keys stay stable; values are localized.
    expect(presetDisplayNames(en)['preset.netflix'], 'Netflix');
    expect(presetDisplayNames(en)['preset.kg'], 'K+');
    expect(presetDisplayNames(vi)['preset.netflix'], 'Netflix');
    expect(presetDisplayNames(vi)['preset.spotify'], 'Spotify');
  });

  testWidgets('device locale vi_VN defaults the app to Vietnamese',
      (tester) async {
    tester.binding.platformDispatcher.localesTestValue = const [
      Locale('vi', 'VN'),
    ];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);

    final harness = WidgetHarness();
    await tester.pumpWidget(harness.scope(child: const SubTrackApp()));
    await pumpUntilFound(tester, find.text('Chưa có gì để theo dõi'));
    expect(find.text('Thêm đăng ký'), findsOneWidget);
    expect(find.text('Trang chủ'), findsOneWidget); // nav label
  });

  testWidgets('runtime switch EN → VI reflects immediately', (tester) async {
    final harness = WidgetHarness(language: 'en');
    await tester.pumpWidget(harness.scope(child: const SubTrackApp()));
    await pumpUntilFound(tester, find.text('Subscriptions'));

    // Drive the runtime switch through the app's own provider container
    // (Settings > Language in the UI calls exactly this controller action).
    final context = tester.element(find.byType(NavigationBar));
    final container = ProviderScope.containerOf(context);
    await container
        .read(settingsControllerProvider.notifier)
        .setLocale('vi');
    await tester.pump();

    // UI renders in Vietnamese immediately, incl. the persisted setting.
    await pumpUntilFound(tester, find.text('Đăng ký'));
    expect(find.text('Trang chủ'), findsOneWidget);
    expect(harness.settingsRepo.get('language'), completion('vi'));

    // Switching back to the device default restores English.
    await container.read(settingsControllerProvider.notifier).setLocale(null);
    await tester.pump();
    await pumpUntilFound(tester, find.text('Subscriptions'));
  });

  testWidgets('user-entered names are never localized across a switch',
      (tester) async {
    final harness = WidgetHarness(
      language: 'vi',
      subscriptions: [
        _sub(id: 'gym', name: 'My Gym'),
        _sub(id: 'net', name: 'Netflix'),
      ],
    );
    await tester.pumpWidget(harness.scope(child: const SubTrackApp()));
    await pumpUntilFound(tester, find.byType(NavigationBar));

    // Switch to the Subscriptions tab and verify stored names render as-is.
    await tester.tap(find.text('Đăng ký'));
    await pumpUntilFound(tester, find.text('My Gym'));
    expect(find.text('My Gym'), findsOneWidget);
    expect(find.text('Netflix'), findsOneWidget);
  });

  test('interpolated strings compose with placeholders', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final vi = lookupAppLocalizations(const Locale('vi'));
    expect(en.nextBillingLabel('08/15'), 'Next: 08/15');
    expect(vi.nextBillingLabel('08/15'), 'Tới: 08/15');
    expect(vi.freeSlotsBanner(3), 'Bạn còn 3 chỗ trống miễn phí');
  });
}

Subscription _sub({required String id, required String name}) {
  return Subscription(
    id: id,
    name: name,
    amountMinor: 999,
    currency: 'USD',
    billingCycle: BillingCycle.monthly,
    startDate: DateTime(2026, 1, 1),
    nextBillingDate: DateTime(2026, 8, 15),
    billingAnchorDay: 1,
    isTrial: false,
    status: SubscriptionStatus.active,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}
