import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:winatraai/core/services/accessibility_permission_service.dart';
import 'package:winatraai/core/services/auth_service.dart';
import 'package:winatraai/core/services/streak_service.dart';
import 'package:winatraai/core/services/widget_preference_service.dart';
import 'package:winatraai/core/widgets/ai_popup.dart';
import 'package:winatraai/screens/account_screen.dart';
import 'package:winatraai/screens/login_screen.dart';
import 'package:winatraai/screens/mode_ujian_setup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? activeMode;
  int streak = 0;
  bool _floatingMode = true;

  @override
  void initState() {
    super.initState();
    _loadStreak();
    _showDailyBriefing();
    _loadFloatingMode();
  }

  Future<void> _loadFloatingMode() async {
    final value = await WidgetPreferenceService().isFloatingMode();
    if (!mounted) return;
    setState(() {
      _floatingMode = value;
    });
  }

  Future<void> _loadStreak() async {
    final bonus = await StreakService().recordActivity();
    final value = await StreakService().getCurrentStreak();
    if (!mounted) return;
    setState(() {
      streak = value;
    });
    if (bonus > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🔥 Streak $value hari! Bonus +$bonus kuota!'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });
    }
  }

  /// Daily Briefing — tampilkan ringkasan saat pertama buka app hari ini.
  Future<void> _showDailyBriefing() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = 'briefing_date_${today.year}_${today.month}_${today.day}';
    final alreadyShown = prefs.getBool(todayKey) ?? false;
    if (alreadyShown) return;

    await prefs.setBool(todayKey, true);
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.wb_sunny_outlined, color: Colors.amber),
              const SizedBox(width: 8),
              Text('Selamat pagi!', style: Theme.of(ctx).textTheme.titleLarge),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🔥 Streak: $streak hari'),
              const SizedBox(height: 8),
              const Text('📌 Pilih mode di bawah untuk mulai:'),
              const SizedBox(height: 4),
              const Text('• Mode Pelajar — bantu jawab soal'),
              const Text('• Mode Daily — bantu aktivitas harian'),
              const Text('• Mode Ujian — fokus persiapan ujian'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Mulai'),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardTheme = theme.cardTheme;

    Widget buildModeCard({
      required String mode,
      required String title,
      required String description,
      required IconData icon,
    }) {
      final isActive = activeMode == mode;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? theme.colorScheme.secondary : theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
              width: isActive ? 2.2 : 1.0,
            ),
          ),
          child: Card(
            margin: EdgeInsets.zero,
            elevation: cardTheme.elevation ?? 1,
            shape: cardTheme.shape ?? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                setState(() {
                  activeMode = mode;
                });
                  if (mode == 'pelajar' || mode == 'daily') {
                    final scaffold = ScaffoldMessenger.of(context);
                    const channel = MethodChannel('com.winatra.ai/floating_service');
                    final modeLabel = mode == 'pelajar' ? 'Pelajar' : 'Daily';
                    try {
                      if (mode == 'pelajar') {
                        await channel.invokeMethod('startFloatingNotes', {'mode': mode, 'floatingMode': _floatingMode});
                      } else {
                        await channel.invokeMethod('startFloating', {'mode': mode, 'prompt': ''});
                      }
                      if (!mounted) return;
                      scaffold.showSnackBar(
                        SnackBar(
                          content: Text('Mode $modeLabel aktif!'),
                        ),
                      );
                    } on PlatformException catch (e) {
                      if (e.code == 'NO_PERMISSION') {
                        debugPrint('startFloating: overlay permission not granted');
                        if (!mounted) return;
                        scaffold.showSnackBar(
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
                        scaffold.showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.message}'),
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint('startFloating error: $e');
                      if (!mounted) return;
                      scaffold.showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                        ),
                      );
                    }
                  }
                if (mode == 'ujian') {
                  if (!mounted) return;
                  final navigator = Navigator.of(context);
                  navigator.push(
                    MaterialPageRoute(
                      builder: (_) => const ModeUjianSetupScreen(),
                    ),
                  );
                }
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
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Winatra${streak > 0 ? '  🔥 $streak hari' : ''}'),
        actions: [
          IconButton(
            tooltip: 'Akun Saya',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AccountScreen()),
              );
            },
            icon: const Icon(Icons.person_outline),
          ),
          // Toggle Widget Mengambang
          Builder(
            builder: (ctx) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Mengambang', style: theme.textTheme.labelSmall),
                  Switch(
                    value: _floatingMode,
                    onChanged: (val) async {
                      await WidgetPreferenceService().setFloatingMode(val);
                      if (!mounted) return;
                      setState(() {
                        _floatingMode = val;
                      });
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              );
            },
          ),
          IconButton(
            tooltip: 'Accessibility Settings',
            onPressed: () async {
              await AccessibilityPermissionService.openAccessibilitySettings();
            },
            icon: const Icon(Icons.accessibility_outlined),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              await AuthService().signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout_outlined),
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pilih mode',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: [
                      buildModeCard(
                        mode: 'pelajar',
                        title: 'Mode Pelajar',
                        description: 'Fokus belajar dengan bantuan cepat.',
                        icon: Icons.school_outlined,
                      ),
                      buildModeCard(
                        mode: 'daily',
                        title: 'Mode Daily',
                        description: 'Bantu aktivitas harian sehari-hari.',
                        icon: Icons.calendar_today_outlined,
                      ),
                      buildModeCard(
                        mode: 'ujian',
                        title: 'Mode Ujian',
                        description: 'Siapkan diri untuk ujian dengan ringkas.',
                        icon: Icons.quiz_outlined,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // AI Popup floating di pojok kanan bawah
          const AiPopup(),
        ],
      ),
    );
  }
}
