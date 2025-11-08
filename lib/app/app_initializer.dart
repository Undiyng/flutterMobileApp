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
    
    FirebaseMessaging.onBackgroundMessage(
      NotificationService.firebaseMessagingBackgroundHandler
    );
  }

  static Future<void> _setupLocalNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    
    // Configuración del canal SIN sonido personalizado
    channel = const AndroidNotificationChannel(
      'high_importance_channel',
      'Notificaciones Importantes',
      description: 'Este canal se usa para notificaciones importantes.',
      importance: Importance.max,
      playSound: true, // Sonido por defecto
      enableVibration: true,
      ledColor: Colors.blue,
      showBadge: true,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = 
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    await androidPlugin?.createNotificationChannel(channel);
    print('✅ Canal de notificaciones creado: ${channel.id}');

    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings = 
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings = 
        InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> _setupNotificationService() async {
    final notificationService = NotificationService(
      navigatorKey: navigatorKey,
      flutterLocalNotificationsPlugin: flutterLocalNotificationsPlugin,
      channel: channel,
    );
    
    await notificationService.init();
  }
}