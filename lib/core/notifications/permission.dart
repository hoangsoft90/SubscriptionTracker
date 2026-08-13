import '../../features/settings/data/settings_repository.dart';
import 'notification_platform.dart' show NotificationPermissionStatus, NotificationPlatform;

/// Notification permission timing (spec §2.4): never at launch/onboarding —
/// only right after the user adds their first subscription, at the point a
/// reminder is being set. The "already asked" flag is persisted so the prompt
/// appears at most once. The Settings screen exposes an explicit enable entry
/// point so users who dismissed the prompt can still turn notifications on.
class NotificationPermissionService {
  NotificationPermissionService(this._platform, this._settings);

  final NotificationPlatform _platform;
  final SettingsRepository _settings;

  static const _requestedKey = 'notifPermissionRequested';

  /// Requests permission unless it was already asked before. Returns whether
  /// notifications are allowed.
  Future<bool> requestIfNeeded() async {
    if (await _settings.get(_requestedKey) == 'true') return true;
    final granted = await _platform.requestPermission();
    await _settings.set(_requestedKey, 'true');
    return granted;
  }

  /// True when the app has already shown the OS permission prompt once.
  Future<bool> wasRequested() async =>
      await _settings.get(_requestedKey) == 'true';

  /// Current OS-level permission state (no prompt).
  Future<NotificationPermissionStatus> status() =>
      _platform.permissionStatus();

  /// Explicit enable from Settings: re-requests the OS prompt when it was
  /// never shown before; otherwise the OS has likely stopped showing prompts
  /// (Android) or the user denied — open the OS settings screen instead.
  /// Returns true when a prompt was shown, false when settings were opened.
  Future<bool> enableFromSettings() async {
    if (!await wasRequested()) {
      await _platform.requestPermission();
      await _settings.set(_requestedKey, 'true');
      return true;
    }
    await _platform.openNotificationSettings();
    return false;
  }
}
