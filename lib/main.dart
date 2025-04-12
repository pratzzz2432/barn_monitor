import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:barn_air_monitor/firebase_options.dart';
import 'package:barn_air_monitor/screens/auth/login_screen.dart';
import 'package:barn_air_monitor/config/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BarnAir Monitor',
      theme: appTheme,
      home: const LoginScreen(),
    );
  }
}
