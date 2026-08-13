import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Outcome of a purchase/restore attempt.
enum PurchaseOutcome { purchased, cancelled, notFound, failed }

/// Thin boundary over the platform store SDK (StoreKit 2 / Play Billing) —
/// swapped for a fake in tests. The store remains the source of truth for
/// purchases and restore; the app persists the granted entitlement locally
/// (spec §2.8).
abstract class PurchaseGateway {
  /// The single non-consumable Lifetime Pro product.
  static const productId = 'subtrack_lifetime_pro';

  Future<bool> isAvailable();

  Future<ProductDetails?> getProduct();

  Future<PurchaseOutcome> buy();

  Future<PurchaseOutcome> restore();
}

/// `in_app_purchase`-backed gateway. One non-consumable product, no recurring
/// billing. Store verification happens through the platform SDK; no app
/// server is involved.
class StorePurchaseGateway implements PurchaseGateway {
  final InAppPurchase _purchase = InAppPurchase.instance;

  @override
  Future<bool> isAvailable() async {
    if (kIsWeb) return false; // no store SDK on web
    return _purchase.isAvailable();
  }

  @override
  Future<ProductDetails?> getProduct() async {
    try {
      final response = await _purchase
          .queryProductDetails({PurchaseGateway.productId});
      return response.productDetails.isEmpty
          ? null
          : response.productDetails.first;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<PurchaseOutcome> buy() async {
    if (!await isAvailable()) return PurchaseOutcome.cancelled;
    final product = await getProduct();
    if (product == null) return PurchaseOutcome.notFound;
    try {
      _purchase.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      return await _awaitPurchaseResult(
        timeout: const Duration(seconds: 60),
      );
    } catch (_) {
      return PurchaseOutcome.failed;
    }
  }

  @override
  Future<PurchaseOutcome> restore() async {
    try {
      await _purchase.restorePurchases();
      return await _awaitPurchaseResult(
        timeout: const Duration(seconds: 30),
      );
    } catch (_) {
      return PurchaseOutcome.failed;
    }
  }

  Future<PurchaseOutcome> _awaitPurchaseResult({required Duration timeout}) {
    return _purchase.purchaseStream
        .firstWhere((details) =>
            details.any((p) => p.productID == PurchaseGateway.productId))
        .then((details) {
          final purchase = details
              .firstWhere((p) => p.productID == PurchaseGateway.productId);
          return switch (purchase.status) {
            PurchaseStatus.purchased ||
            PurchaseStatus.restored => PurchaseOutcome.purchased,
            PurchaseStatus.canceled => PurchaseOutcome.cancelled,
            _ => PurchaseOutcome.failed,
          };
        })
        .timeout(timeout, onTimeout: () => PurchaseOutcome.failed);
  }
}
