import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeyboardSetupScreen extends StatefulWidget {
  const KeyboardSetupScreen({super.key});

  @override
  State<KeyboardSetupScreen> createState() => _KeyboardSetupScreenState();
}

class _KeyboardSetupScreenState extends State<KeyboardSetupScreen> with WidgetsBindingObserver {
  static const MethodChannel _channel = MethodChannel('com.winatra.ai/keyboard');

  bool _isLoading = true;
  bool _isDefaultKeyboard = false;
  final TextEditingController _testController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkKeyboardStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _testController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkKeyboardStatus();
    }
  }

  Future<void> _checkKeyboardStatus() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final isDefault = await _channel.invokeMethod<bool>('isDefaultKeyboard') ?? false;
      if (!mounted) return;
      setState(() {
        _isDefaultKeyboard = isDefault;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('check keyboard status error: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openKeyboardSettings() async {
    try {
      await _channel.invokeMethod<void>('openKeyboardSettings');
    } catch (e) {
      debugPrint('open keyboard settings error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak bisa membuka pengaturan keyboard: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keyboard Winatra'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status Keyboard',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      if (_isLoading)
                        const Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Memeriksa status keyboard...'),
                          ],
                        )
                      else if (_isDefaultKeyboard)
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green.shade600),
                            const SizedBox(width: 8),
                            const Expanded(child: Text('Winatra Keyboard sudah menjadi keyboard utama.')),
                          ],
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                                const SizedBox(width: 8),
                                const Expanded(child: Text('Winatra Keyboard belum dipilih sebagai keyboard utama.')),
                              ],
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: _openKeyboardSettings,
                              icon: const Icon(Icons.keyboard_alt_outlined),
                              label: const Text('Aktifkan sebagai Keyboard Utama'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _testController,
                decoration: const InputDecoration(
                  labelText: 'Coba ketik di sini untuk tes keyboard',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.text_fields_outlined),
                ),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
