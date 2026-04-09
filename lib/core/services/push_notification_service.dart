import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'storage_service.dart';

// Local Notifications Plugin
final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Channel for Foreground Notifications
const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  description:
      'This channel is used for important notifications.', // description
  importance: Importance.high,
);

// Top-level background handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  // Ensure storage is initialized in this isolate
  await StorageService.init();
  debugPrint('Handling a background message: ${message.messageId}');

  // Save to history if it has content
  if (message.notification != null) {
    await StorageService.addNotification(
      message.notification!.title ?? 'Уведомление',
      message.notification!.body ?? '',
    );
  }
}

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  /// Initialize Firebase and FCM
  static Future<void> initialize() async {
    try {
      // 1. Initialize Firebase
      await Firebase.initializeApp();

      // 2. Initialize Local Notifications (for Foreground)
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

      // Create Notification Channel (Android)
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      // 3. Set Background Handler
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // 4. Request Permissions
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission');
      }

      // 5. Get FCM Token (Optional: Log it)
      String? token = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $token');

      // 6. Handle Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');

        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        if (notification != null && android != null) {
          // A. Save to Storage (History)
          StorageService.addNotification(
            notification.title ?? 'Уведомление',
            notification.body ?? '',
          );

          // B. Show Local Notification (Heads-up)
          _flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                _channel.id,
                _channel.name,
                channelDescription: _channel.description,
                icon: '@mipmap/ic_launcher',
                priority: Priority.high,
                importance: Importance.high,
              ),
            ),
          );
        }
      });
    } catch (e) {
      debugPrint('Firebase/Notification Initialization Failed: $e');
    }
  }
}
