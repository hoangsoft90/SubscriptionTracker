import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/money/money.dart';
import '../../../shared/widgets/money_text.dart';
import '../../categories/application/category_controller.dart';
import '../application/subscription_list_controller.dart';
import '../domain/billing_cycle.dart';
import '../domain/subscription.dart';
import '../domain/subscription_status.dart';
import 'subscription_list_screen.dart'
    show StatusChip, TrialBadge, formatDate, isTrialActive;

class SubscriptionDetailScreen extends ConsumerWidget {
  const SubscriptionDetailScreen({super.key, required this.subscriptionId});

  final String subscriptionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listState = ref.watch(subscriptionListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: context.l10n.tooltipEdit,
            onPressed: () =>
                context.push('/subscriptions/$subscriptionId/edit'),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: listState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (state) {
            final sub = state.subscriptions
                .where((s) => s.id == subscriptionId)
                .firstOrNull;
            if (sub == null) {
              return Center(child: Text(context.l10n.detailNotFound));
            }
            return _DetailBody(
              subscription: sub,
              onDelete: () => _confirmDelete(context, ref, sub),
              onStatus: (status) => ref
                  .read(subscriptionListControllerProvider.notifier)
                  .setStatus(sub.id, status),
              onCancel: () => _cancel(context, ref, sub),
            );
          },
        ),
      ),
    );
  }

  /// Cancel flow (plan2_final §5): opens the cancellation URL when present,
  /// then moves the subscription to PENDING_CANCELLATION (still an active
  /// charge; it auto-transitions to CANCELLED at the next billing date via
  /// `NotificationScheduler.reconcile()`).
  Future<void> _cancel(
    BuildContext context,
    WidgetRef ref,
    Subscription sub,
  ) async {
    final url = sub.cancellationUrl;
    if (url != null && url.isNotEmpty) {
      final uri = Uri.tryParse(url);
      if (uri != null &&
          await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        // Browser opened; still mark pending-cancellation below.
      }
    }
    await ref
        .read(subscriptionListControllerProvider.notifier)
        .setStatus(sub.id, SubscriptionStatus.pendingCancellation);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Subscription sub,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteConfirmTitle),
        content: Text(context.l10n.deleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(subscriptionListControllerProvider.notifier)
          .delete(sub.id);
      if (context.mounted) context.pop();
    }
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({
    required this.subscription,
    required this.onDelete,
    required this.onStatus,
    required this.onCancel,
  });

  final Subscription subscription;
  final VoidCallback onDelete;
  final ValueChanged<SubscriptionStatus> onStatus;

  /// Cancel flow: opens URL + sets PENDING_CANCELLATION (plan2_final §5).
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final sub = subscription;
    final isActive = sub.status == SubscriptionStatus.active;
    // Display the category *name*, not the raw id/slug/UUID (fix: previously
    // showed the raw id, e.g. a UUID for custom categories).
    final categoryName = sub.categoryId == null
        ? null
        : (ref.watch(categoryControllerProvider).value ?? const [])
            .where((c) => c.id == sub.categoryId)
            .firstOrNull
            ?.name;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              child: Text(
                sub.iconEmoji ?? '📦',
                style: const TextStyle(fontSize: 28),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          sub.name,
                          style: theme.textTheme.headlineSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isTrialActive(sub)) const TrialBadge(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  StatusChip(status: sub.status),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _DetailRow(
                  label: l10n.fieldAmount,
                  child: MoneyText(
                    Money(sub.amountMinor, sub.currency),
                    style: theme.textTheme.titleMedium,
                    currencyCode: true,
                  ),
                ),
                const Divider(height: 24),
                _DetailRow(
                  label: l10n.detailNextBilling,
                  child: Text(formatDate(context, sub.nextBillingDate)),
                ),
                if (sub.isTrial && sub.trialEndDate != null) ...[
                  const Divider(height: 24),
                  _DetailRow(
                    label: l10n.detailTrialEnd,
                    child: Text(formatDate(context, sub.trialEndDate!)),
                  ),
                ],
                const Divider(height: 24),
                _DetailRow(
                  label: l10n.fieldCycle,
                  child: Text(_cycleLabel(context, sub.billingCycle)),
                ),
                if (sub.billingCycle == BillingCycle.custom &&
                    sub.customIntervalDays != null) ...[
                  const Divider(height: 24),
                  _DetailRow(
                    label: l10n.customIntervalDays,
                    child: Text('${sub.customIntervalDays}'),
                  ),
                ],
                if (sub.categoryId != null) ...[
                  const Divider(height: 24),
                  _DetailRow(
                    label: l10n.fieldCategory,
                    child: Text(categoryName ?? l10n.uncategorized),
                  ),
                ],
                if (sub.notes != null && sub.notes!.isNotEmpty) ...[
                  const Divider(height: 24),
                  _DetailRow(label: l10n.fieldNotes, child: Text(sub.notes!)),
                ],
                if (sub.cancellationUrl != null) ...[
                  const Divider(height: 24),
                  _DetailRow(
                    label: l10n.detailCancellationUrl,
                    child: Text(
                      sub.cancellationUrl!,
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Lifecycle (plan2_final §5): ACTIVE → Cancel (opens URL, becomes
        // PENDING_CANCELLATION) · PENDING_CANCELLATION/CANCELLED → Activate.
        FilledButton.tonalIcon(
          onPressed: isActive
              ? onCancel
              : () => onStatus(SubscriptionStatus.active),
          icon: Icon(
            isActive ? Icons.stop_circle_outlined : Icons.play_circle_outline,
          ),
          label: Text(isActive ? l10n.actionCancel : l10n.actionActivate),
        ),
        if (!isActive)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: FilledButton.tonalIcon(
              onPressed: () => onStatus(
                sub.status == SubscriptionStatus.archived
                    ? SubscriptionStatus.active
                    : SubscriptionStatus.archived,
              ),
              icon: const Icon(Icons.archive_outlined),
              label: Text(
                sub.status == SubscriptionStatus.archived
                    ? l10n.actionUnarchive
                    : l10n.actionArchive,
              ),
            ),
          ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onDelete,
          icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
          label: Text(
            l10n.delete,
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
      ],
    );
  }

  static String _cycleLabel(BuildContext context, BillingCycle cycle) {
    final l10n = context.l10n;
    return switch (cycle) {
      BillingCycle.weekly => l10n.cycleWeekly,
      BillingCycle.monthly => l10n.cycleMonthly,
      BillingCycle.quarterly => l10n.cycleQuarterly,
      BillingCycle.yearly => l10n.cycleYearly,
      BillingCycle.custom => l10n.cycleCustom,
    };
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(child: child),
      ],
    );
  }
}
