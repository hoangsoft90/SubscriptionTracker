/// Calendar-date helpers operating on local-midnight [DateTime] values.
///
/// All billing dates are calendar dates (`YYYY-MM-DD`), never UTC instants
/// (spec §2.3). Normalization to local midnight guarantees day-level
/// comparisons are timezone-independent within a device.
class DateUtils {
  DateUtils._();

  /// Normalizes [date] to local midnight of its calendar day.
  static DateTime localMidnight(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Parses a `YYYY-MM-DD` string into a local-midnight [DateTime].
  ///
  /// Rejects structurally invalid values (wrong parts, non-numeric, month
  /// outside 1–12, day outside the month's valid range) instead of silently
  /// normalizing them, so bad dates from e.g. a future backup import fail
  /// loudly rather than corrupting billing.
  static DateTime parse(String value) {
    final parts = value.split('-');
    if (parts.length != 3) {
      throw FormatException('Invalid date "$value" — expected YYYY-MM-DD');
    }
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      throw FormatException('Invalid date "$value" — non-numeric component');
    }
    if (month < 1 || month > 12) {
      throw FormatException('Invalid date "$value" — month out of range');
    }
    if (day < 1 || day > DateTime(year, month + 1, 0).day) {
      throw FormatException('Invalid date "$value" — day out of range');
    }
    return DateTime(year, month, day);
  }

  /// Formats a local-midnight [DateTime] as `YYYY-MM-DD` (zero-padded).
  static String format(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  /// Adds [months] to [date] applying the "same day if possible, else last
  /// day of month" policy (e.g. Jan 31 + 1 → Feb 28/29; Feb 28 + 1 → Mar 31).
  ///
  /// [anchorDay] preserves the original anchor across month-end clamps so the
  /// day does not drift (Jan 31 → Feb 28 → **Mar 31**, never Mar 28).
  static DateTime addMonthsClamped(DateTime date, int months, {int? anchorDay}) {
    final target = DateTime(date.year, date.month + months, 1);
    final day = anchorDay ?? date.day;
    final lastDay = DateTime(target.year, target.month + 1, 0).day;
    return DateTime(target.year, target.month, day <= lastDay ? day : lastDay);
  }
}
