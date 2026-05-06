import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

  // ──── Feature 3 — Smart Nudges ────
  static Future<void> scheduleSmartNudges(AppProvider app) async {
    // Cancel all previous nudges to avoid duplication
    await _notificationsPlugin.cancel(id: 301);
    await _notificationsPlugin.cancel(id: 302);
    await _notificationsPlugin.cancel(id: 303);

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

    final hour = DateTime.now().hour;

    // (a) 14:00 — water nudge if < 4 glasses
    if (hour == 14 && app.waterGlasses < 4) {
      await _notificationsPlugin.show(
        id: 301,
        title: "Don't forget to hydrate! 💧",
        body: "You've only had ${app.waterGlasses} glasses — drink up!",
        notificationDetails: details,
      );
    }

    // (b) 22:00 — sleep nudge if no sleep logged
    if (hour == 22 && app.sleepHours == 0) {
      await _notificationsPlugin.show(
        id: 302,
        title: 'Time to wind down 🌙',
        body: 'No sleep logged yet — you need 8 hours.',
        notificationDetails: details,
      );
    }

    // (c) 12:00 — steps nudge if < 2000 steps
    if (hour == 12 && app.steps < 2000) {
      await _notificationsPlugin.show(
        id: 303,
        title: 'Get moving! 🚶',
        body: 'Only ${app.steps} steps so far — take a walk after lunch.',
        notificationDetails: details,
      );
    }
  }
}

