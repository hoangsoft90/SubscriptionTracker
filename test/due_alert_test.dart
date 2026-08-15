import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:subtrack/features/decision/due_alert.dart';
import 'package:subtrack/features/decision/presentation/due_alert_dialog.dart';
import 'package:subtrack/features/decision/review_queue.dart';
import 'package:subtrack/features/subscriptions/domain/billing_cycle.dart';
import 'package:subtrack/features/subscriptions/domain/subscription.dart';
import 'package:subtrack/features/subscriptions/domain/subscription_status.dart';
import 'package:subtrack/l10n/app_localizations.dart';

// Fixed "now" for deterministic tests.
final _now = DateTime(2026, 8, 10, 12, 0);

Subscription _sub({
  String id = 's1',
  String name = 'Netflix',
  DateTime? nextBilling,
  SubscriptionStatus status = SubscriptionStatus.active,
  bool isTrial = false,
  DateTime? trialEnd,
  DateTime? lastReviewedAt,
  int? previousAmountMinor,
}) {
  return Subscription(
    id: id,
    name: name,
    amountMinor: 1499,
    currency: 'USD',
    billingCycle: BillingCycle.monthly,
    startDate: DateTime(2026, 7, 1),
    nextBillingDate: nextBilling ?? DateTime(2026, 8, 15),
    billingAnchorDay: 15,
    isTrial: isTrial,
    trialEndDate: trialEnd,
    status: status,
    createdAt: DateTime(2026, 7, 1),
    updatedAt: DateTime(2026, 7, 1),
    lastReviewedAt: lastReviewedAt,
    reviewIntervalDays: 90,
    previousAmountMinor: previousAmountMinor,
  );
}

void main() {
  group('DueAlertService (high-priority items only)', () {
    test('empty when no subscription is due soon', () {
      expect(
        const DueAlertService().compute(
          subscriptions: [
            _sub(id: 'a', name: 'A', nextBilling: DateTime(2026, 9, 1)),
          ],
          now: _now,
        ),
        isEmpty,
      );
    });

    test('renewal today is included', () {
      final items = const DueAlertService().compute(
        subscriptions: [_sub(id: 'a', name: 'A', nextBilling: DateTime(2026, 8, 10))],
        now: _now,
      );
      expect(items.single.subscription.id, 'a');
      expect(items.single.reason, ReviewReason.renewalDue);
    });

    test('renewal tomorrow is included', () {
      final items = const DueAlertService().compute(
        subscriptions: [_sub(id: 'a', name: 'A', nextBilling: DateTime(2026, 8, 11))],
        now: _now,
      );
      expect(items.single.reason, ReviewReason.renewalDue);
    });

    test('renewal 2+ days out is excluded', () {
      expect(
        const DueAlertService().compute(
          subscriptions: [_sub(id: 'a', name: 'A', nextBilling: DateTime(2026, 8, 13))],
          now: _now,
        ),
        isEmpty,
      );
    });

    test('trial ending within 3 days is included', () {
      final items = const DueAlertService().compute(
        subscriptions: [
          _sub(id: 't', name: 'Canva', isTrial: true, trialEnd: DateTime(2026, 8, 12)),
        ],
        now: _now,
      );
      expect(items.single.reason, ReviewReason.trialEnding);
    });

    test('trial ending beyond 3 days is excluded', () {
      expect(
        const DueAlertService().compute(
          subscriptions: [
            _sub(id: 't', name: 'Canva', isTrial: true, trialEnd: DateTime(2026, 8, 16)),
          ],
          now: _now,
        ),
        isEmpty,
      );
    });

    test('medium items (price changed / stale) are never alerted', () {
      expect(
        const DueAlertService().compute(
          subscriptions: [
            _sub(id: 'p', name: 'P', previousAmountMinor: 999),
            _sub(id: 'o', name: 'Old', lastReviewedAt: _now.subtract(const Duration(days: 200))),
          ],
          now: _now,
        ),
        isEmpty,
      );
    });

    test('cancelled / archived / pending-cancellation are excluded', () {
      expect(
        const DueAlertService().compute(
          subscriptions: [
            _sub(id: 'c', name: 'C', status: SubscriptionStatus.cancelled),
            _sub(id: 'a', name: 'A', status: SubscriptionStatus.archived),
            _sub(
              id: 'p',
              name: 'P',
              status: SubscriptionStatus.pendingCancellation,
              isTrial: true,
              trialEnd: DateTime(2026, 8, 11),
            ),
          ],
          now: _now,
        ),
        isEmpty,
      );
    });

    test('high items keep the queue priority/date order', () {
      final items = const DueAlertService().compute(
        subscriptions: [
          _sub(id: 'b', name: 'B', isTrial: true, trialEnd: DateTime(2026, 8, 11)),
          _sub(id: 'a', name: 'A', nextBilling: DateTime(2026, 8, 10)),
        ],
        now: _now,
      );
      expect(items.map((e) => e.subscription.id), ['a', 'b']);
    });
  });

  group('DueAlertDialog widget', () {
    testWidgets('lists due subscriptions with reasons and action buttons',
        (tester) async {
      final items = const DueAlertService().compute(
        subscriptions: [
          _sub(id: 'a', name: 'Netflix', nextBilling: DateTime(2026, 8, 10)),
          _sub(
            id: 't',
            name: 'Canva',
            isTrial: true,
            trialEnd: DateTime(2026, 8, 12),
          ),
        ],
        now: _now,
      );

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => DueAlertDialog(items: items),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Subscriptions due soon'), findsOneWidget);
      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text('Canva'), findsOneWidget);
      expect(find.text('Netflix renews today'), findsOneWidget);
      expect(find.textContaining('trial ends in'), findsOneWidget);
      expect(find.text('View all'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);

      // Dismiss closes the dialog.
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('Subscriptions due soon'), findsNothing);
    });
  });
}
