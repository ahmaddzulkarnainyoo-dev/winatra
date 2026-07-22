import 'dart:async';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_colors.dart';
import '../core/services/overlay_permission_service.dart';
import 'enable_keyboard_screen.dart';
import 'login_screen.dart';
import 'main_nav_screen.dart';
import 'overlay_permission_screen.dart';
import 'tos_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();

    // Pulse animasi — logo membesar/mengecil lembut
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    // Shimmer animasi — gradient bergerak diagonal
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _navigateAfterDelay();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
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
        destination = const MainNavScreen();
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
      body: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          // Gradient bergerak (shimmer effect)
          final alignment = Alignment(
            math.sin(_shimmerController.value * math.pi * 2),
            math.cos(_shimmerController.value * math.pi * 2),
          );

          // Glow tambahan dari neonCyan yang bergerak
          final glowAlignment = Alignment(
            -math.sin(_shimmerController.value * math.pi * 2 + 1),
            -math.cos(_shimmerController.value * math.pi * 2 + 1),
          );

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: alignment,
                end: glowAlignment,
                colors: const [
                  AppColors.electricBlue,
                  AppColors.electricBlueDark,
                  AppColors.electricBlueDeep,
                  AppColors.electricBlue,
                ],
                stops: const [0.0, 0.4, 0.7, 1.0],
              ),
            ),
            alignment: Alignment.center,
            child: child,
          );
        },
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            final glowOpacity = 0.15 + (_pulseAnimation.value - 1.0) * 2.5;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glow effect di belakang logo
                Container(
                  width: 220 * _pulseAnimation.value,
                  height: 220 * _pulseAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonCyan.withValues(alpha: glowOpacity),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                      BoxShadow(
                        color: AppColors.electricBlue.withValues(alpha: glowOpacity * 0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
                // Logo dengan pulse
                Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 200,
                    height: 200,
                  ),
                ),
                const SizedBox(height: 24),
                // Teks "Dikembangkan oleh Tim Winatra" dengan efek fade
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      AppColors.neonCyan.withValues(alpha: 0.6 + (_pulseAnimation.value - 1.0) * 3),
                      AppColors.textPrimary.withValues(alpha: 0.6 + (_pulseAnimation.value - 1.0) * 3),
                      AppColors.neonCyan.withValues(alpha: 0.6 + (_pulseAnimation.value - 1.0) * 3),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ).createShader(bounds),
                  child: const Text(
                    'Dikembangkan oleh Tim Winatra',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                // Loading indicator dengan neon
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.neonCyan.withValues(alpha: 0.5 + (_pulseAnimation.value - 1.0) * 2.5),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}