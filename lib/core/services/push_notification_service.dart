import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class PushNotificationService {
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      // 1. Initialize Firebase
      // Note: This requires google-services.json on Android
      await Firebase.initializeApp();

      final messaging = FirebaseMessaging.instance;

      // 2. Request permission
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // 3. Initialize Local Notifications (for foreground messages)
      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
      await _localNotificationsPlugin.initialize(initializationSettings);

      // 4. Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showLocalNotification(message);
      });

      // 5. Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      print('Push Notification Service Initialized');
    } catch (e) {
      debugPrint('Firebase Initialization Error: $e');
      debugPrint('Make sure you have added google-services.json to android/app/');
    }
  }

  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    print("Handling a background message: ${message.messageId}");
  }

  static void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null && !kIsWeb) {
      _localNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }
  }

  static Future<void> updateTokenInDatabase(SupabaseClient supabase) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await supabase.from('users').update({'fcm_token': token}).eq('id', user.id);
        print('FCM Token updated: $token');
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }
}
