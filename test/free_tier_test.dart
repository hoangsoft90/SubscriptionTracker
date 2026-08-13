import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:subtrack/core/providers.dart';
import 'package:subtrack/features/paywall/entitlement_controller.dart';
import 'package:subtrack/features/paywall/free_tier.dart';
import 'package:subtrack/features/paywall/purchase_gateway.dart';
import 'package:subtrack/features/subscriptions/domain/billing_cycle.dart';
import 'package:subtrack/features/subscriptions/domain/subscription.dart';
import 'package:subtrack/features/subscriptions/domain/subscription_status.dart';

import 'fakes.dart';

void main() {
  group('freeTierState (spec §2.8)', () {
    test('1–8 active → no interference', () {
      for (var count = 1; count <= 8; count++) {
        expect(
          freeTierState(activeCount: count, isPro: false),
          FreeTierState.noInterference,
          reason: 'count=$count',
        );
      }
    });

    test('9–10 active → slots left banner', () {
      expect(
        freeTierState(activeCount: 9, isPro: false),
        FreeTierState.slotsLeft,
      );
      expect(
        freeTierState(activeCount: 10, isPro: false),
        FreeTierState.slotsLeft,
      );
    });

    test('11+ active → hard block', () {
      for (final count in [11, 12, 20]) {
        expect(
          freeTierState(activeCount: count, isPro: false),
          FreeTierState.hardBlock,
          reason: 'count=$count',
        );
      }
    });

    test('Pro lifts the limit entirely', () {
      for (final count in [1, 9, 10, 11, 50]) {
        expect(
          freeTierState(activeCount: count, isPro: true),
          FreeTierState.noInterference,
          reason: 'count=$count',
        );
      }
    });

    test('freeSlotsLeft clamps at the limit', () {
      expect(freeSlotsLeft(7), 3);
      expect(freeSlotsLeft(9), 1);
      expect(freeSlotsLeft(10), 0);
      expect(freeSlotsLeft(15), 0);
    });
  });

  group('paywallSlotCount (plan2_final §5)', () {
    Subscription slotSub(String id, SubscriptionStatus status) {
      return Subscription(
        id: id,
        name: id,
        amountMinor: 100,
        currency: 'USD',
        billingCycle: BillingCycle.monthly,
        startDate: DateTime(2026, 1, 1),
        nextBillingDate: DateTime(2026, 8, 15),
        billingAnchorDay: 1,
        isTrial: false,
        status: status,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
    }

    test('ACTIVE + PENDING_CANCELLATION consume slots; '
        'CANCELLED/ARCHIVED do not', () {
      final subs = [
        slotSub('a', SubscriptionStatus.active),
        slotSub('p', SubscriptionStatus.pendingCancellation),
        slotSub('c', SubscriptionStatus.cancelled),
        slotSub('x', SubscriptionStatus.archived),
      ];
      expect(paywallSlotCount(subs), 2);
    });

    test('10 pending-cancellation subs still consume all 10 slots', () {
      final subs = [
        for (var i = 0; i < 10; i++)
          slotSub('p$i', SubscriptionStatus.pendingCancellation),
      ];
      expect(paywallSlotCount(subs), 10);
      // Adding an 11th while 10 slots are pending → the free-tier guard still
      // engages (no "cancel all to dodge the paywall" loophole).
      expect(
        freeTierState(activeCount: paywallSlotCount(subs), isPro: false),
        FreeTierState.slotsLeft,
      );
    });
  });

  group('ProEntitlementController (offline, no backend)', () {
    ProviderContainer makeContainer(FakeSettingsRepository settings,
        {FakePurchaseGateway? gateway}) {
      return ProviderContainer(overrides: [
        settingsRepositoryProvider.overrideWith((ref) => settings),
        purchaseGatewayProvider
            .overrideWithValue(gateway ?? FakePurchaseGateway() as PurchaseGateway),
      ]);
    }

    test('purchase success grants Pro and persists it', () async {
      final settings = FakeSettingsRepository();
      final gateway = FakePurchaseGateway(buyResult: PurchaseOutcome.purchased);
      final container = makeContainer(settings, gateway: gateway);

      await container.read(proEntitlementControllerProvider.future);
      final notifier = container.read(proEntitlementControllerProvider.notifier);
      expect(container.read(proEntitlementControllerProvider).value, false);

      final outcome = await notifier.purchase();
      expect(outcome, PurchaseOutcome.purchased);
      expect(container.read(proEntitlementControllerProvider).value, true);
      expect(await settings.get('proEntitlement'), 'true');
      container.dispose();
    });

    test('cancelled purchase does not grant Pro', () async {
      final settings = FakeSettingsRepository();
      final gateway =
          FakePurchaseGateway(buyResult: PurchaseOutcome.cancelled);
      final container = makeContainer(settings, gateway: gateway);
      await container.read(proEntitlementControllerProvider.future);

      final outcome = await container
          .read(proEntitlementControllerProvider.notifier)
          .purchase();
      expect(outcome, PurchaseOutcome.cancelled);
      expect(container.read(proEntitlementControllerProvider).value, false);
      expect(await settings.get('proEntitlement'), isNull);
      container.dispose();
    });

    test('restore works without an app backend and persists Pro', () async {
      // Fresh device with no persisted flag, but the store knows the user
      // previously purchased (simulated by the gateway returning purchased).
      final settings = FakeSettingsRepository();
      final gateway =
          FakePurchaseGateway(restoreResult: PurchaseOutcome.purchased);
      final container = makeContainer(settings, gateway: gateway);

      final outcome = await container
          .read(proEntitlementControllerProvider.notifier)
          .restore();
      expect(outcome, PurchaseOutcome.purchased);
      expect(container.read(proEntitlementControllerProvider).value, true);
      expect(await settings.get('proEntitlement'), 'true');
      container.dispose();
    });

    test('entitlement survives a fresh container (persisted flag)', () async {
      final settings = FakeSettingsRepository({'proEntitlement': 'true'});
      final container = makeContainer(settings);

      await container.read(proEntitlementControllerProvider.future);
      expect(container.read(proEntitlementControllerProvider).value, true);
      container.dispose();
    });
  });
}
