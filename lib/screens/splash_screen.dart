import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_colors.dart';
import '../core/services/overlay_permission_service.dart';
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
    Widget destination;

    if (user == null) {
      final prefs = await SharedPreferences.getInstance();
      final tosAgreed = prefs.getBool('tos_agreed') ?? false;
      destination = tosAgreed ? const LoginScreen() : const TosScreen();
    } else {
      final hasPermission = await OverlayPermissionService.hasPermission();
      destination = hasPermission ? const HomeScreen() : const OverlayPermissionScreen();
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
            const Text(
              'Dikembangkan oleh Tim Winatra',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}