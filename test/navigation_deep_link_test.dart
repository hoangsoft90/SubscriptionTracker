import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:subtrack/app/app.dart';
import 'package:subtrack/core/l10n/l10n.dart';
import 'package:subtrack/features/subscriptions/domain/billing_cycle.dart';
import 'package:subtrack/features/subscriptions/domain/subscription.dart';
import 'package:subtrack/features/subscriptions/domain/subscription_status.dart';

import 'm1_widget_test.dart' show pumpUntilFound;
import 'widget_harness.dart';

void main() {
  /// Pumps the full app (real routerProvider) on the widget harness fakes.
  Future<void> pumpApp(WidgetTester tester, WidgetHarness harness) async {
    await tester.pumpWidget(harness.scope(child: const SubTrackApp()));
    await pumpUntilFound(tester, find.byType(Navigator));
    await tester.pumpAndSettle();
  }

  /// Navigates the app's real GoRouter to [path].
  Future<void> goTo(WidgetTester tester, String path) async {
    final ctx = tester.element(find.byType(Navigator).first);
    GoRouter.of(ctx).go(path);
    await tester.pumpAndSettle();
  }

  group('Navigation recovery (deep-link edge cases)', () {
    testWidgets('unknown path shows the not-found screen with a Home button',
        (tester) async {
      final harness = WidgetHarness();
      await pumpApp(tester, harness);
      await goTo(tester, '/no-such-page');

      final l10n = tester.element(find.byType(Scaffold).first).l10n;
      expect(find.text(l10n.errorTitle), findsOneWidget);
      expect(find.byIcon(Icons.home_outlined), findsWidgets);
    });

    testWidgets('/calendar deep link renders and offers Home (no back stack)',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final harness = WidgetHarness();
      await pumpApp(tester, harness);
      await goTo(tester, '/calendar');

      final l10n = tester.element(find.byType(Scaffold).first).l10n;
      expect(find.text(l10n.calendarTitle), findsOneWidget);
      // Deep-linked directly → no back stack → home affordance present.
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    });

    testWidgets('/paywall deep link renders and offers Home (no back stack)',
        (tester) async {
      final harness = WidgetHarness();
      await pumpApp(tester, harness);
      await goTo(tester, '/paywall');

      final l10n = tester.element(find.byType(Scaffold).first).l10n;
      expect(find.text(l10n.paywallTitle), findsWidgets);
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    });

    testWidgets('categories are reachable via /more/categories with back',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final harness = WidgetHarness();
      await pumpApp(tester, harness);
      await goTo(tester, '/more/categories');

      final l10n = tester.element(find.byType(Scaffold).first).l10n;
      await pumpUntilFound(tester, find.text(l10n.categoriesTitle));
      // Pushed as a nested shell route → has an implied back button.
      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets('deep link before onboarding is restored after completing it',
        (tester) async {
      final harness = WidgetHarness(onboardingCompleted: false);
      await pumpApp(tester, harness);

      // Deep link to /calendar while not onboarded → forced to onboarding,
      // destination remembered.
      await goTo(tester, '/calendar');
      final l10n = tester.element(find.byType(Scaffold).first).l10n;
      await pumpUntilFound(tester, find.text(l10n.onboardingPrivacyTitle));

      // Complete the 3 onboarding steps.
      await tester.tap(find.text(l10n.onboardingContinue));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.onboardingContinue));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.onboardingDone));
      await tester.pumpAndSettle();

      // Landed back on the deep-linked destination, with a way home.
      expect(find.text(l10n.calendarTitle), findsOneWidget);
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    });

    testWidgets('root path (bare domain URL) lands on Home, not not-found',
        (tester) async {
      final harness = WidgetHarness();
      await pumpApp(tester, harness);
      // Simulate the web app being opened at https://subtrack.app/ (no path).
      await goTo(tester, '/');

      // Home shell renders (NavigationBar present), and the not-found
      // recovery screen does NOT appear.
      await pumpUntilFound(tester, find.byType(NavigationBar));
      final l10n = tester.element(find.byType(Scaffold).first).l10n;
      expect(find.text(l10n.errorTitle), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('/more/settings deep link renders with back, no dead end',
        (tester) async {
      final harness = WidgetHarness();
      await pumpApp(tester, harness);
      await goTo(tester, '/more/settings');

      final l10n = tester.element(find.byType(Scaffold).first).l10n;
      await pumpUntilFound(tester, find.text(l10n.settingsTitle));
      // Nested shell route → has an implied back button to return to /more.
      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets('/more/backup deep link renders with back, no dead end',
        (tester) async {
      final harness = WidgetHarness();
      await pumpApp(tester, harness);
      await goTo(tester, '/more/backup');

      final l10n = tester.element(find.byType(Scaffold).first).l10n;
      await pumpUntilFound(tester, find.text(l10n.backupTitle));
      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets('/subscriptions/add deep link renders with back, no dead end',
        (tester) async {
      final harness = WidgetHarness();
      await pumpApp(tester, harness);
      await goTo(tester, '/subscriptions/add');

      final l10n = tester.element(find.byType(Scaffold).first).l10n;
      await pumpUntilFound(tester, find.text(l10n.addTitle));
      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets('/subscriptions/:id/edit deep link renders with back',
        (tester) async {
      final harness = WidgetHarness(
        subscriptions: [
          Subscription(
            id: 'sub-1',
            name: 'Netflix',
            amountMinor: 1499,
            currency: 'USD',
            billingCycle: BillingCycle.monthly,
            startDate: DateTime(2026, 1, 1),
            nextBillingDate: DateTime(2026, 8, 15),
            billingAnchorDay: 1,
            isTrial: false,
            status: SubscriptionStatus.active,
            createdAt: DateTime(2026, 1, 1),
            updatedAt: DateTime(2026, 1, 1),
          ),
        ],
      );
      await pumpApp(tester, harness);
      await goTo(tester, '/subscriptions/sub-1/edit');

      final l10n = tester.element(find.byType(Scaffold).first).l10n;
      await pumpUntilFound(tester, find.text(l10n.editTitle));
      expect(find.byType(BackButton), findsOneWidget);
    });
  });
}
