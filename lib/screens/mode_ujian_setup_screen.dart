import 'package:flutter/material.dart';
import '../core/services/exam_mode_service.dart';

/// Screen untuk mengatur Mode Ujian — user memilih rentang tanggal
/// selama periode ujian berlangsung.
///
/// Selama rentang aktif:
/// - Notifikasi non-esensial dibisukan otomatis.
/// - Hanya tombol Jawab (Mode Pelajar) yang tetap aktif & diprioritaskan.
///
/// Penyimpanan Firestore nanti disambungkan secara terpisah.
class ModeUjianSetupScreen extends StatefulWidget {
  const ModeUjianSetupScreen({super.key});

  @override
  State<ModeUjianSetupScreen> createState() => _ModeUjianSetupScreenState();
}

class _ModeUjianSetupScreenState extends State<ModeUjianSetupScreen> {
  DateTimeRange? _selectedRange;

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      helpText: 'Pilih rentang tanggal ujian',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      // Ikut theme dari AppTheme — electric blue + neon
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.secondary,
                  onPrimary: Theme.of(context).colorScheme.primary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedRange = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Atur Mode Ujian'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tombol untuk membuka date range picker
            ElevatedButton.icon(
              onPressed: _pickDateRange,
              icon: const Icon(Icons.date_range),
              label: Text(
                _selectedRange == null
                    ? 'Pilih Rentang Tanggal'
                    : 'Ubah Rentang Tanggal',
              ),
            ),

            const SizedBox(height: 24),

            // Card ringkasan — hanya tampil jika rentang sudah dipilih
            if (_selectedRange != null) ...[
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.secondary.withValues(alpha: 0.55),
                      blurRadius: 20,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.school,
                          size: 48,
                          color: colorScheme.secondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Mode Ujian aktif',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_formatDate(_selectedRange!.start)} — '
                          '${_formatDate(_selectedRange!.end)}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Tombol Simpan
              ElevatedButton(
                onPressed: () async {
                  await ExamModeService().saveExamRange(
                    _selectedRange!.start,
                    _selectedRange!.end,
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mode Ujian disimpan')),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.secondary,
                  foregroundColor: colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Simpan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}