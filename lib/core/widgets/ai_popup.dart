import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
          if (_isExpanded) _buildChatBubble(context),
          const SizedBox(height: 8),
          // Avatar robot — draggable
          GestureDetector(
            onTap: () {
              setState(() => _isExpanded = !_isExpanded);
            },
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
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0A2FFF), Color(0xFF00F0FF)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00F0FF).withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Image.asset(
                        _currentMood.assetPath,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Text(
                          _currentMood.emoji,
                          style: TextStyle(fontSize: 28),
                        ),
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
                    style: TextStyle(fontSize: 20),
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
                  icon: const Icon(Icons.send, size: 18, color: Color(0xFF00F0FF)),
                  onPressed: () {
                    if (_chatController.text.isNotEmpty) {
                      setState(() {
                        _messages.add(_chatController.text);
                        _messages.add('🤖 ' + _getAutoReply(_chatController.text));
                        _chatController.clear();
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

  String _getAutoReply(String msg) {
    if (msg.contains('halo') || msg.contains('hai')) return 'Halo juga! Ada yang bisa dibantu?';
    if (msg.contains('belajar') || msg.contains('soal')) return 'Copy soalnya, tekan Jawab di floating service ya!';
    if (msg.contains('makasih') || msg.contains('terima kasih')) return 'Sama-sama! 😊';
    return 'Baik, saya catat. Ada lagi?';
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