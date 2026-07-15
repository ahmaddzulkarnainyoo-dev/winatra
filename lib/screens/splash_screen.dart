import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_colors.dart';
import '../core/services/overlay_permission_service.dart';
import 'enable_keyboard_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'overlay_permission_screen.dart';
import 'tos_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();
    final keyboardShown = prefs.getBool('keyboard_onboarding_shown') ?? false;
    Widget destination;

    if (user == null) {
      final tosAgreed = prefs.getBool('tos_agreed') ?? false;
      destination = tosAgreed ? const LoginScreen() : const TosScreen();
    } else {
      final hasPermission = await OverlayPermissionService.hasPermission();
      if (!hasPermission) {
        destination = const OverlayPermissionScreen();
      } else if (!keyboardShown) {
        destination = const EnableKeyboardScreen();
      } else {
        destination = const HomeScreen();
      }
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', width: 200, height: 200),
            const SizedBox(height: 12),
            Text(
              'Dikembangkan oleh Tim Winatra',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}