import 'package:flutter/material.dart';
import 'app_spacing.dart';
import 'app_theme.dart';

class AppGradients {
  static const primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0891B2), Color(0xFF22D3EE)],
  );

  static const hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F766E), Color(0xFF0891B2), Color(0xFF22D3EE)],
    stops: [0.0, 0.55, 1.0],
  );

  static const darkHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E3A5F), Color(0xFF0E7490)],
  );

  static const surface = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
  );

  static const darkSurface = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
  );

  static const accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
  );

  static LinearGradient heroFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkHero : hero;

  static LinearGradient surfaceFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkSurface : surface;
}

class AppShadows {
  static List<BoxShadow> soft(BuildContext context) => [
    BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 8)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
  ];

  static List<BoxShadow> card(BuildContext context) => [
    BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 2)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1)),
  ];

  static List<BoxShadow> elevated(BuildContext context) => [
    BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 32, offset: const Offset(0, 12)),
  ];
}

class AppDecorations {
  static BoxDecoration card(BuildContext context, {Color? color}) {
    return BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.border, width: 1),
      boxShadow: AppShadows.card(context),
    );
  }

  static BoxDecoration glass(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bg = brightness == Brightness.dark
        ? const Color(0xFF1E293B).withValues(alpha: 0.92)
        : Colors.white.withValues(alpha: 0.92);
    final borderColor = brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.white.withValues(alpha: 0.6);
    return BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      border: Border.all(color: borderColor),
      boxShadow: AppShadows.elevated(context),
    );
  }

  static BoxDecoration heroBanner(BuildContext context) {
    return BoxDecoration(
      gradient: AppGradients.heroFor(context),
      borderRadius: BorderRadius.circular(AppRadius.xl),
      boxShadow: AppShadows.elevated(context),
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
