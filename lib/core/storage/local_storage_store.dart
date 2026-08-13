import 'dart:convert';

/// Minimal synchronous key/value storage — the single seam between the app
/// and the browser's `localStorage` (web). Native platforms never touch this;
/// the SQLite path (`AppDatabase`) is the storage backend there.
///
/// Tests inject an in-memory [KeyValueStorage] so the whole store + repository
/// layer is testable on the VM without a browser.
abstract class KeyValueStorage {
  String? getItem(String key);
  void setItem(String key, String value);
  void removeItem(String key);
}

/// JSON-encoded row store over [KeyValueStorage].
///
/// Layout (all keys prefixed with [prefix], default `subtrack_`):
/// - `categories`      → JSON array of category row maps
/// - `subscriptions`   → JSON array of subscription row maps
/// - `settings`        → JSON map of setting key → value
/// - `price_history`   → JSON map of subscriptionId → array of history rows
///
/// Rows are stored as the same `toMap()`/`fromMap()` shapes used by the
/// SQLite repositories, so the domain models and repository interfaces are
/// identical across platforms — only the persistence medium differs.
class LocalStorageStore {
  LocalStorageStore(this._storage);

  final KeyValueStorage _storage;

  /// Key prefix separating this app's keys from anything else in the
  /// browser's localStorage.
  static const _prefix = 'subtrack_';

  static const categoriesKey = 'categories';
  static const subscriptionsKey = 'subscriptions';
  static const settingsKey = 'settings';
  static const priceHistoryKey = 'price_history';

  String _key(String key) => '$_prefix$key';

  // --- generic row lists ------------------------------------------------

  List<Map<String, Object?>> readRows(String key) {
    final raw = _storage.getItem(_key(key));
    if (raw == null) return <Map<String, Object?>>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return <Map<String, Object?>>[];
    return <Map<String, Object?>>[
      for (final e in decoded)
        if (e is Map) Map<String, Object?>.from(e),
    ];
  }

  void writeRows(String key, List<Map<String, Object?>> rows) {
    if (rows.isEmpty) {
      _storage.removeItem(_key(key));
    } else {
      _storage.setItem(_key(key), jsonEncode(rows));
    }
  }

  // --- settings (a single JSON map) --------------------------------------

  Map<String, String> readSettings() {
    final raw = _storage.getItem(_key(settingsKey));
    if (raw == null) return <String, String>{};
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return <String, String>{};
    return {
      for (final e in decoded.entries) e.key.toString(): e.value.toString(),
    };
  }

  void writeSettings(Map<String, String> values) {
    _storage.setItem(_key(settingsKey), jsonEncode(values));
  }

  String? getSetting(String key) => readSettings()[key];

  void setSetting(String key, String value) {
    final settings = Map<String, String>.from(readSettings());
    settings[key] = value;
    writeSettings(settings);
  }

  // --- price history (subscriptionId → rows) -----------------------------

  Map<String, List<Map<String, Object?>>> readPriceHistory() {
    final raw = _storage.getItem(_key(priceHistoryKey));
    if (raw == null) return <String, List<Map<String, Object?>>>{};
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return <String, List<Map<String, Object?>>>{};
    return {
      for (final e in decoded.entries)
        e.key.toString(): [
          // Guard like readRows/readSettings: a corrupt value (not a List)
          // must never crash reads.
          if (e.value is List)
            for (final r in e.value as List)
              if (r is Map) Map<String, Object?>.from(r),
        ],
    };
  }

  void writePriceHistory(Map<String, List<Map<String, Object?>>> history) {
    if (history.isEmpty) {
      _storage.removeItem(_key(priceHistoryKey));
    } else {
      _storage.setItem(_key(priceHistoryKey), jsonEncode(history));
    }
  }
}
