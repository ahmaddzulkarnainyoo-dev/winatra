import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

/// AI Popup Winatra — widget kecil floating di pojok kanan bawah.
/// Tidak butuh sprite, cukup emoji + teks yang berubah berdasarkan konteks.
class AiPopup extends StatefulWidget {
  const AiPopup({super.key});

  @override
  State<AiPopup> createState() => _AiPopupState();
}

class _AiPopupState extends State<AiPopup> with TickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  late AnimationController _lookController;
  late Animation<double> _lookAnimation;

  // Draggable position
  Offset _position = const Offset(0, 0);
  bool _positionLoaded = false;

  // Ekspresi & mood
  final _moods = const <Mood>[
    Mood('🤖', 'Halo! Ada yang bisa dibantu?', MoodType.normal, 'assets/images/robot/robot_idle.png'),
    Mood('🥺', 'Lama tak jumpa... Kangen!', MoodType.rindu, 'assets/images/robot/robot_idle.png'),
    Mood('😰', 'Kuota tinggal sedikit!', MoodType.waspada, 'assets/images/robot/robot_alert.png'),
    Mood('😊', 'Streak bagus! Pertahankan!', MoodType.senang, 'assets/images/robot/robot_happy.png'),
    Mood('🤔', 'Butuh bantuan belajar?', MoodType.normal, 'assets/images/robot/robot_thinking.png'),
  ];
  Mood _currentMood = const Mood('🤖', 'Halo! Ada yang bisa dibantu?', MoodType.normal, 'assets/images/robot/robot_idle.png');
  final _chatController = TextEditingController();
  final _messages = <String>[];
  bool _sending = false;

  // Ganti URL ini dengan URL Worker setelah deploy.
  // Format: https://winatraai.nama-akun.workers.dev/ask
  static const String _workerUrl = 'https://winatraai.YOUR_USERNAME.workers.dev/ask';

  final _auth = AuthService();

  static const String _prefKeyPosX = 'ai_popup_pos_x';
  static const String _prefKeyPosY = 'ai_popup_pos_y';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutCubic,
    );
    _lookController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _lookAnimation = Tween<double>(begin: -0.08, end: 0.08).animate(
      CurvedAnimation(parent: _lookController, curve: Curves.easeInOut),
    );

    _loadPosition();

    // Ganti mood setiap 15 detik
    Future.delayed(const Duration(seconds: 15), _cycleMood);
  }

  Future<void> _loadPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final x = prefs.getDouble(_prefKeyPosX);
    final y = prefs.getDouble(_prefKeyPosY);
    if (x != null && y != null) {
      setState(() {
        _position = Offset(x, y);
        _positionLoaded = true;
      });
    } else {
      setState(() {
        _positionLoaded = true;
      });
    }
  }

  Future<void> _savePosition(Offset pos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefKeyPosX, pos.dx);
    await prefs.setDouble(_prefKeyPosY, pos.dy);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _expandController.dispose();
    _lookController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  void _cycleMood() {
    if (!mounted) return;
    setState(() {
      _currentMood = _moods[Random().nextInt(_moods.length)];
    });
    Future.delayed(const Duration(seconds: 15), _cycleMood);
  }

  void _toggleExpanded() {
    if (_isExpanded) {
      _expandController.reverse();
    } else {
      _expandController.forward();
    }
    setState(() => _isExpanded = !_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    if (!_positionLoaded) return const SizedBox.shrink();

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Chat bubble
          if (_isExpanded)
            SizeTransition(
              sizeFactor: _expandAnimation,
              alignment: Alignment.topRight,
              child: _buildChatBubble(context),
            ),
          const SizedBox(height: 8),
          // Avatar robot — draggable
          GestureDetector(
            onTap: _toggleExpanded,
            onPanUpdate: (details) {
              setState(() {
                _position += details.delta;
              });
            },
            onPanEnd: (_) {
              _savePosition(_position);
            },
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isExpanded ? 1.0 : _pulseAnimation.value,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    width: _isExpanded ? 72 : 56,
                    height: _isExpanded ? 72 : 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0A2FFF), Color(0xFF00F0FF)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00F0FF).withValues(alpha: _isExpanded ? 0.6 : 0.4),
                          blurRadius: 12,
                          spreadRadius: _isExpanded ? 3.0 : 1.0,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Stack(
                        children: [
                          // Robot image — animated switch
                          Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              switchInCurve: Curves.easeOutBack,
                              switchOutCurve: Curves.easeIn,
                              transitionBuilder: (Widget child, Animation<double> animation) {
                                return ScaleTransition(
                                  scale: animation,
                                  child: FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                );
                              },
                              child: Image.asset(
                                _currentMood.assetPath,
                                key: ValueKey(_currentMood.assetPath),
                                width: _isExpanded ? 52 : 40,
                                height: _isExpanded ? 52 : 40,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => Text(
                                  _currentMood.emoji,
                                  style: const TextStyle(fontSize: 28),
                                ),
                              ),
                            ),
                          ),
                          // Mata robot "melirik" — sinar mata bergerak pelan
                          AnimatedBuilder(
                            animation: _lookAnimation,
                            builder: (context, child) {
                              return Positioned(
                                top: 16,
                                left: 20 + (_lookAnimation.value * 8),
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00F0FF).withValues(alpha: 0.6),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(BuildContext context) {
    return Container(
      width: 260,
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? const Color(0xFF171E4D),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F0FF).withValues(alpha: 0.2),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header mood
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF2D2D44), width: 1)),
            ),
            child: Row(
                children: [
                Image.asset(
                  _currentMood.assetPath,
                  width: 24,
                  height: 24,
                  errorBuilder: (context, error, stackTrace) => Text(
                    _currentMood.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentMood.message,
                    style: const TextStyle(fontSize: 13, color: Color(0xFFA9B2E3)),
                  ),
                ),
              ],
            ),
          ),
          // Messages
          if (_messages.isNotEmpty)
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _messages.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Text(_messages[i], style: const TextStyle(fontSize: 13, color: Colors.white)),
                ),
              ),
            ),
          // Input
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: TextField(
                      controller: _chatController,
                      style: const TextStyle(fontSize: 13, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Ketik pesan...',
                        hintStyle: const TextStyle(color: Color(0xFFA9B2E3)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF2D2D44)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                  IconButton(
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00F0FF)),
                          )
                        : const Icon(Icons.send, size: 18, color: Color(0xFF00F0FF)),
                    onPressed: _sending
                        ? null
                        : () async {
                            if (_chatController.text.isNotEmpty) {
                              final msg = _chatController.text;
                              setState(() {
                                _messages.add(msg);
                                _chatController.clear();
                                _sending = true;
                              });
                              final reply = await _askWorker(msg);
                              if (!mounted) return;
                              setState(() {
                                _messages.add('🤖 $reply');
                                _sending = false;
                              });
                            }
                          },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Kirim pertanyaan ke Worker AI dan dapatkan jawaban.
  Future<String> _askWorker(String message) async {
    try {
      final uid = _auth.currentUser?.uid ?? 'anonymous';
      final response = await http.post(
        Uri.parse(_workerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'uid': uid,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reply'] as String? ?? 'Tidak ada jawaban.';
      }
      return 'Gagal terhubung ke AI (${response.statusCode}). Coba lagi.';
    } catch (e) {
      return 'Gagal terhubung ke server. $e';
    }
  }
}

enum MoodType { normal, rindu, waspada, senang }

class Mood {
  final String emoji;
  final String message;
  final MoodType type;
  final String assetPath;
  const Mood(this.emoji, this.message, this.type, this.assetPath);
}