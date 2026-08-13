import '../../features/settings/data/settings_repository.dart';
import 'notification_scheduler.dart';
import 'permission.dart';

/// Orchestrates notification triggers (spec §2.4):
///
/// - app open → timezone re-check + reconcile
/// - subscription add/edit/delete/status change → reconcile
/// - permission requested only after the first subscription is added
///
/// Delivery itself never depends on background refresh — the OS fires the
/// scheduled local notifications directly; reconcile() keeps the schedule
/// correct on the triggers above.
class NotificationCoordinator {
  NotificationCoordinator({
    required this.scheduler,
    required this.permission,
    required this.settings,
    required this.currentTimezone,
  });

  final NotificationScheduler scheduler;
  final NotificationPermissionService permission;
  final SettingsRepository settings;

  /// Returns the device IANA timezone name (e.g. "Asia/Ho_Chi_Minh").
  final Future<String> Function() currentTimezone;

  static const _tzKey = 'lastTimeZone';

  bool _appOpenHandled = false;

  /// App open trigger. Runs once per process: compares the device timezone
  /// with the persisted one (reconcile on change per spec §2.4 — covered by
  /// the app-open reconcile below), then reconciles so the schedule is always
  /// fresh.
  Future<void> onAppOpen() async {
    if (_appOpenHandled) return;
    _appOpenHandled = true;
    await _checkTimezone();
    await scheduler.reconcile();
  }

  Future<void> _checkTimezone() async {
    String name;
    try {
      name = await currentTimezone();
    } catch (_) {
      return; // platform tz unavailable → nothing to compare
    }
    final stored = await settings.get(_tzKey);
    if (stored != name) {
      await settings.set(_tzKey, name);
    }
  }

  /// Subscription data changed (add/edit/delete/status) → reconcile so stale
  /// reminders are cancelled and new ones scheduled.
  Future<void> onSubscriptionsChanged() => scheduler.reconcile();

  /// Permission timing: requests once, right after the user adds their first
  /// subscription (total count == 1).
  Future<bool> maybeRequestPermissionAfterFirstSubscription({
    required int totalSubscriptions,
  }) async {
    if (totalSubscriptions == 1) return permission.requestIfNeeded();
    return true;
  }
}
