import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Helper untuk menampilkan SnackBar khas Winatra.
/// - Background gradient/surface color
/// - Border radius 14
/// - Ikon custom (✅ sukses / ⚠️ error)
/// - Animasi slide dari atas (SnackBarBehavior.floating)
void showWinatraSnackbar(
  BuildContext context, {
  required String message,
  bool isError = false,
  Duration duration = const Duration(seconds: 3),
  SnackBarAction? action,
}) {
  if (!context.mounted) return;

  final icon = isError ? Icons.warning_amber_rounded : Icons.check_circle;
  final iconColor = isError ? AppColors.danger : AppColors.success;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isError ? AppColors.danger.withValues(alpha: 0.3) : AppColors.success.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: duration,
        action: action,
        dismissDirection: DismissDirection.up,
      ),
    );
}