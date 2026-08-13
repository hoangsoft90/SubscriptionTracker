import 'dart:convert';

import '../../../core/calendar/date_utils.dart';
import 'billing_cycle.dart';
import 'subscription_status.dart';

/// Subscription aggregate (spec §6). Dates are local calendar dates stored as
/// `YYYY-MM-DD` strings; amounts are integer minor units.
class Subscription {
  const Subscription({
    required this.id,
    required this.name,
    required this.amountMinor,
    required this.currency,
    required this.billingCycle,
    this.customIntervalDays,
    required this.startDate,
    required this.nextBillingDate,
    required this.billingAnchorDay,
    required this.isTrial,
    this.trialEndDate,
    this.cancellationUrl,
    required this.status,
    this.categoryId,
    this.color,
    this.iconEmoji,
    this.reminderDaysBefore = const [],
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.lastReviewedAt,
    this.reviewIntervalDays = 90,
    this.cancelledAt,
    this.previousAmountMinor,
    this.supersededAt,
  });

  final String id; // uuid-v4
  final String name; // user data — never localized
  final int amountMinor;
  final String currency; // ISO 4217
  final BillingCycle billingCycle;
  final int? customIntervalDays; // only for CUSTOM
  final DateTime startDate; // local calendar date
  final DateTime nextBillingDate;
  final int billingAnchorDay; // monthly/quarterly/yearly only
  final bool isTrial;
  final DateTime? trialEndDate; // independent of nextBillingDate
  final String? cancellationUrl;
  final SubscriptionStatus status;
  final String? categoryId;
  final int? color;
  final String? iconEmoji; // generic emoji, never brand logo
  final List<int> reminderDaysBefore; // e.g. [1, 3]
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // --- M2.5 decision-engine fields (plan2_final §7) ---

  /// Last date the user reviewed this subscription (YYYY-MM-DD). Null until
  /// the first review; stale detection compares against [reviewIntervalDays].
  final DateTime? lastReviewedAt;

  /// How often (in days) the user wants to re-review; default 90.
  final int reviewIntervalDays;

  /// Date the subscription stopped billing (set when PENDING_CANCELLATION
  /// auto-transitions to CANCELLED — equals the nextBillingDate at cancel time).
  final DateTime? cancelledAt;

  /// Previous price (minor units) recorded when the amount changed — drives
  /// "price changed" detection until acknowledged (cleared on review).
  final int? previousAmountMinor;

  /// Set when a cancelled subscription is re-subscribed under the same name —
  /// stops its Realized Savings accumulation (plan2_final §4.2).
  final DateTime? supersededAt;

  Subscription copyWith({
    String? name,
    int? amountMinor,
    String? currency,
    BillingCycle? billingCycle,
    int? customIntervalDays,
    bool clearCustomInterval = false,
    DateTime? startDate,
    DateTime? nextBillingDate,
    int? billingAnchorDay,
    bool? isTrial,
    DateTime? trialEndDate,
    bool clearTrialEnd = false,
    String? cancellationUrl,
    bool clearCancellationUrl = false,
    SubscriptionStatus? status,
    String? categoryId,
    bool clearCategory = false,
    int? color,
    bool clearColor = false,
    String? iconEmoji,
    bool clearIconEmoji = false,
    List<int>? reminderDaysBefore,
    String? notes,
    bool clearNotes = false,
    DateTime? updatedAt,
    DateTime? lastReviewedAt,
    bool clearLastReviewedAt = false,
    int? reviewIntervalDays,
    DateTime? cancelledAt,
    bool clearCancelledAt = false,
    int? previousAmountMinor,
    bool clearPreviousAmountMinor = false,
    DateTime? supersededAt,
    bool clearSupersededAt = false,
  }) {
    return Subscription(
      id: id,
      name: name ?? this.name,
      amountMinor: amountMinor ?? this.amountMinor,
      currency: currency ?? this.currency,
      billingCycle: billingCycle ?? this.billingCycle,
      customIntervalDays:
          clearCustomInterval ? null : (customIntervalDays ?? this.customIntervalDays),
      startDate: startDate ?? this.startDate,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      billingAnchorDay: billingAnchorDay ?? this.billingAnchorDay,
      isTrial: isTrial ?? this.isTrial,
      trialEndDate: clearTrialEnd ? null : (trialEndDate ?? this.trialEndDate),
      cancellationUrl: clearCancellationUrl
          ? null
          : (cancellationUrl ?? this.cancellationUrl),
      status: status ?? this.status,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      color: clearColor ? null : (color ?? this.color),
      iconEmoji: clearIconEmoji ? null : (iconEmoji ?? this.iconEmoji),
      reminderDaysBefore:
          reminderDaysBefore ?? this.reminderDaysBefore,
      notes: clearNotes ? null : (notes ?? this.notes),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastReviewedAt:
          clearLastReviewedAt ? null : (lastReviewedAt ?? this.lastReviewedAt),
      reviewIntervalDays: reviewIntervalDays ?? this.reviewIntervalDays,
      cancelledAt:
          clearCancelledAt ? null : (cancelledAt ?? this.cancelledAt),
      previousAmountMinor: clearPreviousAmountMinor
          ? null
          : (previousAmountMinor ?? this.previousAmountMinor),
      supersededAt:
          clearSupersededAt ? null : (supersededAt ?? this.supersededAt),
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'amount_minor': amountMinor,
        'currency': currency,
        'billing_cycle': billingCycle.dbValue,
        'custom_interval_days': customIntervalDays,
        'start_date': DateUtils.format(startDate),
        'next_billing_date': DateUtils.format(nextBillingDate),
        'billing_anchor_day': billingAnchorDay,
        'is_trial': isTrial ? 1 : 0,
        'trial_end_date': trialEndDate == null ? null : DateUtils.format(trialEndDate!),
        'cancellation_url': cancellationUrl,
        'status': status.dbValue,
        'category_id': categoryId,
        'color': color,
        'icon_emoji': iconEmoji,
        'reminder_days_before': jsonEncode(reminderDaysBefore),
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'last_reviewed_at':
            lastReviewedAt == null ? null : DateUtils.format(lastReviewedAt!),
        'review_interval_days': reviewIntervalDays,
        // Derived from status — status is the single source of truth; the
        // column exists for schema compatibility (design D2).
        'pending_cancellation': status == SubscriptionStatus.pendingCancellation ? 1 : 0,
        'cancelled_at': cancelledAt == null ? null : DateUtils.format(cancelledAt!),
        'previous_amount_minor': previousAmountMinor,
        'superseded_at':
            supersededAt == null ? null : DateUtils.format(supersededAt!),
      };

  factory Subscription.fromMap(Map<String, Object?> map) {
    return Subscription(
      id: map['id']! as String,
      name: map['name']! as String,
      amountMinor: map['amount_minor']! as int,
      currency: map['currency']! as String,
      billingCycle: BillingCycle.fromDb(map['billing_cycle']! as String),
      customIntervalDays: map['custom_interval_days'] as int?,
      startDate: DateUtils.parse(map['start_date']! as String),
      nextBillingDate: DateUtils.parse(map['next_billing_date']! as String),
      billingAnchorDay: map['billing_anchor_day']! as int,
      isTrial: (map['is_trial'] as int) == 1,
      trialEndDate: map['trial_end_date'] == null
          ? null
          : DateUtils.parse(map['trial_end_date']! as String),
      cancellationUrl: map['cancellation_url'] as String?,
      status: SubscriptionStatus.fromDb(map['status']! as String),
      categoryId: map['category_id'] as String?,
      color: map['color'] as int?,
      iconEmoji: map['icon_emoji'] as String?,
      reminderDaysBefore: map['reminder_days_before'] == null
          ? const []
          : (jsonDecode(map['reminder_days_before']! as String) as List)
              .map((e) => e as int)
              .toList(),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at']! as String),
      updatedAt: DateTime.parse(map['updated_at']! as String),
      lastReviewedAt: map['last_reviewed_at'] == null
          ? null
          : DateUtils.parse(map['last_reviewed_at']! as String),
      reviewIntervalDays: (map['review_interval_days'] as int?) ?? 90,
      cancelledAt: map['cancelled_at'] == null
          ? null
          : DateUtils.parse(map['cancelled_at']! as String),
      previousAmountMinor: map['previous_amount_minor'] as int?,
      supersededAt: map['superseded_at'] == null
          ? null
          : DateUtils.parse(map['superseded_at']! as String),
    );
  }
}
