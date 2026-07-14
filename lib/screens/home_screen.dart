import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:winatraai/core/services/streak_service.dart';
import 'package:winatraai/screens/mode_ujian_setup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? activeMode;
  int streak = 0;

  @override
  void initState() {
    super.initState();
    StreakService().recordActivity().then((_) {
      StreakService().getCurrentStreak().then((value) {
        if (mounted) {
          setState(() {
            streak = value;
          });
        }
      });
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
                if (mode == 'pelajar') {
                  const channel = MethodChannel('com.winatra.ai/floating_service');
                  try {
                    await channel.invokeMethod('startFloating', {'mode': 'pelajar'});
                  } catch (e) {
                    debugPrint('startFloating error: $e');
                  }
                }
                if (mode == 'ujian') {
                  Navigator.push(
                    context,
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
            tooltip: 'Logout',
            onPressed: () {
              debugPrint('Logout ditekan');
            },
            icon: const Icon(Icons.logout_outlined),
          ),
        ],
      ),
      body: Padding(
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
    );
  }
}
