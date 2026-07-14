import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const WinatraApp());
}

class WinatraApp extends StatelessWidget {
  const WinatraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Winatra AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const SplashScreen(),
    );
  }
}
