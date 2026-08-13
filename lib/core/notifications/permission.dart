import '../../features/settings/data/settings_repository.dart';
import 'notification_platform.dart';

/// Notification permission timing (spec §2.4): never at launch/onboarding —
/// only right after the user adds their first subscription, at the point a
/// reminder is being set. The "already asked" flag is persisted so the prompt
/// appears at most once.
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
}
