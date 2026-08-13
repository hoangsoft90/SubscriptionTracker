/// Recurrence pattern of a subscription (spec §6).
enum BillingCycle {
  weekly('WEEKLY'),
  monthly('MONTHLY'),
  quarterly('QUARTERLY'),
  yearly('YEARLY'),
  custom('CUSTOM');

  const BillingCycle(this.dbValue);

  /// Value as stored in SQLite.
  final String dbValue;

  static BillingCycle fromDb(String value) =>
      BillingCycle.values.firstWhere((c) => c.dbValue == value);
}
