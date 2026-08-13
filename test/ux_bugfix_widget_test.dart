import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:subtrack/app/app.dart';
import 'package:subtrack/features/categories/domain/category.dart';
import 'package:subtrack/features/categories/presentation/categories_screen.dart';
import 'package:subtrack/features/subscriptions/domain/billing_cycle.dart';
import 'package:subtrack/features/subscriptions/domain/subscription.dart';
import 'package:subtrack/features/subscriptions/domain/subscription_status.dart';
import 'package:subtrack/l10n/app_localizations.dart';

import 'widget_harness.dart';
import 'm1_widget_test.dart' show pumpUntilFound;

void main() {
  group('Bug 1 — onboarding preset selection', () {
    testWidgets('tapping a preset toggles its checkmark', (tester) async {
      final harness = WidgetHarness(onboardingCompleted: false);

      await tester.pumpWidget(harness.scope(child: const SubTrackApp()));
      await pumpUntilFound(tester, find.text('Private by design'));

      // Advance privacy step.
      await tester.tap(find.text('Continue'));
      await pumpUntilFound(tester, find.text('Choose your primary currency'));

      // Advance currency step (let the AnimatedSwitcher settle first so only
      // one "Continue" button is on screen).
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await pumpUntilFound(tester, find.text('Pick your subscriptions'));

      // Netflix tile has no checkmark before the tap.
      final netflixCard = find.ancestor(
        of: find.text('Netflix'),
        matching: find.byType(Card),
      );
      expect(netflixCard, findsOneWidget);
      expect(
        find.descendant(of: netflixCard, matching: find.byIcon(Icons.check)),
        findsNothing,
      );

      // Tap → selected (checkmark appears, counter shows).
      await tester.tap(find.text('Netflix'));
      await tester.pump();
      expect(
        find.descendant(of: netflixCard, matching: find.byIcon(Icons.check)),
        findsOneWidget,
      );
      expect(find.text('1 selected — they will pre-fill your add form'),
          findsOneWidget);

      // Tap again → deselected.
      await tester.tap(find.text('Netflix'));
      await tester.pump();
      expect(
        find.descendant(of: netflixCard, matching: find.byIcon(Icons.check)),
        findsNothing,
      );
    });

    testWidgets('selected preset pre-fills the first add form',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final harness = WidgetHarness();
      // Simulate the onboarding presets step having persisted a selection.
      await harness.settingsRepo.set('onboardingPresets', 'netflix');

      await tester.pumpWidget(harness.scope(child: const SubTrackApp()));
      await pumpUntilFound(tester, find.byType(NavigationBar));

      // Add flow: FAB → the form is pre-filled from the pending preset
      // (name + cancellation URL; price/cycle never pre-filled).
      await tester.tap(find.text('Subscriptions'));
      await pumpUntilFound(tester, find.byType(FloatingActionButton));
      await tester.tap(find.byType(FloatingActionButton));
      await pumpUntilFound(tester, find.widgetWithText(FilledButton, 'Save'));

      expect(find.text('Netflix'), findsOneWidget);
      expect(
        find.text('https://www.netflix.com/account/cancelmembership'),
        findsOneWidget,
      );

      // After saving, the preset is consumed (queue empty → next add form
      // starts blank).
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Amount'),
        '14.99',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await pumpUntilFound(tester, find.text('Netflix'));
      expect(await harness.settingsRepo.get('onboardingPresets'), isEmpty);

      // Let the pop transition finish — otherwise the fading route still
      // absorbs taps and the form stays in the tree (duplicate finders).
      await tester.pump(const Duration(milliseconds: 400));

      // Next add form starts empty again (no pre-fill). Note: the list
      // behind the pushed route still shows the Netflix tile (indexed-stack
      // shell keeps branches alive), so assert on the field's controller.
      await tester.tap(find.byType(FloatingActionButton));
      await pumpUntilFound(tester, find.widgetWithText(FilledButton, 'Save'));
      final secondNameField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Name'),
      );
      expect(secondNameField.controller?.text ?? '', isEmpty);
    });
  });

  group('Bug 2 — subscription list right overflow', () {
    testWidgets('long VND amount renders without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final harness = WidgetHarness(
        subscriptions: [
          _sub(
            id: 's1',
            name: 'Premium Plan',
            currency: 'VND',
            amountMinor: 1234567890,
          ),
        ],
      );

      await tester.pumpWidget(harness.scope(child: const SubTrackApp()));
      await pumpUntilFound(tester, find.byType(NavigationBar));

      // Any RenderFlex right-overflow throws during the test → auto-fail.
      await tester.tap(find.text('Subscriptions'));
      await pumpUntilFound(tester, find.text('Premium Plan'));
      await tester.pump();
      expect(find.text('Premium Plan'), findsOneWidget);
    });
  });

  group('Bug 3 — settings appearance row', () {
    testWidgets('theme SegmentedButton fits a narrow screen', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final harness = WidgetHarness();

      await tester.pumpWidget(harness.scope(child: const SubTrackApp()));
      await pumpUntilFound(tester, find.byType(NavigationBar));

      await tester.tap(find.text('More'));
      await pumpUntilFound(tester, find.text('Settings'));
      await tester.tap(find.text('Settings'));
      await pumpUntilFound(tester, find.text('Appearance'));
      await tester.pump();

      // Implicit assertion: a squeezed SegmentedButton overflows → test fails.
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.byType(SegmentedButton<ThemeMode>), findsOneWidget);
    });
  });

  group('Bug 4 — category tap highlight', () {
    Widget categoryApp(Widget child) {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      );
    }

    testWidgets('tapping a category toggles the selected highlight',
        (tester) async {
      final harness = WidgetHarness(
        categories: [
          Category(
            id: 'streaming',
            name: 'Streaming',
            iconEmoji: '📺',
            colorHex: '#E50914',
            isDefault: true,
          ),
        ],
      );

      await tester.pumpWidget(
        harness.scope(child: categoryApp(const CategoriesScreen())),
      );
      await pumpUntilFound(tester, find.text('Streaming'));

      final tile = find.widgetWithText(ListTile, 'Streaming');
      expect(tester.widget<ListTile>(tile).selected, isFalse);

      await tester.tap(tile);
      await tester.pump();
      expect(tester.widget<ListTile>(tile).selected, isTrue);

      await tester.tap(tile);
      await tester.pump();
      expect(tester.widget<ListTile>(tile).selected, isFalse);
    });
  });
}

Subscription _sub({
  required String id,
  required String name,
  required int amountMinor,
  String currency = 'USD',
  String? categoryId,
}) {
  return Subscription(
    id: id,
    name: name,
    amountMinor: amountMinor,
    currency: currency,
    billingCycle: BillingCycle.monthly,
    startDate: DateTime(2026, 1, 1),
    nextBillingDate: DateTime(2026, 8, 15),
    billingAnchorDay: 1,
    isTrial: false,
    status: SubscriptionStatus.active,
    categoryId: categoryId,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}
