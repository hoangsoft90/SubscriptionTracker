import '../subscriptions/domain/subscription.dart';
import 'review_queue.dart';

/// Selects the subscriptions the once-per-day due-alert dialog should surface.
///
/// Only time-sensitive items qualify — renewals due today or tomorrow and
/// trials ending within 3 days — i.e. the HIGH-priority slice of the Review
/// Queue. Medium items (price changed / stale) stay on the Home Review Queue
/// card; a daily popup must never nag about those.
class DueAlertService {
  const DueAlertService();

  /// Settings key persisting the last day (YYYY-MM-DD, local) the dialog was
  /// shown — the once-per-day gate. Null / another day → dialog may show.
  static const String lastShownKey = 'dueAlertLastShown';

  List<ReviewQueueItem> compute({
    required List<Subscription> subscriptions,
    required DateTime now,
  }) {
    final queue = const ReviewQueueService().compute(
      subscriptions: subscriptions,
      now: now,
    );
    return queue
        .where((item) => item.priority == ReviewPriority.high)
        .toList();
  }
}
