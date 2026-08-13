/// Lifecycle status of a subscription (spec §3 — M2.5 adds the 4-state
/// lifecycle ACTIVE → PENDING_CANCELLATION → CANCELLED → ARCHIVED, plan2_final §5).
enum SubscriptionStatus {
  active('ACTIVE'),
  pendingCancellation('PENDING_CANCELLATION'),
  cancelled('CANCELLED'),
  archived('ARCHIVED');

  const SubscriptionStatus(this.dbValue);

  /// Value as stored in SQLite.
  final String dbValue;

  static SubscriptionStatus fromDb(String value) =>
      SubscriptionStatus.values.firstWhere((s) => s.dbValue == value);

  /// Statuses that consume a free-tier paywall slot. PENDING_CANCELLATION is
  /// still an active charge (plan2_final §5), so it counts — only
  /// CANCELLED/ARCHIVED free a slot.
  bool get countsTowardPaywall =>
      this == active || this == pendingCancellation;
}
