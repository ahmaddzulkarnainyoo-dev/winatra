import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/services/auth_service.dart';
import '../core/services/otak_service.dart';
import '../core/models/otak_model.dart';

/// Halaman Chatbot Winatra — tab ke-2 di bottom nav.
/// UI chat bubble sederhana: kiri = AI, kanan = user.
/// History disimpan di state saja (List), tidak persist.
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _messages = <_ChatMessage>[];
  final _chatController = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;
  final _auth = AuthService();
  final _otakService = OtakService();

  List<Otak> _userOtaks = [];
  Otak? _selectedOtak;
  bool _loadingOtaks = false;

  static const String _workerUrl = 'https://winatraai.himlabnews.workers.dev/ask';

  @override
  void initState() {
    super.initState();
    // Sambutan awal
    _messages.add(_ChatMessage(
      text: 'Halo! Aku Winatra AI. Ada yang bisa aku bantu?',
      isUser: false,
    ));
    _loadUserOtaks();
  }

  Future<void> _loadUserOtaks() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    setState(() => _loadingOtaks = true);
    try {
      final otaks = await _otakService.fetchUserOtaks(uid);
      if (!mounted) return;
      setState(() {
        _userOtaks = otaks;
        _loadingOtaks = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingOtaks = false);
    }
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: text.trim(), isUser: true));
      _sending = true;
    });
    _chatController.clear();
    _scrollToBottom();

    try {
      final uid = _auth.currentUser?.uid ?? 'anonymous';
      // Siapkan payload dengan contextFiles jika ada Otak yang dipilih
      final Map<String, dynamic> payload = {
        'message': text,
        'uid': uid,
      };
      if (_selectedOtak != null) {
        payload['contextFiles'] = [_selectedOtak!.fileUrl];
      }

      final response = await http.post(
        Uri.parse(_workerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      String reply;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        reply = data['reply'] as String? ?? 'Tidak ada jawaban.';
        // Kurangi dailyQuota setelah jawaban berhasil
        if (uid != 'anonymous') {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .update({'dailyQuota': FieldValue.increment(-1)});
        }
      } else {
        reply = 'Gagal terhubung ke AI (${response.statusCode}). Coba lagi.';
      }

      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(text: reply, isUser: false));
        _sending = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(
          text: 'Gagal terhubung ke server. Periksa koneksi internet.',
          isUser: false,
        ));
        _sending = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D1117) : const Color(0xFFF5F5F5);
    final aiBubbleColor = isDark ? const Color(0xFF1E2A45) : const Color(0xFFE8F0FE);
    final userBubbleColor = isDark ? const Color(0xFF0A2FFF) : const Color(0xFF4A7CFF);
    final aiTextColor = isDark ? Colors.white : Colors.black87;
    final userTextColor = Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF0A2FFF), Color(0xFF00F0FF)],
                ),
              ),
              alignment: Alignment.center,
              child: const Text('🤖', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 10),
            const Text('Chatbot Winatra'),
          ],
        ),
        actions: [
          if (_loadingOtaks)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_userOtaks.isNotEmpty)
            PopupMenuButton<Otak>(
              tooltip: 'Pilih Otak',
              icon: const Icon(Icons.psychology_outlined),
              onSelected: (otak) {
                setState(() => _selectedOtak = otak);
              },
              itemBuilder: (_) => [
                const PopupMenuItem<Otak>(
                  value: null,
                  child: Text('Tanpa Otak'),
                ),
                ..._userOtaks.map((otak) => PopupMenuItem<Otak>(
                      value: otak,
                      child: Text(
                        otak.fileName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
              ],
            ),
        ],
      ),
      body: Container(
        color: bgColor,
        child: Column(
          children: [
            // Chat messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                itemCount: _messages.length,
                itemBuilder: (_, index) {
                  final msg = _messages[index];
                  final isUser = msg.isUser;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!isUser)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF0A2FFF), Color(0xFF00F0FF)],
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Text('🤖', style: TextStyle(fontSize: 14)),
                            ),
                          ),
                        Flexible(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 280),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isUser ? userBubbleColor : aiBubbleColor,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(18),
                                topRight: const Radius.circular(18),
                                bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
                                bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
                              ),
                            ),
                            child: Text(
                              msg.text,
                              style: TextStyle(
                                fontSize: 14,
                                color: isUser ? userTextColor : aiTextColor,
                              ),
                            ),
                          ),
                        ),
                        if (isUser)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: theme.colorScheme.primary,
                              child: Icon(Icons.person, size: 16, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Typing indicator
            if (_sending)
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: aiBubbleColor,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _dot(context),
                        const SizedBox(width: 4),
                        _dot(context),
                        const SizedBox(width: 4),
                        _dot(context),
                      ],
                    ),
                  ),
                ),
              ),
            // Indikator Otak aktif
            if (_selectedOtak != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                child: Row(
                  children: [
                    Icon(Icons.psychology, size: 14, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Menggunakan Otak: ${_selectedOtak!.fileName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _selectedOtak = null),
                      child: Icon(Icons.close, size: 16, color: theme.colorScheme.primary),
                    ),
                  ],
                ),
              ),
            // Input bar
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: TextField(
                          controller: _chatController,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Ketik pesan...',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                          ),
                          onSubmitted: _sending ? null : (val) => _sendMessage(val),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 44,
                      width: 44,
                      child: IconButton(
                        onPressed: _sending ? null : () => _sendMessage(_chatController.text),
                        icon: _sending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  const _ChatMessage({required this.text, required this.isUser});
}