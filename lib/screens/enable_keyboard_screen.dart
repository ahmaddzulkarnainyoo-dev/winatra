import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class EnableKeyboardScreen extends StatefulWidget {
  const EnableKeyboardScreen({super.key});

  @override
  State<EnableKeyboardScreen> createState() => _EnableKeyboardScreenState();
}

class _EnableKeyboardScreenState extends State<EnableKeyboardScreen> {
  static const _channel = MethodChannel('com.winatra.ai/keyboard');

  Future<void> _openKeyboardSettings() async {
    try {
      await _channel.invokeMethod('openKeyboardSettings');
    } catch (e) {
      debugPrint('openKeyboardSettings error: $e');
    }
    // Tetap tandai sudah dilihat, agar tidak muncul lagi
    await _markShown();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _markShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('keyboard_onboarding_shown', true);
  }

  Future<void> _skipAndGoHome() async {
    await _markShown();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Aktifkan Keyboard Winatra')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            // Icon keyboard
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              ),
              child: const Icon(Icons.keyboard_alt_outlined, size: 56, color: Color(0xFF00F5FF)),
            ),
            const SizedBox(height: 24),
            Text(
              'Aktifkan Keyboard Winatra',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Aktifkan keyboard Winatra di pengaturan untuk mengetik '
              'dengan bantuan AI di aplikasi mana pun.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Langkah 1
            _buildStep(1, 'Buka Settings Android', 'System → Languages & input'),
            const SizedBox(height: 12),
            _buildStep(2, 'Pilih Virtual keyboard', 'Pilih "Winatra AI Keyboard"'),
            const SizedBox(height: 12),
            _buildStep(3, 'Aktifkan & pilih', 'Toggle on, lalu pilih sebagai keyboard default'),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _openKeyboardSettings,
              icon: const Icon(Icons.settings),
              label: const Text('Buka Settings Keyboard'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _skipAndGoHome,
              child: const Text('Nanti saja'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int number, String title, String subtitle) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.primary,
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              Text(subtitle, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}