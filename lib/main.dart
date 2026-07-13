import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';

// NOTE UNTUK CLINE/DEEPSEEK:
// - Jangan ubah AppTheme/AppColors, itu fondasi visual yang sudah fix.
// - Firebase.initializeApp() akan disambungkan di sini setelah konfigurasi
//   Firebase (google-services.json) siap. Jangan tambah dulu kalau belum ada.
// - Screen di bawah ini SHELL/placeholder saja: Splash, ToS, Login, Home kosong.
//   Isi UI form-nya boleh dikerjakan di sini, logic auth JANGAN disentuh dulu.

void main() {
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

/// Splash screen: logo berkilau + "Dikembangkan oleh Tim Winatra" (blueprint 6.1).
/// SHELL — animasi glow & transisi ke ToS/Login boleh digarap Cline/DeepSeek.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'WINATRA AI',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: 2,
              ),
            ),
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
