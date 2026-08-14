import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:subtrack/app/app.dart';

import 'm1_widget_test.dart' show pumpUntilFound;
import 'widget_harness.dart';

/// Reproduction tests for the reported bug: adding a subscription does not
/// appear in the subscriptions tab until the app is reopened, and a
/// pull-to-refresh makes the data disappear.
///
/// Covers the full user flow: add via UI → check list → simulate an app
/// restart (fresh harness + fresh ProviderScope over the SAME storage) →
/// check again → pull-to-refresh (Home + subscriptions) → check again.
void main() {
  Future<void> pumpApp(WidgetTester tester, WidgetHarness harness) async {
    await tester.pumpWidget(harness.scope(child: const SubTrackApp()));
    await pumpUntilFound(tester, find.byType(NavigationBar));
    await tester.pumpAndSettle();
  }

  Future<void> addSubscriptionViaUi(
    WidgetTester tester, {
    String name = 'Netflix',
    String amount = '14.99',
  }) async {
    await tester.tap(find.text('Subscriptions'));
    await pumpUntilFound(tester, find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await pumpUntilFound(tester, find.text('Add subscription'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), name);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Amount'),
      amount,
    );
    final saveButton = find.widgetWithText(FilledButton, 'Save');
    await tester.dragUntilVisible(
      saveButton,
      find.byType(ListView).last,
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
  }

  testWidgets('added subscription shows in the list immediately', (tester) async {
    final harness = WidgetHarness();
    await pumpApp(tester, harness);
    await addSubscriptionViaUi(tester);

    expect(find.text('Netflix'), findsOneWidget);
  });

  testWidgets('data survives app restart (fresh scope, same storage)',
      (tester) async {
    final harness = WidgetHarness();
    await pumpApp(tester, harness);
    await addSubscriptionViaUi(tester);
    expect(find.text('Netflix'), findsOneWidget);

    // Simulate reopening the app: a brand-new widget tree + ProviderScope
    // over the SAME underlying storage (the harness fakes persist).
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await pumpApp(tester, harness);
    await tester.tap(find.text('Subscriptions'));
    await tester.pumpAndSettle();

    // The subscription must still be listed (reported bug: only visible
    // after reopening — but this must hold on the CURRENT code).
    expect(find.text('Netflix'), findsOneWidget);
  });

  testWidgets('data survives pull-to-refresh on Home (no disappear)',
      (tester) async {
    final harness = WidgetHarness();
    await pumpApp(tester, harness);
    await addSubscriptionViaUi(tester);
    expect(find.text('Netflix'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.fling(
      find.byType(ListView).first,
      const Offset(0, 300),
      1000,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Subscriptions'));
    await tester.pumpAndSettle();
    expect(find.text('Netflix'), findsOneWidget);
  });

  testWidgets('pull-down on the subscriptions list reloads from storage and '
      'keeps the row', (tester) async {
    final harness = WidgetHarness();
    await pumpApp(tester, harness);
    await addSubscriptionViaUi(tester);
    expect(find.text('Netflix'), findsOneWidget);

    // Pull down directly on the subscriptions list → the RefreshIndicator
    // re-reads storage. The row must survive (and the refresh must actually
    // trigger, i.e. settle back to a populated list).
    await tester.fling(
      find.byType(ListView).last,
      const Offset(0, 300),
      1000,
    );
    await tester.pumpAndSettle();

    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(find.text('Netflix'), findsOneWidget);
  });
}
