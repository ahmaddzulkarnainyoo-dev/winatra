import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:winatraai/core/services/widget_preference_service.dart';

class NotifikasiSetupScreen extends StatefulWidget {
  const NotifikasiSetupScreen({super.key});

  @override
  State<NotifikasiSetupScreen> createState() => _NotifikasiSetupScreenState();
}

class _NotifikasiSetupScreenState extends State<NotifikasiSetupScreen> {
  String? _selectedMode; // 'pelajar' or 'daily'
  String? _selectedMapel;
  bool _floatingMode = true;
  bool _isActive = false;

  final List<String> _mapelList = [
    'Matematika',
    'Fisika',
    'Kimia',
    'Biologi',
    'Bahasa Indonesia',
    'Bahasa Inggris',
    'Sejarah',
    'Geografi',
    'Ekonomi',
    'Sosiologi',
    'PPKn',
    'Agama',
    'Seni Budaya',
    'PJOK',
    'Informatika',
    'Bahasa Arab',
    'Bahasa Jepang',
    'Bahasa Mandarin',
    'Bahasa Jerman',
    'Bahasa Prancis',
    'Antropologi',
    'Sastra Indonesia',
    'Sastra Inggris',
    'Tata Boga',
    'Tata Busana',
  ];

  @override
  void initState() {
    super.initState();
    _loadFloatingMode();
  }

  Future<void> _loadFloatingMode() async {
    final value = await WidgetPreferenceService().isFloatingMode();
    if (!mounted) return;
    setState(() {
      _floatingMode = value;
    });
  }

  Future<void> _startService() async {
    const channel = MethodChannel('com.winatra.ai/floating_service');
    final modeLabel = _selectedMode == 'pelajar' ? 'Pelajar' : 'Daily';

    try {
      if (_selectedMode == 'pelajar') {
        await channel.invokeMethod('startFloatingNotes', {
          'mode': _selectedMode,
          'floatingMode': _floatingMode,
        });
      } else {
        await channel.invokeMethod('startFloating', {
          'mode': _selectedMode,
          'prompt': '',
        });
      }
      if (!mounted) return;
      setState(() {
        _isActive = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mode $modeLabel aktif!')),
      );
    } on PlatformException catch (e) {
      if (e.code == 'NO_PERMISSION') {
        debugPrint('startFloating: overlay permission not granted');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Aktifkan izin overlay dulu di menu Home'),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Buka Pengaturan',
              onPressed: () async {
                const overlayChannel = MethodChannel('com.winatra.ai/overlay');
                await overlayChannel.invokeMethod('requestOverlayPermission');
              },
            ),
          ),
        );
      } else {
        debugPrint('startFloating PlatformException: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      }
    } catch (e) {
      debugPrint('startFloating error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _stopService() async {
    const channel = MethodChannel('com.winatra.ai/floating_service');
    try {
      await channel.invokeMethod('stopFloating');
      if (!mounted) return;
      setState(() {
        _isActive = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mode dihentikan')),
      );
    } catch (e) {
      debugPrint('stopFloating error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mode Notifikasi'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Dua pilihan besar: Mode Pelajar & Mode Daily
          Text(
            'Pilih Mode',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildModeChoice(
            mode: 'pelajar',
            title: 'Mode Pelajar',
            description: 'Fokus belajar dengan bantuan cepat.',
            icon: Icons.school_outlined,
          ),
          const SizedBox(height: 8),
          _buildModeChoice(
            mode: 'daily',
            title: 'Mode Daily',
            description: 'Bantu aktivitas harian sehari-hari.',
            icon: Icons.calendar_today_outlined,
          ),

          // Sub-config jika sudah pilih mode
          if (_selectedMode != null) ...[
            const SizedBox(height: 24),
            if (_selectedMode == 'pelajar') ...[
              // Spinner mapel
              Text(
                'Mata Pelajaran',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedMapel,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  hintText: 'Pilih mata pelajaran',
                ),
                items: _mapelList.map((mapel) {
                  return DropdownMenuItem(
                    value: mapel,
                    child: Text(mapel),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedMapel = val;
                  });
                },
              ),
              const SizedBox(height: 20),
            ],
            // Toggle Widget Mengambang
            Card(
              child: SwitchListTile(
                title: const Text('Widget Mengambang'),
                subtitle: const Text('Tampilkan widget di atas layar'),
                value: _floatingMode,
                onChanged: (val) async {
                  await WidgetPreferenceService().setFloatingMode(val);
                  if (!mounted) return;
                  setState(() {
                    _floatingMode = val;
                  });
                },
              ),
            ),
            const SizedBox(height: 24),
            // Tombol Mulai / Berhenti
            if (!_isActive)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startService,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.secondary,
                    foregroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Mulai',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _stopService,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Berhenti',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildModeChoice({
    required String mode,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _selectedMode == mode;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.secondary
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
          width: isSelected ? 2.2 : 1.0,
        ),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: isSelected ? 2 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              _selectedMode = mode;
              if (mode == 'daily') {
                _selectedMapel = null;
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
                  child: Icon(icon, size: 28, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: theme.colorScheme.secondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}