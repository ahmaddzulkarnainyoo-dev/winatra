import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
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
                        // Trial section
                        ..._buildTrialSection(theme),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Kartu Referral
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.share_outlined, color: theme.colorScheme.primary),
                            const SizedBox(width: 12),
                            Text('Kode Referral', style: theme.textTheme.labelMedium),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _auth.currentUser?.uid.substring(0, 8).toUpperCase() ?? '—',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bagikan kode ini ke teman. Setiap 3 teman yang berhasil daftar, kamu dapat bonus 10 kuota!',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.people_outline, size: 16, color: theme.colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              '${_user?.referralSuccessCount ?? 0} teman berhasil',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () {
                            final code = _auth.currentUser?.uid.substring(0, 8).toUpperCase() ?? '';
                            Share.share(
                              'Gabung Winatra AI pakai kode referralku: $code\n\nDapatkan asisten AI untuk belajar & kerja sehari-hari! Download sekarang!',
                            );
                          },
                          icon: const Icon(Icons.share, size: 18),
                          label: const Text('Bagikan'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(40),
                          ),
                        ),
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

  /// Membuat section trial — tombol aktivasi atau sisa waktu.
  List<Widget> _buildTrialSection(ThemeData theme) {
    final user = _user;
    if (user == null) return [];

    // Cek apakah trial sedang aktif (trialEndDate masih di masa depan)
    final trialEnd = user.trialEndDate;
    final now = DateTime.now();
    final isTrialActive = trialEnd != null && now.isBefore(trialEnd);

    if (isTrialActive) {
      // Tampilkan sisa waktu trial
      final remaining = trialEnd.difference(now);
      final hours = remaining.inHours;
      final minutes = remaining.inMinutes.remainder(60);
      return [
        const Divider(height: 24),
        Row(
          children: [
            Icon(Icons.timer_outlined, size: 16, color: Colors.amber.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Premium Trial',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.amber.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sisa ${hours}j ${minutes}m',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.amber.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ];
    }

    // Jika tier Free dan belum pernah pakai trial, tampilkan tombol aktivasi
    if (user.tier == WinatraTier.free && !user.hasUsedTrialPremium) {
      return [
        const Divider(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              try {
                await _auth.activateTrialForCurrentUser();
                if (!mounted) return;
                await _loadUser(); // reload data
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Selamat! Trial Premium 3 hari aktif!')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal aktivasi trial: $e')),
                );
              }
            },
            icon: const Icon(Icons.rocket_launch_outlined, size: 18),
            label: const Text('Coba Premium 3 Hari Gratis'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.amber.shade700,
              side: BorderSide(color: Colors.amber.shade700),
              minimumSize: const Size.fromHeight(40),
            ),
          ),
        ),
      ];
    }

    return [];
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
