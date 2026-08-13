import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:subtrack/app/app.dart';

import 'widget_harness.dart';

void main() {
  group('Onboarding gate', () {
    testWidgets('shows onboarding when not completed', (tester) async {
      final harness = WidgetHarness(onboardingCompleted: false);

      await tester.pumpWidget(harness.scope(child: const SubTrackApp()));
      await pumpUntilFound(
        tester,
        find.text('Private by design'),
      );

      expect(find.text('Private by design'), findsOneWidget);
    });
  });

  group('Theme', () {
    testWidgets('dark theme applies via settings', (tester) async {
      final harness = WidgetHarness(themeMode: 'dark');

      await tester.pumpWidget(
        harness.scope(child: const SubTrackApp()),
      );
      // Wait until the settings load AND the theme is actually applied
      // inside MaterialApp (NavigationBar may appear while settings load).
      await pumpUntilTheme(tester, Brightness.dark);

      final context = tester.element(find.byType(NavigationBar));
      expect(Theme.of(context).brightness, Brightness.dark);
    });

    testWidgets('light theme is default', (tester) async {
      final harness = WidgetHarness();

      await tester.pumpWidget(
        harness.scope(child: const SubTrackApp()),
      );
      await pumpUntilFound(tester, find.byType(NavigationBar));
      await tester.pump();

      final context = tester.element(find.byType(NavigationBar));
      expect(Theme.of(context).brightness, Brightness.light);
    });
  });

  group('Empty states', () {
    testWidgets('home shows empty state with CTA when no subscriptions',
        (tester) async {
      final harness = WidgetHarness();

      await tester.pumpWidget(
        harness.scope(child: const SubTrackApp()),
      );
      await pumpUntilFound(tester, find.text('Nothing tracked yet'));

      expect(find.text('Nothing tracked yet'), findsOneWidget);
      expect(find.text('Add subscription'), findsOneWidget);
    });
  });

  group('Accessibility', () {
    testWidgets('FAB has semantic label', (tester) async {
      final harness = WidgetHarness();

      await tester.pumpWidget(
        harness.scope(child: const SubTrackApp()),
      );
      await pumpUntilFound(tester, find.byType(NavigationBar));

      await tester.tap(find.text('Subscriptions'));
      await pumpUntilFound(tester, find.byType(FloatingActionButton));

      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);
      // The FAB exposes its tooltip as the accessible label; assert via the
      // rendered tooltip text instead of raw semantics node internals.
      final tooltip = find.byTooltip('Add subscription');
      expect(tooltip, findsOneWidget);
    });
  });
}

/// Pumps frames until [finder] matches or [timeout] elapses — avoids
/// `pumpAndSettle` hanging on an async provider's loading spinner.
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out waiting for $finder');
}

/// Pumps frames until the theme inside [MaterialApp] reaches [brightness]
/// (or [timeout] elapses). Settings load asynchronously, so the app may
/// render with the default theme for a few frames first.
Future<void> pumpUntilTheme(
  WidgetTester tester,
  Brightness brightness, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 50));
    if (find.byType(NavigationBar).evaluate().isNotEmpty) {
      final context = tester.element(find.byType(NavigationBar));
      if (Theme.of(context).brightness == brightness) return;
    }
  }
  fail('Timed out waiting for $brightness theme');
}
