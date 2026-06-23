import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

enum SnackbarType { success, error, warning, info }

void showServisSnackbar(BuildContext context, String message, {SnackbarType type = SnackbarType.info}) {
  final scheme = Theme.of(context).colorScheme;
  final (Color bg, Color iconColor, IconData icon) = switch (type) {
    SnackbarType.success => (const Color(0xFF065F46), const Color(0xFF10B981), Icons.check_circle_rounded),
    SnackbarType.error => (const Color(0xFF7F1D1D), const Color(0xFFEF4444), Icons.error_rounded),
    SnackbarType.warning => (const Color(0xFF78350F), const Color(0xFFF59E0B), Icons.warning_rounded),
    SnackbarType.info => (const Color(0xFF1E3A5F), scheme.primary, Icons.info_rounded),
  };

  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
      ],
    ),
    backgroundColor: bg,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
    margin: const EdgeInsets.all(AppSpacing.lg),
    duration: const Duration(seconds: 3),
  ));
}
