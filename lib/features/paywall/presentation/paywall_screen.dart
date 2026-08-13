import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/providers.dart';
import '../../subscriptions/application/subscription_list_controller.dart';
import '../../subscriptions/domain/subscription_status.dart';
import '../entitlement_controller.dart';
import '../purchase_gateway.dart';

/// One-time Lifetime Pro paywall (spec §2.8): a single non-consumable
/// product, no recurring billing, purchase + offline restore.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  ProductDetails? _product;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    final product = await ref.read(purchaseGatewayProvider).getProduct();
    if (mounted) setState(() => _product = product);
  }

  Future<void> _purchase() async {
    setState(() => _busy = true);
    final outcome = await ref
        .read(proEntitlementControllerProvider.notifier)
        .purchase();
    if (!mounted) return;
    setState(() => _busy = false);
    if (outcome == PurchaseOutcome.purchased) {
      _show(context.l10n.paywallPurchased);
    } else if (outcome != PurchaseOutcome.cancelled) {
      _show(context.l10n.backupErrorInvalidFile); // generic failure copy
    }
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    final outcome = await ref
        .read(proEntitlementControllerProvider.notifier)
        .restore();
    if (!mounted) return;
    setState(() => _busy = false);
    if (outcome == PurchaseOutcome.purchased) {
      _show(context.l10n.paywallPurchased);
    } else if (outcome != PurchaseOutcome.cancelled) {
      _show(context.l10n.backupErrorInvalidFile);
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isPro = ref.watch(proEntitlementControllerProvider).value ?? false;
    final listState = ref.watch(subscriptionListControllerProvider).value;
    final activeCount = listState == null
        ? 0
        : listState.subscriptions
              .where((s) => s.status == SubscriptionStatus.active)
              .length;
    // Deep-link edge case: when /paywall is reached directly (web URL,
    // notification, cold start) there is no back stack to pop — offer a way
    // home instead of leaving the user stranded. `maybeOf` keeps widget tests
    // (which render the screen without a router) working.
    final canPop = GoRouter.maybeOf(context)?.canPop() ?? false;

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        // Deep link with no back stack: system back goes home, not exit.
        if (!didPop) context.go('/home');
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.paywallTitle),
          automaticallyImplyLeading: canPop,
          leading: canPop
              ? null
              : IconButton(
                  icon: const Icon(Icons.home_outlined),
                  tooltip: l10n.tabHome,
                  onPressed: () => context.go('/home'),
                ),
        ),
        body: SafeArea(
          top: false,
          child: isPro
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified,
                          size: 64,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.paywallPurchased,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Icon(
                      Icons.workspace_premium_outlined,
                      size: 72,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.paywallTitle,
                      style: theme.textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.paywallBody,
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.paywallSlotsUsed(activeCount),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: _busy ? null : _purchase,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          _product == null
                              ? l10n.paywallBuy
                              : '${l10n.paywallBuy} · ${_product!.price}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _busy ? null : _restore,
                      child: Text(l10n.paywallRestore),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
