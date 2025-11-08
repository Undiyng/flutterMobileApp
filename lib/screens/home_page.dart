import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/app_initializer.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

void _testLocalNotification() {
  // Probar notificación local directamente
  AppInitializer.flutterLocalNotificationsPlugin.show(
    999, // ID fijo para testing
    '🚨 TEST: Banner en Primer Plano',
    'Esta es una notificación de prueba para verificar los banners',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'high_importance_channel',
        'Notificaciones Importantes',
        channelDescription: 'Este canal se usa para notificaciones importantes.',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        color: Colors.blue,
        showWhen: true,
        autoCancel: true,
        visibility: NotificationVisibility.public,
        ticker: 'Test de notificación',
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('App de Promociones'),
      ),
  body: Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('¡Bienvenido! Esperando nuevas promociones...'),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _testLocalNotification,
          child: const Text('Probar Notificación Local'),
        ),
      ],
    ),
  ),
);
    
  }
}

