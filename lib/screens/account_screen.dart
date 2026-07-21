import 'package:flutter/material.dart';
import 'package:winatraai/core/models/user_tier.dart';
import 'package:winatraai/core/services/auth_service.dart';
import 'package:winatraai/screens/login_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _auth = AuthService();
  WinatraUser? _user;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final user = await _auth.fetchCurrentUserDoc();
      if (!mounted) return;
      setState(() {
        _user = user;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal memuat data akun. $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = _auth.currentUser?.email ?? '—';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Akun Saya'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _loadUser,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Kartu Email
                    Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.email_outlined, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Email', style: theme.textTheme.labelMedium),
                            Text(email, style: theme.textTheme.bodyLarge),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Kartu Tier & Kuota
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.workspace_premium_outlined, color: theme.colorScheme.primary),
                            const SizedBox(width: 12),
                            Text('Tier', style: theme.textTheme.labelMedium),
                            const Spacer(),
                            Chip(
                              label: Text(
                                _user?.tier.name.toUpperCase() ?? '—',
                                style: TextStyle(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              backgroundColor: _chipColor(_user?.tier, theme),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _infoRow(theme, 'Sisa Kuota Harian', '${_user?.dailyQuota ?? '—'}'),
                        const SizedBox(height: 8),
                        _infoRow(theme, 'Streak', '${_user?.streakCount ?? 0} hari'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Tombol Keluar
                FilledButton.icon(
                  onPressed: () async {
                    try {
                      await _auth.signOut();
                    } catch (_) {
                      // Biarkan user tetap melihat pesan error di layar jika sign out gagal.
                    }

                    if (!context.mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Keluar'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _infoRow(ThemeData theme, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(value, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Color _chipColor(WinatraTier? tier, ThemeData theme) {
    switch (tier) {
      case WinatraTier.premium:
        return Colors.amber.shade700;
      case WinatraTier.legend:
        return Colors.deepPurple;
      default:
        return theme.colorScheme.secondary;
    }
  }
}