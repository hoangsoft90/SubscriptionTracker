import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Thin boundary over the OS local-notification service.
///
/// The scheduler talks only to this interface, so unit tests swap in a fake
/// and never touch platform channels.
abstract class NotificationPlatform {
  /// Initializes the plugin and the timezone database (idempotent).
  Future<void> initialize();

  /// Requests notification permission (Android 13+ / iOS). Returns whether
  /// notifications are allowed.
  Future<bool> requestPermission();

  /// Schedules a local notification to fire at [when] (local wall-clock time).
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  });

  /// Cancels the pending notification with [id] (no-op if unknown).
  Future<void> cancel(int id);

  /// Cancels every pending notification belonging to the app.
  Future<void> cancelAll();
}

/// [NotificationPlatform] backed by `flutter_local_notifications`.
class LocalNotificationPlatform implements NotificationPlatform {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId = 'subtrack_reminders';
  static const _channelName = 'Renewal & trial reminders';
  static const _channelDescription =
      'Upcoming subscription renewals and trial-end reminders.';

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    // Web has no local-notification plugin; everything becomes a no-op.
    if (kIsWeb) {
      _initialized = true;
      return;
    }
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Fall back to tz.local default; scheduling still uses absolute times.
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    await initialize();
    if (kIsWeb) return true; // no permission model on web
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? true;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return await ios?.requestPermissions(alert: true, badge: true, sound: true) ??
          true;
    }
    return true;
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    await initialize();
    if (kIsWeb) return; // no local notifications on web
    final tzWhen = tz.TZDateTime.from(when, tz.local);
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzWhen,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  @override
  Future<void> cancel(int id) async {
    if (kIsWeb) return;
    await _plugin.cancel(id: id);
  }

  @override
  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _plugin.cancelAllPendingNotifications();
  }
}
