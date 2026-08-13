import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../features/categories/data/category_repository.dart';
import '../../features/settings/data/settings_repository.dart';
import '../../features/subscriptions/data/subscription_repository.dart';
import 'backup_models.dart';

/// Gathers the current data into a versioned [BackupFile] and hands it off
/// via the OS share sheet (spec §2.6) — no cloud, no account.
class BackupExportService {
  BackupExportService({
    required this.subscriptions,
    required this.categories,
    required this.settings,
    this.appVersion = '1.0.0',
  });

  final SubscriptionRepository subscriptions;
  final CategoryRepository categories;
  final SettingsRepository settings;
  final String appVersion;

  /// Builds a backup snapshot from the live repositories.
  Future<BackupFile> buildFile({DateTime? now}) async {
    final subs = await subscriptions.getAll();
    final cats = await categories.getAll();
    final settingsSnapshot = <String, String>{};
    for (final key in const ['primaryCurrency', 'language']) {
      final value = await settings.get(key);
      if (value != null && value != 'system') {
        settingsSnapshot[key] = value;
      }
    }
    return BackupFile(
      schemaVersion: BackupFormat.currentSchemaVersion,
      exportedAt: (now ?? DateTime.now()).toUtc(),
      appVersion: appVersion,
      settings: settingsSnapshot,
      categories: [for (final c in cats) c.toMap()],
      subscriptions: [for (final s in subs) s.toMap()],
    );
  }

  /// Writes the backup to a temp file and opens the OS share sheet.
  Future<void> share(BackupFile file) async {
    final dir = await getTemporaryDirectory();
    final stamp = file.exportedAt.toLocal().toIso8601String().replaceAll(':', '-');
    final path = '${dir.path}/subtrack_backup_$stamp.json';
    await File(path).writeAsString(file.encode());
    await SharePlus.instance.share(
      ShareParams(files: [XFile(path, mimeType: 'application/json')]),
    );
  }
}
