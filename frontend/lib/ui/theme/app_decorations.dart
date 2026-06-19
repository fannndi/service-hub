import 'package:flutter/material.dart';

import 'app_spacing.dart';

class AppGradients {
  static const primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)],
  );

  static const hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4338CA), Color(0xFF6366F1), Color(0xFF0891B2)],
    stops: [0.0, 0.55, 1.0],
  );

  static const surface = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
  );

  static const accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
  );
}

class AppShadows {
  static List<BoxShadow> soft(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: color.withValues(alpha: 0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> card(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> elevated(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.12),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
      ];
}

class AppDecorations {
  static BoxDecoration card(BuildContext context, {Color? color}) {
    final scheme = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: color ?? scheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      boxShadow: AppShadows.card(scheme.shadow),
    );
  }

  static BoxDecoration glass(BuildContext context) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(AppRadius.xl),
      border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
      boxShadow: AppShadows.elevated(Colors.indigo),
    );
  }

  static BoxDecoration heroBanner(BuildContext context) {
    return BoxDecoration(
      gradient: AppGradients.hero,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      boxShadow: AppShadows.elevated(const Color(0xFF4338CA)),
    );
  }

  static BoxDecoration iconBadge(Color bg, {double size = 52}) {
    return BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.md),
      boxShadow: [
        BoxShadow(
          color: bg.withValues(alpha: 0.35),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
