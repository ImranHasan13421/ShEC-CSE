import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final ValueNotifier<Map<String, int>> unreadCounts = ValueNotifier({
    'notices': 0,
    'jobs': 0,
    'contests': 0,
    'messenger': 0,
  });

  static Future<void> initialize() async {
    if (kIsWeb) return; // Local notifications skip for web for now

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(settings: initializationSettings);

    // Request permission for Android 13+
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return; // Skip showing local notifications on web
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'shec_cse_channel',
      'ShEC CSE Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
      payload: payload,
    );
  }

  static void incrementUnread(String category) {
    final current = Map<String, int>.from(unreadCounts.value);
    current[category] = (current[category] ?? 0) + 1;
    unreadCounts.value = current;
  }

  static void clearUnread(String category) {
    final current = Map<String, int>.from(unreadCounts.value);
    current[category] = 0;
    unreadCounts.value = current;
  }
}
