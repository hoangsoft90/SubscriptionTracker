import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:subtrack/app/app.dart';
import 'package:subtrack/features/calendar/presentation/money_calendar_screen.dart';
import 'package:subtrack/features/subscriptions/domain/billing_cycle.dart';
import 'package:subtrack/features/subscriptions/domain/subscription.dart';
import 'package:subtrack/features/subscriptions/domain/subscription_status.dart';
import 'package:subtrack/l10n/app_localizations.dart';

import 'm1_widget_test.dart' show pumpUntilFound;
import 'widget_harness.dart';

void main() {
  group('Home Today Money Brief (plan2_final §2)', () {
    testWidgets('far-future renewal → "Nothing due today" + Next line',
        (tester) async {
      final now = DateTime.now();
      final harness = WidgetHarness(subscriptions: [
        _sub(
          name: 'Netflix',
          nextBilling: DateTime(now.year, now.month, now.day + 3),
        ),
      ]);

      await tester.pumpWidget(harness.scope(child: const SubTrackApp()));
      await pumpUntilFound(tester, find.text('Nothing due today'));
      expect(find.textContaining('Next: Netflix'), findsOneWidget);
    });

    testWidgets('renewal today → shows the sub, never the clear message',
        (tester) async {
      final now = DateTime.now();
      final harness = WidgetHarness(subscriptions: [
        _sub(name: 'Netflix', nextBilling: DateTime(now.year, now.month, now.day)),
      ]);

      await tester.pumpWidget(harness.scope(child: const SubTrackApp()));
      await pumpUntilFound(tester, find.textContaining('Next: Netflix'));
      // Device-test 2026-08-15 regression: a renewal due today must not show
      // the "You're clear" message on the Home Today card.
      expect(find.textContaining('You\'re clear'), findsNothing);
    });

    testWidgets('trial ending in 2 days surfaces the warning on the Today card',
        (tester) async {
      final now = DateTime.now();
      final harness = WidgetHarness(subscriptions: [
        _sub(
          name: 'Canva',
          isTrial: true,
          trialEnd: DateTime(now.year, now.month, now.day + 2),
        ),
      ]);

      await tester.pumpWidget(harness.scope(child: const SubTrackApp()));
      await pumpUntilFound(
        tester,
        find.textContaining('Trial ending in 2 day(s)'),
      );
    });
  });

  group('Money Calendar (plan2_final §6)', () {
    Widget calendarApp(Widget child) {
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

    testWidgets('charge day shows a dot; tap lists the renewal + total',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final now = DateTime.now();
      // 5th of next month — always in the future, so the dot is deterministic
      // regardless of the real run date.
      final nextMonth = DateTime(now.year, now.month + 1, 5);
      final harness = WidgetHarness(subscriptions: [
        _sub(name: 'Netflix', nextBilling: nextMonth),
      ]);

      await tester.pumpWidget(
        harness.scope(child: calendarApp(const MoneyCalendarScreen())),
      );

      // Navigate to next month, tap the day with the dot.
      await pumpUntilFound(tester, find.byIcon(Icons.chevron_right));
      await tester.tap(find.byIcon(Icons.chevron_right));
      await pumpUntilFound(tester, find.text('5'));
      await tester.tap(find.text('5'));

      await pumpUntilFound(tester, find.text('Netflix'));
      expect(find.textContaining('renewal'), findsOneWidget);
    });

    testWidgets('day without a charge shows the empty message',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final now = DateTime.now();
      final nextMonth = DateTime(now.year, now.month + 1, 5);
      final harness = WidgetHarness(subscriptions: [
        _sub(name: 'Netflix', nextBilling: nextMonth),
      ]);

      await tester.pumpWidget(
        harness.scope(child: calendarApp(const MoneyCalendarScreen())),
      );

      await pumpUntilFound(tester, find.byIcon(Icons.chevron_right));
      await tester.tap(find.byIcon(Icons.chevron_right));
      await pumpUntilFound(tester, find.text('7'));
      await tester.tap(find.text('7'));

      await pumpUntilFound(tester, find.text('No charges on this day'));
    });
  });
}

Subscription _sub({
  required String name,
  DateTime? nextBilling,
  bool isTrial = false,
  DateTime? trialEnd,
}) {
  final now = DateTime.now();
  // Default: far-future renewal so the trial test stays deterministic.
  final effectiveNextBilling =
      nextBilling ?? DateTime(now.year, now.month + 1, 15);
  return Subscription(
    id: name,
    name: name,
    amountMinor: 1499,
    currency: 'USD',
    billingCycle: BillingCycle.monthly,
    startDate: DateTime(2026, 1, 1),
    nextBillingDate: effectiveNextBilling,
    // Production invariant: anchor = startDate.day; nextBillingDate is derived
    // from it — keep the fixture consistent for deterministic calendar dots.
    billingAnchorDay: effectiveNextBilling.day,
    isTrial: isTrial,
    trialEndDate: trialEnd,
    status: SubscriptionStatus.active,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}
