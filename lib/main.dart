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
// Necesaria para navegar desde el servicio de notificaciones
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 2. Instancias de notificación (para ser accesibles globalmente)
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
late AndroidNotificationChannel channel;

// 3. Handler de mensajes en Background/Terminated
// ESTA FUNCIÓN DEBE ESTAR FUERA DE CUALQUIER CLASE (ser "top-level")
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Asegúrate de inicializar Firebase para que funcione en segundo plano
  await Firebase.initializeApp();
  
  print("Handling a background message: ${message.messageId}");
  // Aquí puedes ejecutar lógica de fondo si es necesario,
  // como guardar datos en SharedPreferences.
}
// ------------------------------------------


void main() async {
  // 1. Asegurar la inicialización de Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Inicializar Firebase Core
  await Firebase.initializeApp();

  // 3. Asignar el handler de mensajes en segundo plano
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
  // (Esto es manejado por el SDK de firebase_messaging)
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true, // Requerido
    badge: true,
    sound: true,
  );

  // 7. Correr la aplicación
  runApp(MyApp());
  
  // 8. Inicializar nuestro servicio de notificaciones
  // Lo hacemos después de runApp para que el navigatorKey esté listo
  NotificationService(navigatorKey: navigatorKey).init();
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App de Promociones',
      // Asignamos la clave de navegación global
      navigatorKey: navigatorKey,
      initialRoute: '/',
      // Definimos las rutas de la aplicación
      routes: {
        '/': (context) => HomePage(),
        '/promotion-details': (context) => PromotionDetailsPage(),
      },
    );
  }
}