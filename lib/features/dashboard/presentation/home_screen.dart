import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/money/money.dart';
import '../../../core/providers.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/money_text.dart';
import '../../decision/review_queue.dart';
import '../../decision/today_brief.dart';
import '../../guidance/application/guidance_controller.dart';
import '../../guidance/domain/guidance_step.dart';
import '../../guidance/presentation/feature_badge.dart';
import '../../guidance/presentation/guidance_host.dart';
import '../../settings/application/settings_controller.dart';
import '../../subscriptions/application/subscription_list_controller.dart';
import '../../subscriptions/domain/subscription.dart';
import '../application/dashboard_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// Targets for the first-run spotlight tour (cost card + calendar card).
  final _costKey = GlobalKey();
  final _calendarKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dashboard = ref.watch(dashboardControllerProvider);
    final primary =
        ref.watch(settingsControllerProvider).value?.primaryCurrency ?? 'USD';
    final exchangeRates = ref.watch(exchangeRatesProvider).value;
    final calendarSeen =
        ref.watch(guidanceControllerProvider).value?.completedStepIds
                .contains('home.calendar') ??
            false;

    return GuidanceHost(
      tourId: 'firstRunHome',
      steps: [
        GuidanceStep(
          id: 'home.cost',
          targetKey: 'homeCostCard',
          title: l10n.guidanceHomeCostTitle,
          body: l10n.guidanceHomeCostBody,
        ),
        GuidanceStep(
          id: 'home.calendar',
          targetKey: 'homeCalendarCard',
          title: l10n.guidanceHomeCalendarTitle,
          body: l10n.guidanceHomeCalendarBody,
        ),
      ],
      targetKeys: {'homeCostCard': _costKey, 'homeCalendarCard': _calendarKey},
      l10n: GuidanceLabels(
        skip: l10n.guidanceSkip,
        next: l10n.guidanceNext,
        done: l10n.guidanceDone,
        stepCounter: l10n.guidanceStepCounter,
      ),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.appName)),
        body: Column(
          children: [
            Expanded(
              child: dashboard.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (state) {
                  if (state.active.isEmpty) {
                    return EmptyState(
                      icon: Icons.home_outlined,
                      title: l10n.dashboardEmptyTitle,
                      body: l10n.dashboardEmptyBody,
                      ctaLabel: l10n.dashboardEmptyCta,
                      onCta: () => context.push('/subscriptions/add'),
                    );
                  }

                  final controller =
                      ref.read(dashboardControllerProvider.notifier);
                  // Multi-currency report (user-approved 2026-08-15): when
                  // exchange rates are available, the headline converts every
                  // currency to the primary one and a per-currency breakdown
                  // is shown below. Without rates (offline + no manual
                  // rates) it falls back to the primary-only total.
                  final rates = exchangeRates?.rates;
                  // Converted headline is only trustworthy when EVERY active
                  // subscription can be converted — if any currency lacks a
                  // rate, fall back to the primary-only total rather than
                  // silently truncating the headline (the per-currency
                  // breakdown below still shows every currency exactly).
                  final convertibleRates = (rates != null &&
                          controller.allActiveConvertible(primary, rates))
                      ? rates
                      : null;
                  final monthly = convertibleRates != null
                      ? controller.monthlyTotalConverted(primary, convertibleRates)
                      : controller.monthlyTotal(primary);
                  final yearly = convertibleRates != null
                      ? controller.yearlyTotalConverted(primary, convertibleRates)
                      : controller.yearlyTotal(primary);
                  final monthTotal = controller.monthTotal(primary);
                  final byCurrency = controller.monthlyByCurrency();
                  final projectedSavings = convertibleRates != null
                      ? controller.savingsConverted(
                          state.savings.projectedMonthly,
                          primary,
                          convertibleRates,
                        )
                      : (state.savings.projectedMonthly[primary] ?? 0);
                  final realizedSavings = convertibleRates != null
                      ? controller.savingsConverted(
                          state.savings.realized, primary, convertibleRates,
                        )
                      : (state.savings.realized[primary] ?? 0);

                  return RefreshIndicator(
                    onRefresh: () async =>
                        ref.refresh(dashboardControllerProvider.future),
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Spotlight target #1 — monthly cost card.
                        KeyedSubtree(
                          key: _costKey,
                          child: _CostCard(
                            monthly: Money(monthly, primary),
                            yearly: Money(yearly, primary),
                            projectedSavings:
                                Money(projectedSavings, primary),
                            realizedSavings: Money(realizedSavings, primary),
                            // Per-currency monthly breakdown shown only when
                            // more than one currency is active.
                            breakdownByCurrency: byCurrency.length > 1
                                ? byCurrency
                                : null,
                            // "≈ converted" note when the headline used
                            // exchange rates (live or manual).
                            converted: convertibleRates != null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _TodayCard(brief: state.brief, primary: primary),
                        const SizedBox(height: 16),
                        _QueueCard(queue: state.queue),
                        const SizedBox(height: 16),
                        // Spotlight target #2 — calendar card + "New" badge.
                        KeyedSubtree(
                          key: _calendarKey,
                          child: FeatureBadge(
                            visible: !calendarSeen,
                            label: l10n.featureNew,
                            child: _MonthCard(
                              monthTotal: Money(monthTotal, primary),
                              month: DateTime.now(),
                              onViewCalendar: () =>
                                  context.push('/calendar'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card 1 — Monthly Cost (with projected + realized savings delta).
class _CostCard extends StatelessWidget {
  const _CostCard({
    required this.monthly,
    required this.yearly,
    required this.projectedSavings,
    required this.realizedSavings,
    this.breakdownByCurrency,
    this.converted = false,
  });

  final Money monthly;
  final Money yearly;
  final Money projectedSavings;
  final Money realizedSavings;

  /// Per-currency monthly equivalents (multi-currency report) — rendered as
  /// a compact breakdown line under the headline when more than one currency
  /// is active. Null when everything is already in the primary currency.
  final Map<String, int>? breakdownByCurrency;

  /// True when the headline was produced by converting other currencies to
  /// the primary one (live or manual rates) — shows the "≈" estimated note.
  final bool converted;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final hasSavings = projectedSavings.amountMinor > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.dashboardMonthly,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: MoneyText(
                    monthly,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasSavings) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '↓ ${MoneyText.renderMoney(
                          projectedSavings,
                          locale: Localizations.localeOf(context).toString(),
                        )}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.tertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.dashboardYearly,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: MoneyText(
                    yearly,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            // Multi-currency breakdown: one line per currency, each showing
            // its own monthly equivalent with its ISO code — the headline
            // converts to primary, this line keeps every currency visible.
            if (breakdownByCurrency != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final entry in breakdownByCurrency!.entries)
                    MoneyText(
                      Money(entry.value, entry.key),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      currencyCode: true,
                      maxLines: 1,
                    ),
                ],
              ),
            ],
            if (converted) ...[
              const SizedBox(height: 4),
              Text(
                l10n.dashboardConvertedNote,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (hasSavings) ...[
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      l10n.savingsProjectedLabel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: MoneyText(
                      projectedSavings,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      l10n.savingsRealizedLabel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: MoneyText(
                      realizedSavings,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                l10n.savingsEstimatedNote,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Card 2 — Today Money Brief (replaces the old Upcoming card).
class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.brief, required this.primary});

  final TodayBrief brief;
  final String primary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.dashboardToday,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            if (brief.clear)
              Text(
                l10n.todayClear,
                style: theme.textTheme.bodyMedium,
              )
            else ...[
              if (brief.trialEnding != null)
                _TrialWarning(
                  subscription: brief.trialEnding!,
                  days: brief.trialEndingInDays ?? 0,
                )
              else if (!brief.hasEventToday)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(l10n.todayNothingDue),
                    ],
                  ),
                ),
              // Renewals charging TODAY (device-test 2026-08-15: these must
              // surface here — previously only the Review Queue/dialog saw
              // them and the card wrongly said "You're clear").
              for (final sub in brief.dueToday)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _NextRenewalRow(
                    subscription: sub,
                    days: 0,
                    primary: primary,
                  ),
                ),
              if (brief.nextRenewal != null)
                _NextRenewalRow(
                  subscription: brief.nextRenewal!,
                  days: brief.nextRenewalInDays ?? 0,
                  primary: primary,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrialWarning extends StatelessWidget {
  const _TrialWarning({required this.subscription, required this.days});

  final Subscription subscription;
  final int days;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 18, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  days == 0
                      ? l10n.trialEndingToday(subscription.name)
                      : l10n.trialEndingIn(subscription.name, days),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.trialAfterPrice(
                    subscription.name,
                    _pricePerMonth(context, subscription),
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _pricePerMonth(BuildContext context, Subscription sub) {
    final money = Money(sub.amountMinor, sub.currency);
    final locale = Localizations.localeOf(context).toString();
    return '${MoneyText.renderMoney(money, locale: locale)}/'
        '${sub.billingCycle.dbValue.toLowerCase()}';
  }
}

class _NextRenewalRow extends StatelessWidget {
  const _NextRenewalRow({
    required this.subscription,
    required this.days,
    required this.primary,
  });

  final Subscription subscription;
  final int days;
  final String primary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final date = DateFormat('EEE, MMM d').format(subscription.nextBillingDate);
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          child: Text(subscription.iconEmoji ?? '📦', style: const TextStyle(fontSize: 14)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            l10n.todayNext(
              subscription.name,
              days == 0 ? l10n.todayToday : '$days',
              date,
            ),
            style: theme.textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        MoneyText(
          Money(subscription.amountMinor, subscription.currency),
          style: theme.textTheme.titleSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Card 3 — Needs Attention (Review Queue), capped at 3 with "Review all".
class _QueueCard extends ConsumerWidget {
  const _QueueCard({required this.queue});

  final List<ReviewQueueItem> queue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final visible = queue.take(3).toList();
    final hiddenCount = queue.length - visible.length;

    if (queue.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.needsAttention(queue.length),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final item in visible)
              _QueueTile(item: item),
            if (hiddenCount > 0)
              TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  builder: (context) => _ReviewAllSheet(queue: queue),
                ),
                child: Text(l10n.reviewAll(hiddenCount + visible.length)),
              ),
          ],
        ),
      ),
    );
  }
}

class _QueueTile extends ConsumerWidget {
  const _QueueTile({required this.item});

  final ReviewQueueItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sub = item.subscription;
    final color = item.priority == ReviewPriority.high
        ? theme.colorScheme.error
        : theme.colorScheme.tertiary;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: color.withValues(alpha: 0.12),
        child: Text(sub.iconEmoji ?? '📦', style: const TextStyle(fontSize: 15)),
      ),
      title: Text(sub.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        _reasonLabel(context, item),
        style: theme.textTheme.bodySmall?.copyWith(color: color),
      ),
      trailing: Icon(
        item.priority == ReviewPriority.high
            ? Icons.error_outline
            : Icons.info_outline,
        size: 18,
        color: color,
      ),
      onTap: () => _showReviewDialog(context, ref, item),
    );
  }

  String _reasonLabel(BuildContext context, ReviewQueueItem item) {
    final l10n = context.l10n;
    final sub = item.subscription;
    return switch (item.reason) {
      ReviewReason.trialEnding =>
        l10n.queueTrialEnding(sub.trialEndDate == null
            ? 0
            : sub.trialEndDate!.difference(DateTime.now()).inDays),
      ReviewReason.renewalDue =>
        l10n.queueRenewalDue(sub.nextBillingDate.day),
      ReviewReason.priceChanged => l10n.queuePriceChanged,
      ReviewReason.stale => l10n.queueStale(sub.name),
    };
  }
}

Future<void> _showReviewDialog(
  BuildContext context,
  WidgetRef ref,
  ReviewQueueItem item,
) async {
  final l10n = context.l10n;
  final sub = item.subscription;
  final choice = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.reviewTitle(sub.name)),
      content: Text(l10n.reviewQuestion),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, 'later'),
          child: Text(l10n.reviewLater),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, 'cancel'),
          child: Text(l10n.reviewCancelAction),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, 'keep'),
          child: Text(l10n.reviewKeep),
        ),
      ],
    ),
  );
  if (choice == null || !context.mounted) return;

  final listNotifier =
      ref.read(subscriptionListControllerProvider.notifier);
  switch (choice) {
    case 'keep':
      await listNotifier.markReviewed(sub.id);
    case 'cancel':
      final url = sub.cancellationUrl;
      if (url != null && url.isNotEmpty) {
        final uri = Uri.tryParse(url);
        if (uri != null) {
          await _launchUrl(uri);
        }
      }
      await listNotifier.cancelSubscription(sub.id);
    case 'later':
      ref.read(reviewQueueHiddenIdsProvider.notifier).hideLater(sub.id);
  }
  ref.invalidate(dashboardControllerProvider);
}

Future<void> _launchUrl(Uri uri) async {
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    // Offline or no browser — never block the review flow.
  }
}

class _ReviewAllSheet extends ConsumerWidget {
  const _ReviewAllSheet({required this.queue});

  final List<ReviewQueueItem> queue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        children: [
          for (final item in queue) _QueueTile(item: item),
        ],
      ),
    );
  }
}

/// Card 4 — current month recurring charges + calendar entry point.
class _MonthCard extends StatelessWidget {
  const _MonthCard({
    required this.monthTotal,
    required this.month,
    required this.onViewCalendar,
  });

  final Money monthTotal;
  final DateTime month;
  final VoidCallback onViewCalendar;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onViewCalendar,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.calendar_month,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('MMMM').format(month).toUpperCase(),
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      l10n.calendarMonthCharges,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    MoneyText(
                      monthTotal,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    TextButton(
                      onPressed: onViewCalendar,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(l10n.calendarView),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
