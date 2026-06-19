import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF0E6B5C);
  static const secondary = Color(0xFF31536C);
  static const accent = Color(0xFFC29A5B);
  static const error = Color(0xFFB42318);
  static const warning = Color(0xFFB54708);
  static const success = Color(0xFF067647);
  static const background = Color(0xFFF7F8F6);
  static const surface = Colors.white;
  static const surfaceAlt = Color(0xFFEFF3EF);
  static const border = Color(0xFFDDE3DE);
  static const textPrimary = Color(0xFF17211D);
  static const textSecondary = Color(0xFF66736D);
}

class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.accent,
      error: AppColors.error,
      surface: AppColors.surface,
      surfaceContainerHighest: AppColors.surfaceAlt,
    );

    return _base(scheme).copyWith(
      scaffoldBackgroundColor: AppColors.background,
      dividerColor: AppColors.border,
      extensions: const [],
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: const Color(0xFF7FD9C9),
      secondary: const Color(0xFF9EC4DD),
      tertiary: const Color(0xFFE0C083),
      error: const Color(0xFFFFB4AB),
    );

    return _base(scheme).copyWith(
      scaffoldBackgroundColor: const Color(0xFF101512),
      dividerColor: const Color(0xFF2A332F),
    );
  }

  static ThemeData _base(ColorScheme scheme) {
    final textTheme = Typography.material2021().black.apply(
          fontFamily: 'Roboto',
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Roboto',
      textTheme: textTheme.copyWith(
        headlineLarge: textTheme.headlineLarge
            ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0),
        headlineMedium: textTheme.headlineMedium
            ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0),
        headlineSmall: textTheme.headlineSmall
            ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0),
        titleLarge: textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0),
        titleMedium: textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0),
        labelLarge: textTheme.labelLarge
            ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .75)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 46),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle:
              const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 46),
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle:
              const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle:
              const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelMedium
              ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
        selectedLabelTextStyle: textTheme.labelMedium
            ?.copyWith(fontWeight: FontWeight.w800, color: scheme.onSurface),
        unselectedLabelTextStyle:
            textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(
            scheme.surfaceContainerHighest.withValues(alpha: .6)),
        headingTextStyle: textTheme.labelMedium
            ?.copyWith(fontWeight: FontWeight.w800, color: scheme.onSurface),
        dataTextStyle: textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
        dividerThickness: .6,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
    );
  }
}
