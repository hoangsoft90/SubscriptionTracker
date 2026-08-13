import '../../../core/calendar/date_utils.dart';

/// One recorded price state of a subscription (plan2_final §7). Written on
/// every amount change; deleted with the subscription (FK cascade).
class PriceHistoryEntry {
  const PriceHistoryEntry({
    required this.id,
    required this.subscriptionId,
    required this.amountMinor,
    required this.currency,
    required this.effectiveFrom,
    required this.createdAt,
  });

  final String id; // uuid-v4
  final String subscriptionId;
  final int amountMinor;
  final String currency; // ISO 4217
  final DateTime effectiveFrom; // YYYY-MM-DD (local calendar date)
  final DateTime createdAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'subscription_id': subscriptionId,
        'amount_minor': amountMinor,
        'currency': currency,
        'effective_from': DateUtils.format(effectiveFrom),
        'created_at': createdAt.toIso8601String(),
      };

  factory PriceHistoryEntry.fromMap(Map<String, Object?> map) {
    return PriceHistoryEntry(
      id: map['id']! as String,
      subscriptionId: map['subscription_id']! as String,
      amountMinor: map['amount_minor']! as int,
      currency: map['currency']! as String,
      effectiveFrom: DateUtils.parse(map['effective_from']! as String),
      createdAt: DateTime.parse(map['created_at']! as String),
    );
  }
}
