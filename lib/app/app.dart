import 'package:flutter/material.dart';
import 'app_initializer.dart';
import 'routes/app_routes.dart';
import '../screens/home_page.dart';
import '../screens/promotion_details_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App de Promociones',
      navigatorKey: AppInitializer.navigatorKey,
      initialRoute: AppRoutes.home,
      routes: {
        AppRoutes.home: (context) => HomePage(),
        AppRoutes.promotionDetails: (context) => PromotionDetailsPage(),
      },
    );
  }
}