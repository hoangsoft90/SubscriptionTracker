import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/money/money.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/money_text.dart';
import '../../ads/ads_controller.dart';
import '../../ads/presentation/banner_ad_view.dart';
import '../../guidance/presentation/disabled_state_helper.dart';
import '../../paywall/entitlement_controller.dart';
import '../../paywall/free_tier.dart';
import '../application/subscription_list_controller.dart';
import '../domain/subscription.dart';
import '../domain/subscription_status.dart';

class SubscriptionListScreen extends ConsumerStatefulWidget {
  const SubscriptionListScreen({super.key});

  @override
  ConsumerState<SubscriptionListScreen> createState() =>
      _SubscriptionListScreenState();
}

class _SubscriptionListScreenState extends ConsumerState<SubscriptionListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final listState = ref.watch(subscriptionListControllerProvider);
    final showAds = ref.watch(showAdsProvider);
    final isPro = ref.watch(proEntitlementControllerProvider).value ?? false;
    final slotCount = listState.value == null
        ? 0
        : paywallSlotCount(listState.value!.subscriptions);
    final tier = freeTierState(activeCount: slotCount, isPro: isPro);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.subscriptionsTitle)),
      floatingActionButton: DisabledStateHelper(
        // At the hard limit, adding is blocked. The helper keeps the FAB
        // visibly disabled but explains why + how to unlock when tapped.
        enabled: tier != FreeTierState.hardBlock,
        title: context.l10n.disabledFreeLimitTitle,
        message: context.l10n.disabledFreeLimitBody,
        unlockLabel: context.l10n.disabledFreeLimitUnlock,
        onUnlock: () => context.push('/paywall'),
        child: FloatingActionButton(
          onPressed: tier == FreeTierState.hardBlock
              ? null
              : () => context.push('/subscriptions/add'),
          tooltip: l10n.subscriptionsAdd,
          child: const Icon(Icons.add),
        ),
      ),
      body: listState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (state) {
          final visible = state.visible;
          return Column(
            children: [
              if (tier == FreeTierState.slotsLeft)
                _FreeSlotsBanner(count: freeSlotsLeft(slotCount)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.subscriptionsSearchHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(subscriptionListControllerProvider.notifier)
                                  .setQuery('');
                            },
                          ),
                  ),
                  onChanged: (value) => ref
                      .read(subscriptionListControllerProvider.notifier)
                      .setQuery(value),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    // Expanded lets the chip row scroll instead of pushing
                    // the sort menu off-screen (right-overflow on narrow
                    // devices when all status chips are visible).
                    Expanded(
                      child: _StatusFilterChips(
                        current: state.filter.status,
                        onChanged: (status) => ref
                            .read(subscriptionListControllerProvider.notifier)
                            .setStatusFilter(status),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SortMenu(
                      current: state.sort,
                      onChanged: (sort) => ref
                          .read(subscriptionListControllerProvider.notifier)
                          .setSort(sort),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: visible.isEmpty
                    ? EmptyState(
                        icon: Icons.list_alt_outlined,
                        title: state.query.isNotEmpty
                            ? l10n.subscriptionsNoResults
                            : l10n.subscriptionsEmptyTitle,
                        body: state.query.isNotEmpty
                            ? ''
                            : l10n.subscriptionsEmptyBody,
                        ctaLabel: state.query.isEmpty
                            ? l10n.subscriptionsAdd
                            : null,
                        onCta: state.query.isEmpty
                            ? () => context.push('/subscriptions/add')
                            : null,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: visible.length,
                        itemBuilder: (context, index) {
                          final sub = visible[index];
                          return _SubscriptionTile(subscription: sub);
                        },
                      ),
              ),
              // Free tier only: adaptive banner above the bottom nav (Pro: none).
              if (showAds) const BannerAdView(),
            ],
          );
        },
      ),
    );
  }
}

class _SubscriptionTile extends StatelessWidget {
  const _SubscriptionTile({required this.subscription});

  final Subscription subscription;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sub = subscription;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        child: Text(sub.iconEmoji ?? '📦'),
      ),
      title: Row(
        children: [
          Flexible(child: Text(sub.name, overflow: TextOverflow.ellipsis)),
          if (isTrialActive(sub))
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: TrialBadge(),
            ),
        ],
      ),
      subtitle: Text(
        context.l10n.nextBillingLabel(formatDate(context, sub.nextBillingDate)),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Long amounts (e.g. VND) must ellipsize inside the ListTile
          // trailing — otherwise the tile overflows to the right.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: MoneyText(
              Money(sub.amountMinor, sub.currency),
              style: theme.textTheme.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          // Long labels (e.g. "Pending cancellation") must ellipsize inside
          // the constrained trailing — otherwise the tile overflows right.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: StatusChip(status: sub.status),
          ),
        ],
      ),
      onTap: () => context.push('/subscriptions/${sub.id}'),
    );
  }
}

/// True while a subscription is an active trial (trial end in the future).
bool isTrialActive(Subscription sub) {
  final trialEnd = sub.trialEndDate;
  if (!sub.isTrial || trialEnd == null) return false;
  return trialEnd.isAfter(DateTime.now());
}

/// Locale-aware short date (no year): MM/DD for English, DD/MM for
/// Vietnamese — previously hard-coded MM/DD for every locale, which reads
/// day/month backwards for VN users (fix: month/day misreading).
String formatDate(BuildContext context, DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  final mm = two(d.month);
  final dd = two(d.day);
  final isVietnamese = Localizations.localeOf(context).languageCode == 'vi';
  return isVietnamese ? '$dd/$mm' : '$mm/$dd';
}

/// Red trial badge (spec M1 dashboard + list/detail).
class TrialBadge extends StatelessWidget {
  const TrialBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        context.l10n.trialBadge,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onError,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final SubscriptionStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final (label, color) = switch (status) {
      SubscriptionStatus.active => (l10n.filterActive, null),
      SubscriptionStatus.pendingCancellation => (
          l10n.filterPendingCancellation,
          theme.colorScheme.tertiaryContainer,
        ),
      SubscriptionStatus.cancelled => (
          l10n.filterCancelled,
          theme.colorScheme.errorContainer,
        ),
      SubscriptionStatus.archived => (
          l10n.filterArchived,
          theme.colorScheme.surfaceContainerHighest,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color == null
              ? theme.colorScheme.primary
              : theme.colorScheme.onErrorContainer,
        ),
      ),
    );
  }
}

/// Light "N free slots left" banner shown at 9–10 active subscriptions
/// (spec §2.8 staged messaging).
class _FreeSlotsBanner extends StatelessWidget {
  const _FreeSlotsBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: theme.colorScheme.onSecondaryContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.l10n.freeSlotsBanner(count),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusFilterChips extends StatelessWidget {
  const _StatusFilterChips({required this.current, required this.onChanged});

  final SubscriptionStatus? current;
  final ValueChanged<SubscriptionStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: Text(l10n.filterAll),
            selected: current == null,
            onSelected: (_) => onChanged(null),
          ),
          const SizedBox(width: 4),
          for (final status in SubscriptionStatus.values)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: ChoiceChip(
                label: Text(_statusLabel(context, status)),
                selected: current == status,
                onSelected: (_) => onChanged(status),
              ),
            ),
        ],
      ),
    );
  }

  static String _statusLabel(BuildContext context, SubscriptionStatus status) {
    final l10n = context.l10n;
    return switch (status) {
      SubscriptionStatus.active => l10n.filterActive,
      SubscriptionStatus.pendingCancellation => l10n.filterPendingCancellation,
      SubscriptionStatus.cancelled => l10n.filterCancelled,
      SubscriptionStatus.archived => l10n.filterArchived,
    };
  }
}

class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.current, required this.onChanged});

  final SubscriptionSort current;
  final ValueChanged<SubscriptionSort> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopupMenuButton<SubscriptionSort>(
      icon: const Icon(Icons.sort),
      tooltip: l10n.tooltipSort,
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final sort in SubscriptionSort.values)
          PopupMenuItem(
            value: sort,
            child: Row(
              children: [
                if (current == sort) const Icon(Icons.check, size: 18),
                const SizedBox(width: 8),
                Text(_sortLabel(context, sort)),
              ],
            ),
          ),
      ],
    );
  }

  static String _sortLabel(BuildContext context, SubscriptionSort sort) {
    final l10n = context.l10n;
    return switch (sort) {
      SubscriptionSort.name => l10n.sortName,
      SubscriptionSort.amount => l10n.sortAmount,
      SubscriptionSort.nextBilling => l10n.sortNextBilling,
    };
  }
}
