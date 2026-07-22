import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:winatraai/core/services/accessibility_permission_service.dart';
import 'package:winatraai/core/services/exam_mode_service.dart';
import 'package:winatraai/core/services/streak_service.dart';
import 'package:winatraai/core/services/widget_preference_service.dart';
import 'package:winatraai/core/widgets/ai_popup.dart';
import 'package:winatraai/core/widgets/streak_dialog.dart';
import 'package:winatraai/screens/keyboard_setup_screen.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? activeMode;
  int streak = 0;
  bool _floatingMode = true;
  bool _examModeActive = false;
  DateTime? _examStart;
  DateTime? _examEnd;

  static const _modeChannel = MethodChannel('com.winatra/mode');

  @override
  void initState() {
    super.initState();
    _loadStreak();
    _showDailyBriefing();
    _loadFloatingMode();
    _loadExamMode();
    _loadActiveMode();
  }

  Future<void> _loadActiveMode() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('active_mode');
    if (!mounted) return;
    setState(() {
      activeMode = mode;
    });
  }

  Future<void> _setActiveMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_mode', mode);
    if (!mounted) return;
    setState(() {
      activeMode = mode;
    });
    // Kirim ke native via MethodChannel
    try {
      await _modeChannel.invokeMethod('setMode', {'mode': mode});
    } catch (e) {
      debugPrint('Gagal kirim mode ke native: $e');
    }
  }

  Future<void> _loadExamMode() async {
    final service = ExamModeService();
    final active = await service.isInExamMode();
    final exam = await service.getActiveExam();
    if (!mounted) return;
    setState(() {
      _examModeActive = active;
      if (exam != null) {
        _examStart = DateTime.fromMillisecondsSinceEpoch(exam['startDate'] as int);
        _examEnd = DateTime.fromMillisecondsSinceEpoch(exam['endDate'] as int);
      } else {
        _examStart = null;
        _examEnd = null;
      }
    });
  }

  Future<void> _pickExamRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 7)),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _examStart != null && _examEnd != null
          ? DateTimeRange(start: _examStart!, end: _examEnd!)
          : DateTimeRange(
              start: now,
              end: now.add(const Duration(days: 30)),
            ),
      helpText: 'Pilih rentang ujian',
      cancelText: 'Batal',
      confirmText: 'Simpan',
      saveText: 'Simpan',
      fieldStartHintText: 'Mulai',
      fieldEndHintText: 'Selesai',
    );

    if (picked == null) return;

    await ExamModeService().saveExamRange(picked.start, picked.end);
    if (!mounted) return;
    setState(() {
      _examStart = picked.start;
      _examEnd = picked.end;
      _examModeActive = true;
    });
  }

  Future<void> _cancelExamMode() async {
    await ExamModeService().cancelExamMode();
    if (!mounted) return;
    setState(() {
      _examModeActive = false;
      _examStart = null;
      _examEnd = null;
    });
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
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (_) => StreakDialog(streakValue: value, bonus: bonus),
        );
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showLockedFeatureSnackbar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur ini sedang dikembangkan, tunggu update berikutnya'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardTheme = theme.cardTheme;
    const electricBlue = Color(0xFF00D4FF);

    Widget buildModeSelector({
      required String mode,
      required String title,
      required String description,
      required IconData icon,
      bool isLocked = false,
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
            boxShadow: isActive
              ? [
                  BoxShadow(
                    color: electricBlue.withValues(alpha: 0.3),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : null,
          ),
          child: Card(
            margin: EdgeInsets.zero,
            elevation: cardTheme.elevation ?? 1,
            shape: cardTheme.shape ?? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: isLocked
                  ? _showLockedFeatureSnackbar
                  : () => _setActiveMode(mode),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: isLocked
                          ? Colors.grey.withValues(alpha: 0.2)
                          : isActive
                              ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.6)
                              : theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
                      child: isLocked
                          ? const Icon(Icons.lock_outline, size: 22, color: Colors.grey)
                          : Icon(icon, size: 28, color: isActive ? theme.colorScheme.secondary : theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isLocked
                                      ? Colors.grey
                                      : isActive ? electricBlue : null,
                                ),
                              ),
                              if (isLocked) ...[
                                const SizedBox(width: 8),
                                Icon(Icons.lock_outline, size: 14, color: Colors.grey),
                              ],
                              if (!isLocked && isActive) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: electricBlue.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'AKTIF',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: electricBlue,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isLocked ? 'Fitur dalam pengembangan' : description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isLocked ? Colors.grey : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (!isLocked && isActive)
                      Icon(Icons.check_circle, color: electricBlue, size: 20),
                    if (isLocked)
                      const Icon(Icons.lock_outline, color: Colors.grey, size: 20),
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
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.keyboard_alt_outlined),
                          title: const Text('Keyboard Winatra'),
                          subtitle: const Text('Atur dan uji keyboard di sini'),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const KeyboardSetupScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 3 Mode Selector
                      buildModeSelector(
                        mode: 'pelajar',
                        title: 'Pelajar',
                        description: 'Bantu jawab soal dari clipboard',
                        icon: Icons.menu_book_outlined,
                      ),
                      buildModeSelector(
                        mode: 'daily',
                        title: 'Daily',
                        description: 'Bantu aktivitas harian',
                        icon: Icons.wb_sunny_outlined,
                      ),
                      buildModeSelector(
                        mode: 'ujian',
                        title: 'Ujian',
                        description: 'Fokus persiapan ujian',
                        icon: Icons.track_changes_outlined,
                        isLocked: true,
                      ),
                      const SizedBox(height: 12),
                      // Card Mode Ujian khusus — DIKUNCI
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
                            width: 1.0,
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
                            onTap: _showLockedFeatureSnackbar,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: Colors.grey.withValues(alpha: 0.2),
                                        child: const Icon(
                                          Icons.lock_outline,
                                          size: 22,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  'Mode Ujian',
                                                  style: theme.textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                const Icon(Icons.lock_outline, size: 14, color: Colors.grey),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Fitur dalam pengembangan',
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                color: Colors.grey,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.lock_outline, color: Colors.grey, size: 20),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      buildModeSelector(
                        mode: 'notifikasi',
                        title: 'Mode Notifikasi',
                        description: 'Pelajar & Daily — notifikasi pintar.',
                        icon: Icons.notifications_outlined,
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