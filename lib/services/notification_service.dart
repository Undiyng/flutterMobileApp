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
    // 1. Solicitar permisos (iOS y Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Permiso de notificación concedido.');
      
      // 2. Suscribirse al Topic (¡Clave!)
      // El backend debe enviar a este mismo topic.
      await _fcm.subscribeToTopic('new_promotions');
      print('Suscrito al topic: new_promotions');

      // 3. Inicializar el plugin local (para manejo de toques)
      _initLocalNotifications();

      // 4. Manejar mensajes en FOREGROUND
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 5. Manejar toque en notificación (App en BACKGROUND)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

      // 6. Manejar toque en notificación (App TERMINADA)
      _fcm.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          _handleMessageTap(message);
        }
      });

    } else {
      print('Permiso de notificación denegado.');
    }
  }

  // Inicializa el plugin local y define el callback de toque
  void _initLocalNotifications() {
    const InitializationSettings initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'), // Tu ícono
      iOS: DarwinInitializationSettings(),
    );

    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      // Callback cuando se toca una notificación (mostrada localmente)
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          _navigateToPromotion(response.payload!);
        }
      },
    );
  }

  // Maneja un mensaje recibido mientras la app está en PRIMER PLANO
  void _handleForegroundMessage(RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    
    // Si es un mensaje de notificación y estamos en Android
    if (notification != null && android != null) {
      // Muestra la notificación usando el plugin local
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id, // ID del canal de main.dart
            channel.name,
            channelDescription: channel.description,
            icon: android.smallIcon ?? '@mipmap/ic_launcher',
          ),
        ),
        // 'payload' son los datos que pasamos al callback de toque
        // Usamos el 'data' payload que enviaste desde tu backend
        payload: message.data['promotionId'], 
      );
    }
  }

  // Maneja el TOQUE en una notificación (Background o Terminated)
  void _handleMessageTap(RemoteMessage message) {
    print('App abierta desde notificación: ${message.data['promotionId']}');
    final String? promotionId = message.data['promotionId'];
    if (promotionId != null) {
      _navigateToPromotion(promotionId);
    }
  }

  // Función de ayuda para navegar
  void _navigateToPromotion(String promotionId) {
    // Usa la GlobalKey para navegar
    navigatorKey.currentState?.pushNamed(
      '/promotion-details',
      arguments: promotionId,
    );
  }
}