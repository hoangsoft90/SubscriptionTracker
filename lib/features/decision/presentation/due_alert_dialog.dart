import 'package:flutter/material.dart' hide DateUtils;
import 'package:go_router/go_router.dart';

import '../../../core/calendar/date_utils.dart';
import '../../../core/l10n/l10n.dart';
import '../review_queue.dart';

/// Once-per-day alert listing subscriptions that are due soon (renewal today /
/// tomorrow, or a trial ending within 3 days). Tapping an item opens the
/// subscription's detail page; "View all" jumps to Home where the full Review
/// Queue lives.
class DueAlertDialog extends StatelessWidget {
  const DueAlertDialog({super.key, required this.items});

  final List<ReviewQueueItem> items;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return AlertDialog(
      icon: Icon(
        Icons.warning_amber_rounded,
        color: theme.colorScheme.error,
      ),
      title: Text(l10n.dueAlertTitle),
      // AlertDialog measures content intrinsically — a shrink-wrap ListView
      // throws there, so items render in a plain scrollable column instead.
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.dueAlertBody),
            const SizedBox(height: 8),
            for (final item in items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor:
                      theme.colorScheme.error.withValues(alpha: 0.12),
                  child: Text(
                    item.subscription.iconEmoji ?? '📦',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
                title: Text(
                  item.subscription.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  _reasonLabel(context, item),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/subscriptions/${item.subscription.id}');
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.dueAlertDismiss),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            context.go('/home');
          },
          child: Text(l10n.dueAlertViewAll),
        ),
      ],
    );
  }

  String _reasonLabel(BuildContext context, ReviewQueueItem item) {
    final l10n = context.l10n;
    final sub = item.subscription;
    final today = DateUtils.localMidnight(DateTime.now());
    switch (item.reason) {
      case ReviewReason.trialEnding:
        final days = sub.trialEndDate == null
            ? 0
            : DateUtils.localMidnight(sub.trialEndDate!)
                .difference(today)
                .inDays;
        return l10n.dueAlertTrialEnding(sub.name, days);
      case ReviewReason.renewalDue:
        final days = DateUtils.localMidnight(sub.nextBillingDate)
            .difference(today)
            .inDays;
        return days <= 0
            ? l10n.dueAlertRenewalToday(sub.name)
            : l10n.dueAlertRenewalTomorrow(sub.name);
      // Medium-priority reasons never reach the dialog (DueAlertService
      // filters to high only) — keep the switch exhaustive.
      case ReviewReason.priceChanged:
      case ReviewReason.stale:
        return '';
    }
  }
}
