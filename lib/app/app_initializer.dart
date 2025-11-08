import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/notification_service.dart';

class AppInitializer {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  static late AndroidNotificationChannel channel;

  static Future<void> initialize() async {
    await _initializeFirebase();
    await _setupLocalNotifications();
    await _setupNotificationService();
  }

  static Future<void> _initializeFirebase() async {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(NotificationService.firebaseMessagingBackgroundHandler);
  }

  static Future<void> _setupLocalNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    
    channel = const AndroidNotificationChannel(
      'promotions_channel',
      'Promociones Importantes',
      description: 'Canal para notificaciones de promociones.',
      importance: Importance.max,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> _setupNotificationService() async {
    await NotificationService(
      navigatorKey: navigatorKey,
      flutterLocalNotificationsPlugin: flutterLocalNotificationsPlugin,
      channel: channel,
    ).init();
  }
}