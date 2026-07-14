import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class TosScreen extends StatefulWidget {
  const TosScreen({super.key});

  @override
  State<TosScreen> createState() => _TosScreenState();
}

class _TosScreenState extends State<TosScreen> {
  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'SELAMAT DATANG DI WINATRA AI\n\n'
                  'Dengan menggunakan aplikasi Winatra AI ("Aplikasi"), Anda menyetujui ketentuan berikut. '
                  'Jika tidak setuju, jangan gunakan Aplikasi.\n\n'
                  '1. LAYANAN\n'
                  'Aplikasi menyediakan asisten berbasis AI untuk membantu belajar dan aktivitas harian. '
                  'Fitur dapat berubah sewaktu-waktu tanpa pemberitahuan.\n\n'
                  '2. AKUN\n'
                  'Anda bertanggung jawab menjaga kerahasiaan akun. '
                  '1 akun hanya untuk 1 perangkat (device binding). '
                  'Untuk pindah perangkat, logout dulu dari perangkat lama.\n\n'
                  '3. PENGGUNAAN WAJAR\n'
                  'Aplikasi dilengkapi kuota harian. '
                  'Penyalahgunaan (spam, akses berlebihan, otomatisasi) dapat mengakibatkan pembatasan atau pemblokiran akun.\n\n'
                  '4. KEBIJAKAN PRIVASI\n'
                  'Kami mengumpulkan data minimal yang diperlukan untuk operasional: email, ID perangkat, '
                  'dan data penggunaan. Data tidak dibagikan ke pihak ketiga kecuali diwajibkan hukum.\n\n'
                  '5. BATASAN TANGGUNG JAWAB\n'
                  'Jawaban AI bersifat informatif, bukan nasihat profesional. '
                  'Pengembang tidak bertanggung jawab atas kerugian akibat penggunaan Aplikasi.\n\n'
                  '6. PERUBAHAN\n'
                  'Ketentuan ini dapat berubah. Pengguna akan diberitahu melalui Aplikasi. '
                  'Penggunaan lanjutan setelah perubahan berarti menyetujui ketentuan baru.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _isChecked,
              onChanged: (value) => setState(() => _isChecked = value!),
              title: const Text('Saya setuju'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isChecked
                  ? () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('tos_agreed', true);
                      if (!context.mounted) return;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  : null,
              child: const Text('Lanjut'),
            ),
          ],
        ),
      ),
    );
  }
}