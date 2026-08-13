/// Deterministic notification identity (spec §2.4).
library;

import 'dart:convert';

/// What kind of event a reminder belongs to.
enum ReminderType {
  /// A billing date reminder.
  billing,

  /// Trial Shield: two days before `trialEndDate`.
  trialTwoDaysBefore,

  /// Trial Shield: on `trialEndDate` itself.
  trialEndDay,
}

/// A single scheduled reminder event for one subscription.
class ReminderEvent {
  const ReminderEvent({
    required this.subscriptionId,
    required this.triggerAt,
    required this.type,
    required this.title,
    required this.body,
  });

  final String subscriptionId;
  final DateTime triggerAt;
  final ReminderType type;
  final String title;
  final String body;

  /// Deterministic ID (spec §2.4): FNV-1a 32-bit hash of
  /// `subscriptionId + trigger ISO 8601 + reminder type`, mod 2^31−1, so
  /// re-scheduling the same event always yields the same ID and cancel-by-ID
  /// is exact. FNV-1a is used instead of `String.hashCode` because Dart does
  /// not guarantee hashCode stability across VM versions/platforms.
  int get id => notificationIdFor(
        subscriptionId: subscriptionId,
        date: triggerAt,
        type: type,
      );
}

/// Computes the deterministic notification ID for [date]/[type] per spec §2.4.
int notificationIdFor({
  required String subscriptionId,
  required DateTime date,
  required ReminderType type,
}) {
  final input = utf8.encode(
    '$subscriptionId|${date.toIso8601String()}|${type.name}',
  );
  const offset = 0x811c9dc5; // FNV-1a 32-bit offset basis
  const prime = 0x01000193; // FNV-1a 32-bit prime
  var hash = offset;
  for (final byte in input) {
    hash ^= byte;
    hash = (hash * prime) & 0xFFFFFFFF; // keep 32-bit unsigned
  }
  return hash % 2147483647; // ≤ Android int32 max (2^31−1)
}
