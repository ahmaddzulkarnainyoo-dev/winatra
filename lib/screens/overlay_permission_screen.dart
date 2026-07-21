import 'package:flutter/material.dart';

import '../core/services/notification_permission_service.dart';
import '../core/services/overlay_permission_service.dart';
import 'main_nav_screen.dart';

class OverlayPermissionScreen extends StatefulWidget {
  const OverlayPermissionScreen({super.key});

  @override
  State<OverlayPermissionScreen> createState() => _OverlayPermissionScreenState();
}

class _OverlayPermissionScreenState extends State<OverlayPermissionScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestNotificationPermission();
  }

  Future<void> _requestNotificationPermission() async {
    await NotificationPermissionService.requestPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      final has = await OverlayPermissionService.hasPermission();
      if (has && context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.layers,
                size: 96,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Winatra butuh izin tampil di atas aplikasi lain biar bisa bantu kamu real-time',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await OverlayPermissionService.requestPermission();
                  },
                  child: const Text('Izinkan Sekarang'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const MainNavScreen()),
                  );
                },
                child: const Text('Nanti saja'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
