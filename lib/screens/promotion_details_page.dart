import 'package:flutter/material.dart';

class PromotionDetailsPage extends StatelessWidget {
  const PromotionDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Recibe el ID de la promoción pasado como argumento
    final String promotionId = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle de la Promoción'),
      ),
      body: Center(
        child: Text('Mostrando detalles para la promoción ID: $promotionId'),
        // Aquí puedes usar el ID para hacer una llamada a tu API
        // y obtener los detalles completos de la promoción.
      ),
    );
  }
}