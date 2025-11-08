import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert'; // Para codificar/decodificar JSON

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
          try {
            // Decodificar el JSON del payload
            Map<String, dynamic> payloadData = jsonDecode(response.payload!);
            _navigateToPromotion(
              payloadData['promotionId'] ?? 'default_id',
              payloadData['title'] ?? 'Sin título',
              payloadData['body'] ?? 'Sin contenido',
            );
          } catch (e) {
            print('Error al decodificar payload: $e');
            // Si hay error, usar valores por defecto
            _navigateToPromotion(
              response.payload!,
              'Nueva Promoción',
              'Toca para ver más detalles'
            );
          }
        }
      },
    );
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('Mensaje en foreground: ${message.notification?.title}');
    
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    
    if (notification != null && android != null) {
      // Crear un mapa con todos los datos de la notificación
      Map<String, dynamic> payloadData = {
        'promotionId': message.data['promotionId'] ?? 'default_id',
        'title': notification.title ?? 'Nueva Promoción',
        'body': notification.body ?? 'Toca para ver más detalles',
      };
      
      // Convertir a JSON string para el payload
      String payload = jsonEncode(payloadData);
      
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
        payload: payload, // Enviar todos los datos como JSON
      );
    }
  }

  void _handleMessageTap(RemoteMessage message) {
    final String? promotionId = message.data['promotionId'];
    final String title = message.notification?.title ?? 'Nueva Promoción';
    final String body = message.notification?.body ?? 'Toca para ver más detalles';
    
    if (promotionId != null) {
      _navigateToPromotion(promotionId, title, body);
    } else {
      print('No se encontró promotionId en el mensaje');
      // Navegar incluso sin promotionId, mostrando título y cuerpo
      _navigateToPromotion('default_id', title, body);
    }
  }

  void _navigateToPromotion(String promotionId, String title, String body) {
    print('Navegando a promoción con ID: $promotionId, Título: $title');
    
    Future.delayed(Duration(milliseconds: 500), () {
      navigatorKey.currentState?.pushNamed(
        '/promotion-details',
        arguments: {
          'promotionId': promotionId,
          'title': title,
          'body': body,
        },
      );
    });
  }
}