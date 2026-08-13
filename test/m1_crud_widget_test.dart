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
  group('Subscriptions CRUD widget flows (task 3.7)', () {
    testWidgets('add flow: FAB → form → save → appears in list', (tester) async {
      // Tall viewport so the Save button (bottom of the form ListView) is
      // built and hittable without scrolling.
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final harness = WidgetHarness();

      await tester.pumpWidget(harness.scope(child: const SubTrackApp()));
      await pumpUntilFound(tester, find.byType(NavigationBar));

      // Go to Subscriptions tab, tap FAB.
      await tester.tap(find.text('Subscriptions'));
      await pumpUntilFound(tester, find.byType(FloatingActionButton));
      await tester.tap(find.byType(FloatingActionButton));

      // Add form: name + amount, then save.
      await pumpUntilFound(tester, find.widgetWithText(FilledButton, 'Save'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'Netflix',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Amount'),
        '14.99',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));

      // Back on the list, the new subscription shows with formatted amount
      // (Money.format is symbol-less in this intl setup: "14.99"). The
      // indexed-stack shell keeps the Home branch alive, so the dashboard
      // monthly total may also render 14.99 — assert at least one match.
      await pumpUntilFound(tester, find.text('Netflix'));
      expect(find.text('14.99'), findsWidgets);
    });

    testWidgets('edit preserves untouched fields', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final harness = WidgetHarness(
        subscriptions: [
          _sub(
            id: 's1',
            name: 'Netflix',
            amountMinor: 1499,
            categoryId: 'streaming',
          ),
        ],
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

      await tester.pumpWidget(harness.scope(child: const SubTrackApp()));
      await pumpUntilFound(tester, find.byType(NavigationBar));

      await tester.tap(find.text('Subscriptions'));
      await pumpUntilFound(tester, find.text('Netflix'));
      await tester.tap(find.text('Netflix'));

      // Wait for the page transition to finish — the AppBar edit icon slides
      // in from off-screen (x > viewport) until the transition completes.
      await pumpUntilFound(tester, find.byIcon(Icons.edit_outlined));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byIcon(Icons.edit_outlined));

      // Amount is pre-filled; change only the amount.
      await pumpUntilFound(
        tester,
        find.widgetWithText(FilledButton, 'Save'),
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Amount'),
        '19.99',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));

      // Price-change confirmation (plan2_final §7): 14.99 → 19.99 shows the
      // PRICE CHANGED dialog — confirm it so the new price is persisted.
      await pumpUntilFound(tester, find.text('Save new price'));
      await tester.tap(find.text('Save new price'));

      // Back on detail: amount updated, name + category untouched. The
      // category renders its display *name*, not the raw id (fix: raw
      // id/slug used to be shown).
      await pumpUntilFound(tester, find.text('Netflix'));
      expect(find.text('19.99 USD'), findsOneWidget);
      expect(find.text('Streaming'), findsOneWidget);
    });

    testWidgets('delete requires confirmation and removes the item',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final harness = WidgetHarness(
        subscriptions: [_sub(id: 's1', name: 'Spotify', amountMinor: 1099)],
      );

      await tester.pumpWidget(harness.scope(child: const SubTrackApp()));
      await pumpUntilFound(tester, find.byType(NavigationBar));

      await tester.tap(find.text('Subscriptions'));
      await pumpUntilFound(tester, find.text('Spotify'));
      await tester.tap(find.text('Spotify'));

      // Detail → Delete → confirm dialog.
      await pumpUntilFound(tester, find.text('Delete'));
      await tester.tap(find.text('Delete'));
      await pumpUntilFound(tester, find.text('Delete subscription?'));

      // Cancel first: item stays.
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pump();
      await tester.tap(find.text('Delete'));
      await pumpUntilFound(tester, find.text('Delete subscription?'));

      // Confirm: item removed, empty state shown.
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await pumpUntilFound(tester, find.text('No subscriptions yet'));
      expect(find.text('Spotify'), findsNothing);
    });

    testWidgets('search filters the list case-insensitively', (tester) async {
      final harness = WidgetHarness(
        subscriptions: [
          _sub(id: 's1', name: 'Netflix', amountMinor: 1499),
          _sub(id: 's2', name: 'Spotify', amountMinor: 1099),
        ],
      );

      await tester.pumpWidget(harness.scope(child: const SubTrackApp()));
      await pumpUntilFound(tester, find.byType(NavigationBar));

      await tester.tap(find.text('Subscriptions'));
      await pumpUntilFound(tester, find.text('Netflix'));

      await tester.enterText(
        find.widgetWithText(TextField, 'Search subscriptions'),
        'NET',
      );
      await pumpUntilFound(tester, find.text('Netflix'));
      expect(find.text('Spotify'), findsNothing);
      expect(find.text('No matches'), findsNothing);
    });
  });

  group('Categories widget flows (task 5.4)', () {
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

    testWidgets('default category cannot be deleted', (tester) async {
      final harness = WidgetHarness(
        categories: [
          Category(
            id: 'streaming',
            name: 'Streaming',
            iconEmoji: '📺',
            colorHex: '#E50914',
            isDefault: true,
          ),
          Category(
            id: 'custom',
            name: 'My Custom',
            iconEmoji: '🏷️',
            colorHex: '#10B981',
          ),
        ],
      );

      await tester.pumpWidget(
        harness.scope(child: categoryApp(const CategoriesScreen())),
      );
      await pumpUntilFound(tester, find.text('Streaming'));

      // Default has no delete action.
      expect(
        find.descendant(
          of: find.widgetWithText(ListTile, 'Streaming'),
          matching: find.byIcon(Icons.delete_outline),
        ),
        findsNothing,
      );
    });

    testWidgets('custom category delete removes it from the list',
        (tester) async {
      final harness = WidgetHarness(
        categories: [
          Category(
            id: 'custom',
            name: 'My Custom',
            iconEmoji: '🏷️',
            colorHex: '#10B981',
          ),
        ],
      );

      await tester.pumpWidget(
        harness.scope(child: categoryApp(const CategoriesScreen())),
      );
      await pumpUntilFound(tester, find.text('My Custom'));

      await tester.tap(
        find.descendant(
          of: find.widgetWithText(ListTile, 'My Custom'),
          matching: find.byIcon(Icons.delete_outline),
        ),
      );
      await pumpUntilFound(tester, find.text('Categories'));
      expect(find.text('My Custom'), findsNothing);
    });
  });
}

Subscription _sub({
  required String id,
  required String name,
  required int amountMinor,
  String? categoryId,
}) {
  return Subscription(
    id: id,
    name: name,
    amountMinor: amountMinor,
    currency: 'USD',
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
