import 'dart:convert';

/// Versioned backup format (spec §2.6).
///
/// The backup `schemaVersion` is the *data-format* version and is completely
/// independent of the internal SQLite `PRAGMA user_version` migrations (M0).
abstract final class BackupFormat {
  static const formatMarker = 'subtrack_backup';
  static const currentSchemaVersion = 1;
}

/// Thrown when a file cannot be imported: not a SubTrack backup, or made by
/// a newer app version than this one supports.
class BackupValidationException implements Exception {
  const BackupValidationException(this.reason);

  /// 'invalid' → not a backup; 'future' → newer schemaVersion.
  final String reason;

  bool get isFutureVersion => reason == 'future';

  @override
  String toString() => 'BackupValidationException($reason)';
}

/// Parsed, validated backup contents.
class BackupFile {
  const BackupFile({
    required this.schemaVersion,
    required this.exportedAt,
    required this.appVersion,
    required this.settings,
    required this.categories,
    required this.subscriptions,
  });

  final int schemaVersion;
  final DateTime exportedAt;
  final String appVersion;

  /// Key/value app settings snapshot (e.g. primaryCurrency, language).
  final Map<String, String> settings;

  /// Category rows (raw maps — same shape as the SQLite rows).
  final List<Map<String, Object?>> categories;

  /// Subscription rows (raw maps — same shape as the SQLite rows).
  final List<Map<String, Object?>> subscriptions;

  int get subscriptionCount => subscriptions.length;
  int get categoryCount => categories.length;

  Map<String, Object?> toJson() => {
        'format': BackupFormat.formatMarker,
        'schemaVersion': schemaVersion,
        'exportedAt': exportedAt.toUtc().toIso8601String(),
        'appVersion': appVersion,
        'settings': settings,
        'categories': categories,
        'subscriptions': subscriptions,
      };

  /// Serializes to the portable JSON string.
  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());

  /// Parses and validates a backup string. Throws [BackupValidationException]
  /// for non-backup files and for newer schema versions (before any preview
  /// or mutation).
  factory BackupFile.decode(String raw) {
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const BackupValidationException('invalid');
    }
    if (decoded is! Map<String, Object?>) {
      throw const BackupValidationException('invalid');
    }
    if (decoded['format'] != BackupFormat.formatMarker) {
      throw const BackupValidationException('invalid');
    }
    final schemaVersion = decoded['schemaVersion'];
    if (schemaVersion is! int || schemaVersion < 1) {
      throw const BackupValidationException('invalid');
    }
    if (schemaVersion > BackupFormat.currentSchemaVersion) {
      throw const BackupValidationException('future');
    }
    return BackupFile(
      schemaVersion: schemaVersion,
      exportedAt: DateTime.tryParse(decoded['exportedAt'] as String? ?? '') ??
          DateTime.now(),
      appVersion: decoded['appVersion'] as String? ?? 'unknown',
      settings: {
        for (final e in (decoded['settings'] as Map? ?? {}).entries)
          e.key.toString(): e.value.toString(),
      },
      categories: _mapList(decoded['categories']),
      subscriptions: _mapList(decoded['subscriptions']),
    );
  }

  static List<Map<String, Object?>> _mapList(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map) {for (final e in item.entries) e.key.toString(): e.value},
    ];
  }
}
