import 'package:flutter/material.dart';
import 'app/app.dart';
import 'app/app_initializer.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppInitializer.initialize();
  runApp(MyApp());
}