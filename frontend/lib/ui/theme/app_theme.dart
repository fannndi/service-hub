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
  static const bg = Color(0xFFE2E8F0);
  static const surface = Colors.white;
  static const surfaceAlt = Color(0xFFF1F5F9);
  static const border = Color(0xFFCBD5E1);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
}

class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFA5E1F0),
      onPrimaryContainer: const Color(0xFF003544),
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFD1D0FF),
      onSecondaryContainer: const Color(0xFF13006B),
      tertiary: AppColors.accent,
      onTertiary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: const Color(0xFFFECACA),
      onErrorContainer: const Color(0xFF450A0A),
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerLowest: AppColors.bg,
      surfaceContainerLow: AppColors.surface,
      surfaceContainer: AppColors.surfaceAlt,
      surfaceContainerHigh: AppColors.border,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: const Color(0xFFE2E8F0),
      shadow: Colors.black,
      scrim: Colors.black,
    );

    return _base(scheme).copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      dividerColor: scheme.outline,
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: const Color(0xFF22D3EE),
      onPrimary: const Color(0xFF003544),
      primaryContainer: const Color(0xFF004D63),
      onPrimaryContainer: const Color(0xFFA5E1F0),
      secondary: const Color(0xFF818CF8),
      onSecondary: const Color(0xFF13006B),
      secondaryContainer: const Color(0xFF2E00A3),
      onSecondaryContainer: const Color(0xFFD1D0FF),
      tertiary: const Color(0xFFF472B6),
      onTertiary: const Color(0xFF4A002F),
      error: const Color(0xFFF87171),
      onError: const Color(0xFF601410),
      errorContainer: const Color(0xFF93000A),
      onErrorContainer: const Color(0xFFFECACA),
      surface: const Color(0xFF1A1F2E),
      onSurface: const Color(0xFFE2E8F0),
      surfaceContainerLowest: const Color(0xFF0F172A),
      surfaceContainerLow: const Color(0xFF1A1F2E),
      surfaceContainer: const Color(0xFF1E2335),
      surfaceContainerHigh: const Color(0xFF292E40),
      onSurfaceVariant: const Color(0xFF94A3B8),
      outline: const Color(0xFF475569),
      outlineVariant: const Color(0xFF334155),
      shadow: Colors.black,
      scrim: Colors.black,
    );

    return _base(scheme).copyWith(
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      dividerColor: scheme.outline,
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    final base = GoogleFonts.interTextTheme(Typography.material2021().black);
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5, color: scheme.onSurface),
      displayMedium: base.displayMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.4, color: scheme.onSurface),
      headlineLarge: base.headlineLarge?.copyWith(fontWeight: FontWeight.w700, color: scheme.onSurface),
      headlineMedium: base.headlineMedium?.copyWith(fontWeight: FontWeight.w700, color: scheme.onSurface),
      headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.w600, color: scheme.onSurface),
      titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: scheme.onSurface),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: scheme.onSurface),
      titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: scheme.onSurface),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.1, color: scheme.onSurface),
      labelMedium: base.labelMedium?.copyWith(fontWeight: FontWeight.w600, color: scheme.onSurface),
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
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          elevation: 0,
          shadowColor: AppColors.primary.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: textTheme.labelLarge?.copyWith(letterSpacing: 0.2, color: Colors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          side: BorderSide(color: scheme.outline, width: 1),
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
        fillColor: AppColors.bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        floatingLabelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.primary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 2,
        height: 72,
        backgroundColor: scheme.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        selectedIconTheme: IconThemeData(color: AppColors.primary),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: AppColors.border),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.primary.withValues(alpha: 0.15),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
        side: BorderSide(color: AppColors.border),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
    );
  }
}
