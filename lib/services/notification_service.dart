import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Importa las variables globales de main.dart
import '../main.dart'; 

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final GlobalKey<NavigatorState> navigatorKey;

  NotificationService({required this.navigatorKey});

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

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Mensaje en foreground recibido: ${message.messageId}');
        _handleForegroundMessage(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('App abierta desde notificación en background: ${message.data['promotionId']}');
        _handleMessageTap(message);
      });

      _fcm.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          print('App abierta desde notificación con app terminada: ${message.data['promotionId']}');
          _handleMessageTap(message);
        }
      });

      _configureBackgroundNotifications();

    } else {
      print('Permiso de notificación denegado.');
    }
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
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          print('Notificación tocada con payload: ${response.payload}');
          _navigateToPromotion(response.payload!);
        }
      },
    );
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('Mensaje en foreground: ${message.notification?.title}');
    
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    
    if (notification != null && android != null) {
      // VERSIÓN SIMPLIFICADA: Sin vibración personalizada
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title ?? 'Nueva promoción',
        notification.body ?? 'Toca para ver los detalles',
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: android.smallIcon ?? '@mipmap/ic_launcher',
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
        payload: message.data['promotionId'] ?? 'default_id',
      );
    }
  }

  void _handleMessageTap(RemoteMessage message) {
    final String? promotionId = message.data['promotionId'];
    if (promotionId != null) {
      _navigateToPromotion(promotionId);
    } else {
      print('No se encontró promotionId en el mensaje');
    }
  }

  void _navigateToPromotion(String promotionId) {
    print('Navegando a promoción con ID: $promotionId');
    
    Future.delayed(Duration(milliseconds: 500), () {
      navigatorKey.currentState?.pushNamed(
        '/promotion-details',
        arguments: promotionId,
      );
    });
  }
}