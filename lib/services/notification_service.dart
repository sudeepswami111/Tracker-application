import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/app_provider.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const _nudgeChannelId = 'lifepulse_nudge';
  static const _nudgeChannelName = 'LifePulse Smart Nudges';

  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
    );
  }

  static Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'lifepulse_channel',
      'LifePulse Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
    );
  }

  // ──── Feature 3 — Smart Nudges (fires at most once per day per nudge) ────
  static Future<void> scheduleSmartNudges(AppProvider app) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayStr();
    final hour = DateTime.now().hour;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _nudgeChannelId,
      _nudgeChannelName,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    // (a) 14:00 — water nudge if < 4 glasses
    if (hour == 14 && app.waterGlasses < 4) {
      final key = 'nudge_301_$today';
      if (prefs.getString(key) == null) {
        await prefs.setString(key, 'sent');
        await _notificationsPlugin.show(
          id: 301,
          title: "Don't forget to hydrate! 💧",
          body: "You've only had ${app.waterGlasses} glasses — drink up!",
          notificationDetails: details,
        );
      }
    }

    // (b) 22:00 — sleep nudge if no sleep logged
    if (hour == 22 && app.sleepHours == 0) {
      final key = 'nudge_302_$today';
      if (prefs.getString(key) == null) {
        await prefs.setString(key, 'sent');
        await _notificationsPlugin.show(
          id: 302,
          title: 'Time to wind down ðŸŒ™',
          body: 'No sleep logged yet — you need 8 hours.',
          notificationDetails: details,
        );
      }
    }

    // (c) 12:00 — steps nudge if < 2000 steps
    if (hour == 12 && app.steps < 2000) {
      final key = 'nudge_303_$today';
      if (prefs.getString(key) == null) {
        await prefs.setString(key, 'sent');
        await _notificationsPlugin.show(
          id: 303,
          title: 'Get moving! 🚶',
          body: 'Only ${app.steps} steps so far — take a walk after lunch.',
          notificationDetails: details,
        );
      }
    }
  }

  static String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
