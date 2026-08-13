import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'purchase_gateway.dart';

/// Persisted Lifetime Pro entitlement + purchase/restore orchestration
/// (spec §2.8). The store is the source of truth for restore; the granted
/// flag is persisted locally so offline launches stay consistent.
class ProEntitlementController extends AsyncNotifier<bool> {
  static const _key = 'proEntitlement';

  @override
  Future<bool> build() async {
    final repo = await ref.watch(settingsRepositoryProvider.future);
    return (await repo.get(_key)) == 'true';
  }

  PurchaseGateway get _gateway => ref.read(purchaseGatewayProvider);

  /// Runs the platform purchase flow and grants Pro on success.
  Future<PurchaseOutcome> purchase() async {
    final outcome = await _gateway.buy();
    if (outcome == PurchaseOutcome.purchased) {
      await _grant();
    }
    return outcome;
  }

  /// Restores a prior purchase via the store SDK — no app backend.
  Future<PurchaseOutcome> restore() async {
    final outcome = await _gateway.restore();
    if (outcome == PurchaseOutcome.purchased) {
      await _grant();
    }
    return outcome;
  }

  Future<void> _grant() async {
    final repo = await ref.read(settingsRepositoryProvider.future);
    await repo.set(_key, 'true');
    state = const AsyncData(true);
  }
}

final proEntitlementControllerProvider =
    AsyncNotifierProvider<ProEntitlementController, bool>(
  ProEntitlementController.new,
);
