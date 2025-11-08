import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Importa tus pantallas
import 'screens/home_page.dart';
import 'screens/promotion_details_page.dart';
import 'services/notification_service.dart'; // Importamos el servicio

// ---------- CONFIGURACIÓN GLOBAL ----------

// 1. Clave Global para Navegación
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 2. Instancias de notificación (para ser accesibles globalmente)
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
late AndroidNotificationChannel channel;

// 3. Handler de mensajes en Background/Terminated - MODIFICADO
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  
  print("Handling a background message: ${message.messageId}");
  
  // INICIO: NUEVO CÓDIGO PARA MOSTRAR NOTIFICACIÓN EN BACKGROUND
  // Configurar el canal de notificaciones para background
  const AndroidNotificationChannel backgroundChannel = AndroidNotificationChannel(
    'promotions_channel_background', // ID diferente para background
    'Promociones Importantes',
    description: 'Canal para notificaciones de promociones en background.',
    importance: Importance.max,
  );

  // Inicializar plugin local para background
  FlutterLocalNotificationsPlugin backgroundPlugin = FlutterLocalNotificationsPlugin();
  
  // Crear el canal
  await backgroundPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(backgroundChannel);

  // Inicializar el plugin
  const InitializationSettings initializationSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(),
  );
  
  await backgroundPlugin.initialize(initializationSettings);

  // Mostrar la notificación
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
  // FIN: NUEVO CÓDIGO PARA MOSTRAR NOTIFICACIÓN EN BACKGROUND
}
// ------------------------------------------

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 4. Configurar el Canal de Android para notificaciones locales (Foreground)
  channel = const AndroidNotificationChannel(
    'promotions_channel', // ID único
    'Promociones Importantes', // Título visible
    description: 'Canal para notificaciones de promociones.',
    importance: Importance.max,
  );

  // 5. Inicializar el Plugin de Notificaciones Locales
  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Crear el canal en el dispositivo
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // 6. Configurar permisos de iOS para foreground
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(MyApp());
  
  // 8. Inicializar nuestro servicio de notificaciones
  NotificationService(navigatorKey: navigatorKey).init();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App de Promociones',
      navigatorKey: navigatorKey,
      initialRoute: '/',
      routes: {
        '/': (context) => HomePage(),
        '/promotion-details': (context) => PromotionDetailsPage(),
      },
    );
  }
}