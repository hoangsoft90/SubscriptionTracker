import '../../../core/calendar/date_utils.dart';
import '../subscriptions/domain/subscription.dart';
import '../subscriptions/domain/subscription_status.dart';

/// Priority of a Review Queue item (plan2_final §3.1).
enum ReviewPriority { high, medium }

/// Why a subscription landed in the queue (plan2_final §3.1).
enum ReviewReason {
  /// Free trial ends within 3 days (high).
  trialEnding,

  /// Billing date within 1 day (high).
  renewalDue,

  /// Price changed and not yet acknowledged (medium).
  priceChanged,

  /// Not reviewed for more than `reviewIntervalDays` (medium).
  stale,
}

/// One subscription needing attention.
class ReviewQueueItem {
  const ReviewQueueItem({
    required this.subscription,
    required this.priority,
    required this.reason,
    required this.sortDate,
  });

  final Subscription subscription;
  final ReviewPriority priority;
  final ReviewReason reason;

  /// Earliest date driving urgency (trial end / billing date / review due) —
  /// used for stable ordering within the same priority.
  final DateTime sortDate;
}

/// Pure scoring of which subscriptions need attention (plan2_final §3.1, §8).
///
/// Rules (one item per subscription — highest priority wins):
/// - `trialEndDate - today ≤ 3d` → high
/// - `nextBillingDate - today ≤ 1d` → high
/// - `previousAmountMinor != null` (price changed, unacknowledged) → medium
/// - `lastReviewedAt` older than `reviewIntervalDays` → medium (stale)
///
/// [hiddenIds] are session-scoped "Later" items that must not re-surface
/// (plan2_final §3.4). Items with a passed trial end or billing date are
/// skipped (the moment for acting on them has gone).
class ReviewQueueService {
  const ReviewQueueService();

  List<ReviewQueueItem> compute({
    required List<Subscription> subscriptions,
    required DateTime now,
    Set<String> hiddenIds = const {},
  }) {
    final today = DateUtils.localMidnight(now);
    final in3Days = today.add(const Duration(days: 3));
    final tomorrow = today.add(const Duration(days: 1));

    final items = <ReviewQueueItem>[];
    for (final sub in subscriptions) {
      if (sub.status != SubscriptionStatus.active) continue;
      if (hiddenIds.contains(sub.id)) continue;

      // High: trial ending within 3 days (only while the trial is live).
      if (sub.isTrial && sub.trialEndDate != null) {
        final trialEnd = DateUtils.localMidnight(sub.trialEndDate!);
        if (!trialEnd.isBefore(today) && !trialEnd.isAfter(in3Days)) {
          items.add(ReviewQueueItem(
            subscription: sub,
            priority: ReviewPriority.high,
            reason: ReviewReason.trialEnding,
            sortDate: trialEnd,
          ));
          continue;
        }
      }

      // High: billing within 1 day (today or tomorrow).
      final billing = DateUtils.localMidnight(sub.nextBillingDate);
      if (!billing.isBefore(today) && !billing.isAfter(tomorrow)) {
        items.add(ReviewQueueItem(
          subscription: sub,
          priority: ReviewPriority.high,
          reason: ReviewReason.renewalDue,
          sortDate: billing,
        ));
        continue;
      }

      // Medium: unacknowledged price change.
      if (sub.previousAmountMinor != null) {
        items.add(ReviewQueueItem(
          subscription: sub,
          priority: ReviewPriority.medium,
          reason: ReviewReason.priceChanged,
          sortDate: billing,
        ));
        continue;
      }

      // Medium: stale (never reviewed, or reviewed long ago).
      final reviewedAt = sub.lastReviewedAt ?? sub.createdAt;
      final dueDate =
          reviewedAt.add(Duration(days: sub.reviewIntervalDays));
      if (!dueDate.isAfter(today)) {
        items.add(ReviewQueueItem(
          subscription: sub,
          priority: ReviewPriority.medium,
          reason: ReviewReason.stale,
          sortDate: dueDate,
        ));
      }
    }

    // High first (enum order: high=0, medium=1), then by date, then by name.
    int priorityRank(ReviewPriority p) => p == ReviewPriority.high ? 0 : 1;
    items.sort((a, b) {
      final byPriority = priorityRank(a.priority).compareTo(priorityRank(b.priority));
      if (byPriority != 0) return byPriority;
      final byDate = a.sortDate.compareTo(b.sortDate);
      if (byDate != 0) return byDate;
      return a.subscription.name.compareTo(b.subscription.name);
    });
    return items;
  }
}
