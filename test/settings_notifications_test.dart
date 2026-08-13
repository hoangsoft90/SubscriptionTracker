import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:subtrack/app/app.dart';
import 'package:subtrack/core/l10n/l10n.dart';
import 'package:subtrack/core/notifications/notification_platform.dart';

import 'm1_widget_test.dart' show pumpUntilFound;
import 'widget_harness.dart';

void main() {
  /// Pumps the full app on the widget harness fakes and navigates to Settings.
  Future<void> openSettings(WidgetTester tester, WidgetHarness harness) async {
    await tester.pumpWidget(harness.scope(child: const SubTrackApp()));
    await pumpUntilFound(tester, find.byType(Navigator));
    await tester.pumpAndSettle();
    // Navigate to the Settings screen (nested shell route).
    final ctx = tester.element(find.byType(Navigator).first);
    // ignore: use_build_context_synchronously
    ctx.go('/more/settings');
    await pumpUntilFound(
      tester,
      find.text(tester.element(find.byType(Scaffold).first).l10n.settingsTitle),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('settings shows notification section with status', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final harness = WidgetHarness();
    harness.notificationPlatform.status =
        NotificationPermissionStatus.enabled;
    await openSettings(tester, harness);

    final l10n = tester.element(find.byType(Scaffold).first).l10n;
    expect(find.text(l10n.settingsNotificationsTitle), findsOneWidget);
    expect(find.text(l10n.settingsNotificationsEnabled), findsOneWidget);
    // Enabled → no enable button.
    expect(find.text(l10n.settingsNotificationsEnable), findsNothing);
  });

  testWidgets('disabled status offers enable → opens OS settings after ask',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final harness = WidgetHarness();
    final platform = harness.notificationPlatform;
    platform.status = NotificationPermissionStatus.disabled;
    // Simulate the user having denied the prompt once already (the common
    // case on Android after the first denial).
    await harness.settingsRepo.set('notifPermissionRequested', 'true');

    await openSettings(tester, harness);

    final l10n = tester.element(find.byType(Scaffold).first).l10n;
    expect(find.text(l10n.settingsNotificationsDisabled), findsOneWidget);
    expect(find.text(l10n.settingsNotificationsEnable), findsOneWidget);

    // Tap enable → opens the OS notification settings (no re-prompt).
    await tester.tap(find.text(l10n.settingsNotificationsEnable));
    await tester.pumpAndSettle();
    expect(platform.settingsOpened, isTrue);
    expect(platform.permissionRequested, isFalse);
  });

  testWidgets('never-asked disabled status prompts on enable', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final harness = WidgetHarness();
    final platform = harness.notificationPlatform;
    platform.status = NotificationPermissionStatus.disabled;
    platform.permissionGranted = true; // user will accept the prompt

    await openSettings(tester, harness);

    final l10n = tester.element(find.byType(Scaffold).first).l10n;
    await tester.tap(find.text(l10n.settingsNotificationsEnable));
    await tester.pumpAndSettle();

    // First ask → OS prompt shown, not the settings screen.
    expect(platform.permissionRequested, isTrue);
    expect(platform.settingsOpened, isFalse);
  });
}
