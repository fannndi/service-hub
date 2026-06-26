import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_spacing.dart';

class AppColors {
  static const primary = Color(0xFF0891B2);
  static const primaryLight = Color(0xFF22D3EE);
  static const secondary = Color(0xFF6366F1);
  static const accent = Color(0xFFD946EF);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const success = Color(0xFF10B981);
  static const bg = Color(0xFFEDF2F7);
  static const surface = Colors.white;
  static const surfaceAlt = Color(0xFFE8EEF4);
  static const border = Color(0xFFD1D9E6);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
}

class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFB0EAF5),
      onPrimaryContainer: const Color(0xFF003544),
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFD1D0FF),
      onSecondaryContainer: const Color(0xFF13006B),
      tertiary: AppColors.accent,
      onTertiary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerLowest: const Color(0xFFF4F8FB),
      surfaceContainerLow: Colors.white,
      surfaceContainer: AppColors.bg,
      surfaceContainerHigh: AppColors.surfaceAlt,
      surfaceContainerHighest: const Color(0xFFE2E8F0),
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: const Color(0xFFE2E8F0),
    );

    return _base(scheme).copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      dividerColor: scheme.outlineVariant,
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: const Color(0xFF22D3EE),
      onPrimary: const Color(0xFF003544),
      primaryContainer: const Color(0xFF004D63),
      onPrimaryContainer: const Color(0xFFB0EAF5),
      secondary: const Color(0xFF818CF8),
      onSecondary: const Color(0xFF13006B),
      secondaryContainer: const Color(0xFF2E00A3),
      onSecondaryContainer: const Color(0xFFD1D0FF),
      tertiary: const Color(0xFFF472B6),
      onTertiary: const Color(0xFF4A002F),
      error: const Color(0xFFF87171),
      onError: const Color(0xFF601410),
      surface: const Color(0xFF1A1F2E),
      onSurface: const Color(0xFFE2E8F0),
      surfaceContainerLowest: const Color(0xFF141824),
      surfaceContainerLow: const Color(0xFF1A1F2E),
      surfaceContainer: const Color(0xFF1E2335),
      surfaceContainerHigh: const Color(0xFF292E40),
      surfaceContainerHighest: const Color(0xFF34394C),
      onSurfaceVariant: const Color(0xFF94A3B8),
      outline: const Color(0xFF475569),
      outlineVariant: const Color(0xFF334155),
    );

    return _base(scheme).copyWith(
      scaffoldBackgroundColor: const Color(0xFF141824),
      dividerColor: scheme.outlineVariant,
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    final base = GoogleFonts.interTextTheme(Typography.material2021().black);
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontWeight: FontWeight.w800, letterSpacing: -0.5, color: scheme.onSurface,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontWeight: FontWeight.w800, letterSpacing: -0.4, color: scheme.onSurface,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontWeight: FontWeight.w700, letterSpacing: -0.3, color: scheme.onSurface,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700, letterSpacing: -0.3, color: scheme.onSurface,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700, letterSpacing: -0.2, color: scheme.onSurface,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600, color: scheme.onSurface,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w700, letterSpacing: -0.2, color: scheme.onSurface,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w700, color: scheme.onSurface,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontWeight: FontWeight.w600, color: scheme.onSurface,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w700, letterSpacing: 0.1, color: scheme.onSurface,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontWeight: FontWeight.w600, color: scheme.onSurface,
      ),
    );
  }

  static ThemeData _base(ColorScheme scheme) {
    final textTheme = _textTheme(scheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      extensions: const [ServisSpacing()],
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: scheme.onSurface, fontWeight: FontWeight.w800,
        ),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        margin: EdgeInsets.zero,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          elevation: 0,
          shadowColor: scheme.primary.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: textTheme.labelLarge?.copyWith(letterSpacing: 0.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        floatingLabelStyle: textTheme.bodyMedium?.copyWith(color: scheme.primary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 72,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        shadowColor: scheme.shadow.withValues(alpha: 0.08),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        selectedIconTheme: IconThemeData(color: scheme.primary),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700, color: scheme.primary,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(
          scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        ),
        headingTextStyle: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w800, color: scheme.onSurface,
        ),
        dataTextStyle: textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
        dividerThickness: 0.5,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primaryContainer,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: scheme.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
