import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/money/money.dart';
import '../../../shared/widgets/money_text.dart';
import '../../subscriptions/application/subscription_list_controller.dart';
import '../../subscriptions/domain/subscription.dart';
import '../money_calendar.dart';

/// Dot-only money calendar (plan2_final §6): month grid, one dot per day with
/// charges, tap a day → that day's renewals + per-currency total. No heatmap.
class MoneyCalendarScreen extends ConsumerStatefulWidget {
  const MoneyCalendarScreen({super.key});

  @override
  ConsumerState<MoneyCalendarScreen> createState() =>
      _MoneyCalendarScreenState();
}

class _MoneyCalendarScreenState extends ConsumerState<MoneyCalendarScreen> {
  late DateTime _displayedMonth;

  static const _weekdayLabels = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month, 1);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + delta,
        1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final listState = ref.watch(subscriptionListControllerProvider);
    // Deep-link edge case: when /calendar is reached directly (web URL,
    // cold start) there is no back stack to pop — offer a way home instead
    // of leaving the user stranded. `maybeOf` keeps widget tests (which
    // render the screen without a router) working.
    final canPop = GoRouter.maybeOf(context)?.canPop() ?? false;

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        // Deep link with no back stack: system back goes home, not exit.
        if (!didPop) context.go('/home');
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.calendarTitle),
          automaticallyImplyLeading: canPop,
          leading: canPop
              ? null
              : IconButton(
                  icon: const Icon(Icons.home_outlined),
                  tooltip: l10n.tabHome,
                  onPressed: () => context.go('/home'),
                ),
          actions: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: l10n.calendarPrevMonth,
              onPressed: () => _shiftMonth(-1),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: l10n.calendarNextMonth,
              onPressed: () => _shiftMonth(1),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: listState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (state) {
              final service = const MoneyCalendarService();
              final data = service.compute(
                subscriptions: state.subscriptions,
                month: _displayedMonth,
              );
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    DateFormat('MMMM yyyy').format(_displayedMonth),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _MonthGrid(data: data),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.data});

  final CalendarMonthData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = data.month;
    final daysInMonth = DateTime(first.year, first.month + 1, 0).day;
    // DateTime.weekday: Mon=1 … Sun=7 → leading blanks before day 1.
    final leading = first.weekday - 1;

    return Column(
      children: [
        Row(
          children: [
            for (final label in _MoneyCalendarScreenState._weekdayLabels)
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var week = 0; week * 7 < leading + daysInMonth; week++)
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: _DayCell(
                    month: data.month,
                    day: _dayAt(week, i, leading, daysInMonth),
                    hasDot: data.dotDays.contains(
                      _dayAt(week, i, leading, daysInMonth),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  int? _dayAt(int week, int i, int leading, int daysInMonth) {
    final ordinal = week * 7 + i - leading + 1;
    if (ordinal < 1 || ordinal > daysInMonth) return null;
    return ordinal;
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.hasDot,
    required this.month,
  });

  final int? day;
  final bool hasDot;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: day == null
          ? null
          : () => showModalBottomSheet<void>(
              context: context,
              builder: (context) => _DayDetailSheet(month: month, day: day!),
            ),
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 52,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day?.toString() ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: day == null
                    ? Colors.transparent
                    : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasDot ? theme.colorScheme.primary : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayDetailSheet extends ConsumerWidget {
  const _DayDetailSheet({required this.month, required this.day});

  final DateTime month;
  final int day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final listState = ref.watch(subscriptionListControllerProvider);
    final state = listState.value;
    if (state == null) return const SizedBox.shrink();

    final data = const MoneyCalendarService().compute(
      subscriptions: state.subscriptions,
      month: month,
    );
    final charges = data.chargesForDay(day);
    final totals = data.totalsForDay(day);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${DateFormat('MMMM').format(month)} $day',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (charges.isEmpty)
              Text(
                l10n.calendarDayEmpty,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else ...[
              Text(
                charges.length == 1
                    ? l10n.calendarOneRenewal
                    : l10n.calendarRenewals(charges.length),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              for (final sub in charges) _ChargeRow(subscription: sub),
              const Divider(height: 24),
              for (final entry in totals.entries)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.calendarTotal),
                      MoneyText(
                        Money(entry.value, entry.key),
                        style: theme.textTheme.titleSmall,
                        currencyCode: true,
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChargeRow extends StatelessWidget {
  const _ChargeRow({required this.subscription});

  final Subscription subscription;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            child: Text(
              subscription.iconEmoji ?? '📦',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(subscription.name)),
          MoneyText(
            Money(subscription.amountMinor, subscription.currency),
            style: theme.textTheme.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
