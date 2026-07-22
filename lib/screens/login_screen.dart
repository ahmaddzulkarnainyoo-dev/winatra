import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../core/services/auth_service.dart';
import '../core/services/overlay_permission_service.dart';
import '../core/widgets/winatra_snackbar.dart';
import 'main_nav_screen.dart';
import 'overlay_permission_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Masuk')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outlined),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      setState(() => _isLoading = true);
                      try {
                        final error = await AuthService()
                            .signIn(
                              _emailController.text,
                              _passwordController.text,
                            )
                            .timeout(const Duration(seconds: 10));
                        if (mounted) setState(() => _isLoading = false);
                        if (error == null) {
                          if (!context.mounted) return;
                          final hasPermission = await OverlayPermissionService.hasPermission();
                          if (!context.mounted) return;
                          if (hasPermission) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const MainNavScreen()),
                            );
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const OverlayPermissionScreen()),
                            );
                          }
                        } else {
                          if (!context.mounted) return;
                          showWinatraSnackbar(context, message: error, isError: true);
                        }
                      } on TimeoutException catch (_) {
                        if (mounted) {
                          setState(() => _isLoading = false);
                          showWinatraSnackbar(context, message: 'Koneksi lambat, coba lagi.', isError: true);
                        }
                      } catch (e) {
                        if (mounted) {
                          setState(() => _isLoading = false);
                          showWinatraSnackbar(context, message: 'Gagal login: $e', isError: true);
                        }
                      }
                    },
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Masuk'),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text.rich(
                TextSpan(
                  text: 'Belum punya akun? ',
                  style: theme.textTheme.bodyMedium,
                  children: [
                    TextSpan(
                      text: 'Daftar',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
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
}