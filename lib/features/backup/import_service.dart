import '../../core/calendar/date_utils.dart';
import '../../features/categories/data/category_repository.dart';
import '../../features/categories/domain/category.dart';
import '../../features/settings/data/settings_repository.dart';
import '../../features/subscriptions/data/subscription_repository.dart';
import '../../features/subscriptions/domain/subscription.dart';
import 'backup_models.dart';

/// Merge keeps existing rows (duplicate IDs skipped) and inserts new ones;
/// Replace All wipes existing data first (explicitly confirmed by the user).
enum ImportStrategy { merge, replaceAll }

/// Counts shown in the import preview before any mutation (spec §2.6).
class ImportPreview {
  const ImportPreview({
    required this.subscriptionCount,
    required this.categoryCount,
    this.settingsSummary,
  });

  final int subscriptionCount;
  final int categoryCount;
  final String? settingsSummary;
}

/// Result of an applied import.
class ImportResult {
  const ImportResult({required this.importedSubscriptions, required this.importedCategories});

  final int importedSubscriptions;
  final int importedCategories;
}

/// Validates and applies backups (spec §2.6):
///
/// 1. `preview()` — validate marker + schemaVersion (reject non-backup /
///    future versions with a clear error) and return counts, before any
///    mutation.
/// 2. `apply()` — Merge (skip existing IDs, insert new) or Replace All
///    (delete everything, then restore). Re-importing the same backup with
///    Merge never duplicates.
class BackupImportService {
  BackupImportService({
    required this.subscriptions,
    required this.categories,
    required this.settings,
  });

  final SubscriptionRepository subscriptions;
  final CategoryRepository categories;
  final SettingsRepository settings;

  /// Parses + validates [raw] and returns the preview counts. Throws
  /// [BackupValidationException] before any data is touched.
  Future<ImportPreview> preview(String raw) async {
    final file = BackupFile.decode(raw);
    String? settingsSummary;
    final currency = file.settings['primaryCurrency'];
    if (currency != null) {
      settingsSummary = 'primaryCurrency=$currency';
    }
    return ImportPreview(
      subscriptionCount: file.subscriptionCount,
      categoryCount: file.categoryCount,
      settingsSummary: settingsSummary,
    );
  }

  /// Applies [file] with the chosen [strategy].
  Future<ImportResult> apply(BackupFile file, {required ImportStrategy strategy}) async {
    switch (strategy) {
      case ImportStrategy.merge:
        return _applyMerge(file);
      case ImportStrategy.replaceAll:
        return _applyReplace(file);
    }
  }

  Future<ImportResult> _applyMerge(BackupFile file) async {
    var importedCategories = 0;
    final existingCategoryIds = {
      for (final c in await categories.getAll()) c.id,
    };
    for (final row in file.categories) {
      final category = Category.fromMap(row);
      if (existingCategoryIds.contains(category.id)) continue; // skip duplicate
      await categories.insert(category);
      existingCategoryIds.add(category.id);
      importedCategories++;
    }

    var importedSubscriptions = 0;
    final existingSubIds = {
      for (final s in await subscriptions.getAll()) s.id,
    };
    for (final row in file.subscriptions) {
      final sub = _importedSubscription(row);
      if (existingSubIds.contains(sub.id)) continue; // skip duplicate
      await subscriptions.insert(sub);
      existingSubIds.add(sub.id);
      importedSubscriptions++;
    }

    await _applySettings(file);
    return ImportResult(
      importedSubscriptions: importedSubscriptions,
      importedCategories: importedCategories,
    );
  }

  Future<ImportResult> _applyReplace(BackupFile file) async {
    // FK order matters (PRAGMA foreign_keys = ON): subscriptions reference
    // categories, so child rows must be wiped first — deleting categories
    // while subscriptions still point at them would raise a FK violation.
    await subscriptions.deleteAll();
    await categories.deleteAll();
    await _applySettings(file, replace: true);

    var importedCategories = 0;
    for (final row in file.categories) {
      await categories.insert(Category.fromMap(row));
      importedCategories++;
    }
    var importedSubscriptions = 0;
    for (final row in file.subscriptions) {
      await subscriptions.insert(_importedSubscription(row));
      importedSubscriptions++;
    }
    return ImportResult(
      importedSubscriptions: importedSubscriptions,
      importedCategories: importedCategories,
    );
  }

  /// Import hygiene (plan2_final §3.2): a restored subscription is treated as
  /// reviewed at its creation date, so a fresh import never creates a fake
  /// stale backlog (last_reviewed_at = created_at when unset).
  Subscription _importedSubscription(Map<String, Object?> row) {
    final sub = Subscription.fromMap(row);
    if (sub.lastReviewedAt != null) return sub;
    return sub.copyWith(
      lastReviewedAt: DateUtils.localMidnight(sub.createdAt),
    );
  }

  Future<void> _applySettings(BackupFile file, {bool replace = false}) async {
    final currency = file.settings['primaryCurrency'];
    if (currency != null && (replace || await settings.get('primaryCurrency') == null)) {
      await settings.set('primaryCurrency', currency);
    }
    final language = file.settings['language'];
    if (language != null && (replace || await settings.get('language') == null)) {
      await settings.set('language', language);
    }
  }
}
