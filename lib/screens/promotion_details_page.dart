import 'package:flutter/material.dart';

class PromotionDetailsPage extends StatefulWidget {
  const PromotionDetailsPage({super.key});

  @override
  State<PromotionDetailsPage> createState() => _PromotionDetailsPageState();
}

class _PromotionDetailsPageState extends State<PromotionDetailsPage> {
  late String promotionId;
  late String title;
  late String body;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArguments();
  }

  void _loadArguments() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dynamic arguments = ModalRoute.of(context)?.settings.arguments;
      
      setState(() {
        if (arguments is Map) {
          promotionId = arguments['promotionId']?.toString() ?? 'ID no disponible';
          title = arguments['title']?.toString() ?? 'Sin título';
          body = arguments['body']?.toString() ?? 'Sin contenido';
        } else {
          promotionId = 'ID no disponible';
          title = 'Sin título';
          body = 'Sin contenido';
        }
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle de la Promoción'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título de la promoción
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Cuerpo/descripción de la promoción
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        body,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Información adicional (ID)
                  Card(
                    color: Colors.grey[100],
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'ID de la promoción: $promotionId',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}