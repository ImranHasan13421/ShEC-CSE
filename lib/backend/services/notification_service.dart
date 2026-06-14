import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ShEC_CSE/main.dart'; // for navigatorKey
import 'package:ShEC_CSE/features/dashboard/screens/main_screen.dart'; // for HomeLayout
import 'package:ShEC_CSE/features/messenger/screens/chat_screen.dart';
import 'package:ShEC_CSE/features/notices/screens/notice_detail_screen.dart';
import 'package:ShEC_CSE/features/jobs/screens/job_detail_screen.dart';
import 'package:ShEC_CSE/features/jobs/screens/jobs_screen.dart';

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

    // Initialize Firebase
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Error initializing Firebase in NotificationService: $e');
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null) {
          try {
            final data = jsonDecode(payload) as Map<String, dynamic>;
            _handleNotificationClick(data);
          } catch (e) {
            debugPrint('Error parsing notification payload: $e');
          }
        }
      },
    );

    // Request permission for Android 13+
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Firebase Messaging Listeners
    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification?.title}');
        showNotification(
          id: message.notification.hashCode,
          title: message.notification?.title ?? 'Notification',
          body: message.notification?.body ?? '',
          payload: jsonEncode(message.data),
        );
      }
    });

    // Background message click handler (app was in background but running)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM Notification clicked while app was in background: ${message.data}');
      _handleNotificationClick(message.data);
    });

    // Terminated state click handler (app was completely terminated)
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('FCM Notification clicked and launched app from terminated state: ${message.data}');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 500), () {
            _handleNotificationClick(message.data);
          });
        });
      }
    });

    // Background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request direct Firebase permission (iOS & Android 13+)
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Fetch and sync FCM token if user is signed in
    await syncFCMToken();

    // Token refresh listener
    messaging.onTokenRefresh.listen((token) async {
      await _uploadTokenToSupabase(token);
    });
  }

  static void _handleNotificationClick(Map<String, dynamic> data) {
    debugPrint('Handling notification click with data: $data');
    final table = data['table']?.toString();
    final id = data['id']?.toString();
    final roomId = data['room_id']?.toString();

    final context = navigatorKey.currentState?.context;
    if (context == null) {
      debugPrint('Navigator state context is null. Skipping navigation.');
      return;
    }

    if (table == 'messages') {
      if (roomId != null && roomId.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(roomId: roomId),
          ),
        );
      } else {
        HomeLayout.activeTab.value = 2;
      }
    } else if (table == 'notices') {
      if (id != null && id.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NoticeDetailScreen(noticeId: id),
          ),
        );
      } else {
        HomeLayout.activeTab.value = 1;
      }
    } else if (table == 'jobs') {
      if (id != null && id.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => JobDetailScreen(jobId: id),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const JobsScreen(),
          ),
        );
      }
    } else if (table == 'contests') {
      Navigator.popUntil(context, (route) => route.isFirst);
      HomeLayout.activeTab.value = 3;
    }
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

  static Future<void> syncFCMToken() async {
    if (kIsWeb) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _uploadTokenToSupabase(token);
      }
    } catch (e) {
      debugPrint('Error fetching FCM token: $e');
    }
  }

  static Future<void> _uploadTokenToSupabase(String token) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user != null) {
      try {
        await client.from('profiles').update({
          'fcm_token': token,
        }).eq('id', user.id);
        debugPrint('FCM Token successfully uploaded/updated in Supabase profiles.');
      } catch (e) {
        debugPrint('Error updating FCM Token in Supabase profiles: $e');
      }
    }
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}
