import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:workmanager/workmanager.dart';

import '../../features/settings/data/settings_repository.dart';
import '../../features/subscriptions/data/subscription_repository.dart';
import '../../features/subscriptions/domain/subscription_status.dart';
import '../storage/app_database.dart';
import 'notification_platform.dart';
import 'notification_scheduler.dart';

/// Android-only post-reboot recovery (spec §2.4 / design D2).
///
/// A periodic WorkManager task survives device reboots (AndroidX WorkManager
/// restores periodic jobs), so it re-runs `reconcile()` after reboot — on iOS
/// the OS restores scheduled local notifications automatically and no
/// workmanager task is registered there.
abstract final class RebootRescheduler {
  static const taskName = 'subtrackReconcile';
  static const _uniqueName = 'subtrack-periodic-reconcile';

  static bool _initialized = false;

  /// Must be called once at app start (Android only).
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await Workmanager().initialize(subtrackBackgroundDispatcher);
      await Workmanager().registerPeriodicTask(
        _uniqueName,
        taskName,
        frequency: const Duration(hours: 12),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
    } catch (_) {
      // Background scheduling is best-effort; reconcile still runs on every
      // app open / data change.
    }
  }
}

/// Workmanager entry point (background isolate). Must be top-level and
/// annotated so the VM keeps it for entry.
@pragma('vm:entry-point')
void subtrackBackgroundDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == RebootRescheduler.taskName) {
      await _runBackgroundReconcile();
    }
    return true;
  });
}

/// Runs one reconcile pass from the background isolate. Uses the FFI sqlite
/// factory so the database works without the main-isolate sqflite factory.
Future<void> _runBackgroundReconcile() async {
  try {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final dir = await getApplicationDocumentsDirectory();
    final db = await AppDatabase.open(
      path: '${dir.path}/${AppDatabase.defaultFileName}',
    );
    final scheduler = NotificationScheduler(
      platform: LocalNotificationPlatform(),
      loadActive: () async {
        final repo = SqfliteSubscriptionRepository(db);
        final all = await repo.getAll();
        return all
            .where((s) => s.status == SubscriptionStatus.active)
            .toList();
      },
      settings: SqfliteSettingsRepository(db),
    );
    await scheduler.reconcile();
    await db.close();
  } catch (_) {
    // Swallow background failures: the next app open reconciles anyway.
  }
}
