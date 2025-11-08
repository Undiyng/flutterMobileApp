import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('App de Promociones'),
      ),
      body: Center(
        child: Text('¡Bienvenido! Esperando nuevas promociones...'),
      ),
    );
  }
}