import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import '../app/routes/app_routes.dart';

// AÑADE ESTA ANOTACIÓN A LA CLASE
@pragma('vm:entry-point')
class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final GlobalKey<NavigatorState> navigatorKey;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final AndroidNotificationChannel channel;

  bool _isNotificationHandled = false;
  int _notificationId = 0;

  NotificationService({
    required this.navigatorKey,
    required this.flutterLocalNotificationsPlugin,
    required this.channel,
  });

  // Handler de background
  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    print("🔄 Handling background message: ${message.messageId}");

    // En segundo plano, FCM maneja la notificación automáticamente
    // Solo necesitamos asegurar que el canal existe
    final FlutterLocalNotificationsPlugin backgroundPlugin = FlutterLocalNotificationsPlugin();
    
    const AndroidNotificationChannel backgroundChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'Notificaciones Importantes',
      description: 'Este canal se usa para notificaciones importantes.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await backgroundPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(backgroundChannel);
        
    print("✅ Canal de background verificado");
    
    // MOSTRAR NOTIFICACIÓN EN SEGUNDO PLANO
    await _showBackgroundNotification(backgroundPlugin, message);
  }

  static Future<void> _showBackgroundNotification(
    FlutterLocalNotificationsPlugin plugin, 
    RemoteMessage message
  ) async {
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      final String title = notification.title ?? data['title'] ?? 'Nueva Promoción';
      final String body = notification.body ?? data['body'] ?? data['message'] ?? 'Toca para ver más detalles';
      final String promotionId = data['promotionId'] ?? 
                                data['promotion_id'] ?? 
                                data['id'] ?? 
                                'default_id';

      final Map<String, dynamic> payloadData = {
        'promotionId': promotionId,
        'title': title,
        'body': body,
      };
      payloadData.addAll(data);

      try {
        // CONFIGURACIÓN PARA BANNERS EN SEGUNDO PLANO
        const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
          'high_importance_channel',
          'Notificaciones Importantes',
          channelDescription: 'Este canal se usa para notificaciones importantes.',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'Nueva promoción disponible',
          playSound: true,
          enableVibration: true,
          color: Colors.blue,
          ledColor: Colors.blue,
          ledOnMs: 1000,
          ledOffMs: 500,
          showWhen: true,
          autoCancel: true,
          visibility: NotificationVisibility.public,
          timeoutAfter: 10000,
          styleInformation: BigTextStyleInformation(''),
        );

        const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

        int notificationId = (message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch) % 2147483647;
        
        await plugin.show(
          notificationId,
          title,
          body,
          const NotificationDetails(
            android: androidDetails,
            iOS: iosDetails,
          ),
          payload: jsonEncode(payloadData),
        );
        
        print("✅ Notificación de BACKGROUND mostrada: $title");
      } catch (e) {
        print("❌ Error en background notification: $e");
      }
    }
  }

  // ... (el resto del código se mantiene igual)
  Future<void> init() async {
    try {
      _setupLocalNotificationHandlers();

      final NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('📱 Estado de permisos: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Permiso de notificación concedido.');
        
        await _fcm.subscribeToTopic('new_promotions');
        print('✅ Suscrito al topic: new_promotions');

        _setupFirebaseListeners();

        final String? token = await _fcm.getToken();
        print('🔥 FCM Token: $token');

      } else {
        print('❌ Permiso de notificación denegado.');
      }
    } catch (e) {
      print('❌ Error inicializando notificaciones: $e');
    }
  }

  void _setupLocalNotificationHandlers() {
    flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleLocalNotificationTap(response);
      },
    );
  }

  void _setupFirebaseListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📱 Mensaje en FOREGROUND recibido: ${message.messageId}');
      _handleForegroundMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📱 App abierta desde BACKGROUND: ${message.data}');
      _handleMessageTap(message);
    });

    _fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('📱 App abierta desde TERMINATED: ${message.data}');
        Future.delayed(const Duration(milliseconds: 1500), () {
          _handleMessageTap(message);
        });
      }
    });
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('🎯 Creando notificación local para FOREGROUND');
    
    final notification = message.notification;
    final data = message.data;

    String title = notification?.title ?? data['title'] ?? 'Nueva Promoción';
    String body = notification?.body ?? data['body'] ?? data['message'] ?? 'Toca para ver más detalles';
    String promotionId = data['promotionId'] ?? 
                        data['promotion_id'] ?? 
                        data['id'] ?? 
                        'default_id';

    final Map<String, dynamic> payloadData = {
      'promotionId': promotionId,
      'title': title,
      'body': body,
    };
    payloadData.addAll(data);

    final String payload = jsonEncode(payloadData);

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'Notificaciones Importantes',
      channelDescription: 'Este canal se usa para notificaciones importantes.',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      color: Colors.blue,
      ledColor: Colors.blue,
      ledOnMs: 1000,
      ledOffMs: 500,
      showWhen: true,
      autoCancel: true,
      ticker: title,
      visibility: NotificationVisibility.public,
      styleInformation: BigTextStyleInformation(body, htmlFormatBigText: true),
    );

    final DarwinNotificationDetails iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    _notificationId = (_notificationId + 1) % 10000;
    
    flutterLocalNotificationsPlugin.show(
      _notificationId,
      title,
      body,
      NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: payload,
    );
    
    print('✅ Notificación en foreground DISPARADA: $title');
  }

  void _handleLocalNotificationTap(NotificationResponse response) {
    if (_isNotificationHandled) return;
    _isNotificationHandled = true;

    print('👆 Notificación local tocada: ${response.payload}');
    
    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        final Map<String, dynamic> payloadData = jsonDecode(response.payload!);
        _navigateToPromotion(
          payloadData['promotionId']?.toString() ?? 'default_id',
          payloadData['title']?.toString() ?? 'Sin título',
          payloadData['body']?.toString() ?? 'Sin contenido',
        );
      } catch (e) {
        print('❌ Error decodificando payload: $e');
        _navigateToPromotion(
          'default_id',
          'Nueva Promoción',
          'Toca para ver más detalles'
        );
      }
    } else {
      _navigateToPromotion(
        'default_id',
        'Nueva Promoción',
        'Toca para ver más detalles'
      );
    }

    _resetNotificationHandler();
  }

  void _handleMessageTap(RemoteMessage message) {
    if (_isNotificationHandled) return;
    _isNotificationHandled = true;

    print('👆 Mensaje FCM tocado: ${message.data}');
    
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
    Future.delayed(const Duration(seconds: 3), () {
      _isNotificationHandled = false;
    });
  }

  void _navigateToPromotion(String promotionId, String title, String body) {
    print('🧭 Navegando a promoción: $promotionId');
    
    Future.delayed(const Duration(milliseconds: 500), () {
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
        print('✅ Navegación exitosa a detalles de promoción');
      } else {
        print('⚠️ Navigator no disponible, reintentando...');
        Future.delayed(const Duration(milliseconds: 1000), () {
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