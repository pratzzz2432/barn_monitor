import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  // Initialize the service
  Future<void> init() async {
    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    // Configure local notifications
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) async {
        // Handle notification tap
        print('Notification clicked: ${details.payload}');
      },
    );

    // Configure Firebase Messaging
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        _showLocalNotification(message);
      }
    });

    // Get FCM token
    String? token = await _messaging.getToken();
    print('FCM Token: $token');
  }

  // Show a local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'barn_air_channel',
            'BarnAir Alerts',
            channelDescription: 'Important alerts about barn conditions',
            importance: Importance.high,
            priority: Priority.high,
            ticker: 'ticker',
            color: const Color(0xFFF44336),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data['barnId'],
      );
    }
  }

  // Subscribe to a topic (for barn-specific alerts)
  Future<void> subscribeToBarnAlerts(String barnId) async {
    await _messaging.subscribeToTopic('barn_$barnId');
  }

  // Unsubscribe from a topic
  Future<void> unsubscribeFromBarnAlerts(String barnId) async {
    await _messaging.unsubscribeFromTopic('barn_$barnId');
  }
}