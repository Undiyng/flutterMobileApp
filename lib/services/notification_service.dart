import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import '../app/routes/app_routes.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final GlobalKey<NavigatorState> navigatorKey;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final AndroidNotificationChannel channel;

  bool _isNotificationHandled = false;

  NotificationService({
    required this.navigatorKey,
    required this.flutterLocalNotificationsPlugin,
    required this.channel,
  });

  // Manejador de background como método estático
  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    
    print("Handling a background message: ${message.messageId}");
    
    const AndroidNotificationChannel backgroundChannel = AndroidNotificationChannel(
      'promotions_channel_background',
      'Promociones Importantes',
      description: 'Canal para notificaciones de promociones en background.',
      importance: Importance.max,
    );

    FlutterLocalNotificationsPlugin backgroundPlugin = FlutterLocalNotificationsPlugin();
    
    await backgroundPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(backgroundChannel);

    const InitializationSettings initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    
    await backgroundPlugin.initialize(initializationSettings);

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    
    if (notification != null && android != null) {
      await backgroundPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            backgroundChannel.id,
            backgroundChannel.name,
            channelDescription: backgroundChannel.description,
            icon: android.smallIcon ?? '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
          ),
        ),
        payload: message.data['promotionId'],
      );
    }
  }

  Future<void> init() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Permiso de notificación concedido.');
      
      await _fcm.subscribeToTopic('new_promotions');
      print('Suscrito al topic: new_promotions');

      _initLocalNotifications();
      _setupFirebaseListeners();
      _configureBackgroundNotifications();
    } else {
      print('Permiso de notificación denegado.');
    }
  }

  void _setupFirebaseListeners() {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);
    
    _fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('App abierta desde notificación con app terminada: ${message.data}');
        Future.delayed(Duration(milliseconds: 1000), () {
          _handleMessageTap(message);
        });
      }
    });
  }

  void _configureBackgroundNotifications() {
    FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void _initLocalNotifications() {
    const InitializationSettings initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
    );
  }

  void _handleLocalNotificationTap(NotificationResponse response) {
    if (_isNotificationHandled) return;
    _isNotificationHandled = true;
    
    print('Notificación local tocada con payload: ${response.payload}');
    
    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        Map<String, dynamic> payloadData = jsonDecode(response.payload!);
        _navigateToPromotion(
          payloadData['promotionId'] ?? 'default_id',
          payloadData['title'] ?? 'Sin título',
          payloadData['body'] ?? 'Sin contenido',
        );
      } catch (e) {
        print('Error al decodificar payload: $e');
        _navigateToPromotion(
          response.payload!,
          'Nueva Promoción',
          'Toca para ver más detalles'
        );
      }
    } else {
      print('Payload vacío en notificación local');
      _navigateToPromotion(
        'default_id',
        'Nueva Promoción',
        'Toca para ver más detalles'
      );
    }

    _resetNotificationHandler();
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('Mensaje en foreground: ${message.notification?.title}');
    
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    
    if (notification != null) {
      Map<String, dynamic> payloadData = {
        'promotionId': message.data['promotionId'] ?? 
                      message.data['promotion_id'] ?? 
                      message.data['id'] ?? 
                      'default_id',
        'title': notification.title ?? 'Nueva Promoción',
        'body': notification.body ?? 'Toca para ver más detalles',
      };
      
      payloadData.addAll(message.data);
      
      String payload = jsonEncode(payloadData);
      
      flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch,
        notification.title ?? 'Nueva promoción',
        notification.body ?? 'Toca para ver los detalles',
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
            color: Colors.blue,
            enableVibration: true,
            playSound: true,
            timeoutAfter: 5000,
            showWhen: true,
            autoCancel: true,
          ),
        ),
        payload: payload,
      );
    }
  }

  void _handleMessageTap(RemoteMessage message) {
    if (_isNotificationHandled) return;
    _isNotificationHandled = true;

    print('Manejando tap de mensaje FCM: ${message.data}');
    
    final String promotionId = message.data['promotionId'] ?? 
                              message.data['promotion_id'] ?? 
                              message.data['id'] ?? 
                              'default_id';
    
    final String title = message.notification?.title ?? 
                        message.data['title'] ?? 
                        'Nueva Promoción';
    
    final String body = message.notification?.body ?? 
                       message.data['body'] ?? 
                       message.data['message'] ?? 
                       'Toca para ver más detalles';

    _navigateToPromotion(promotionId, title, body);
    _resetNotificationHandler();
  }

  void _resetNotificationHandler() {
    Future.delayed(Duration(seconds: 2), () {
      _isNotificationHandled = false;
    });
  }

  void _navigateToPromotion(String promotionId, String title, String body) {
    print('Navegando a promoción con ID: $promotionId, Título: $title');
    
    Future.delayed(Duration(milliseconds: 300), () {
      if (navigatorKey.currentState?.mounted ?? false) {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRoutes.promotionDetails,
          (route) => route.isFirst,
          arguments: {
            'promotionId': promotionId,
            'title': title,
            'body': body,
          },
        );
      } else {
        Future.delayed(Duration(milliseconds: 500), () {
          if (navigatorKey.currentState?.mounted ?? false) {
            navigatorKey.currentState?.pushNamed(
              AppRoutes.promotionDetails,
              arguments: {
                'promotionId': promotionId,
                'title': title,
                'body': body,
              },
            );
          }
        });
      }
    });
  }
}