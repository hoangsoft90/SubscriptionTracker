import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:subtrack/features/categories/domain/category.dart';
import 'package:subtrack/features/subscriptions/domain/billing_cycle.dart';
import 'package:subtrack/features/subscriptions/domain/subscription.dart';
import 'package:subtrack/features/subscriptions/domain/subscription_status.dart';
import 'package:subtrack/features/subscriptions/presentation/subscription_detail_screen.dart';
import 'package:subtrack/l10n/app_localizations.dart';

import 'widget_harness.dart';

Subscription _sub({String? categoryId}) {
  return Subscription(
    id: 's1',
    name: 'Netflix',
    amountMinor: 1499,
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

/// Pumps the detail screen with the same localization setup as the real app.
Widget _pump(WidgetHarness harness, String subscriptionId) {
  return harness.scope(
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: SubscriptionDetailScreen(subscriptionId: subscriptionId),
    ),
  );
}

void main() {
  testWidgets('detail shows the category name, not the raw id/slug',
      (tester) async {
    final harness = WidgetHarness(
      subscriptions: [_sub(categoryId: 'streaming')],
      categories: const [
        Category(
          id: 'streaming',
          name: 'Streaming',
          iconEmoji: '📺',
          isDefault: true,
        ),
      ],
    );
    await tester.pumpWidget(_pump(harness, 's1'));
    await tester.pumpAndSettle();

    expect(find.text('Streaming'), findsOneWidget);
    // The raw slug/id must not leak into the UI.
    expect(find.text('streaming'), findsNothing);
  });

  testWidgets('detail falls back to Uncategorized when category is missing',
      (tester) async {
    // A backup could restore a subscription whose category no longer exists.
    final harness = WidgetHarness(subscriptions: [_sub(categoryId: 'ghost')]);
    await tester.pumpWidget(_pump(harness, 's1'));
    await tester.pumpAndSettle();

    expect(find.text('Uncategorized'), findsOneWidget);
  });
}
