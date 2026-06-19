import 'package:flutter/material.dart';

class AppColors {
  static const primary = Colors.teal;
  static const secondary = Colors.tealAccent;
  static const error = Colors.red;
  static const warning = Colors.orange;
  static const success = Colors.green;
  static const background = Color(0xFFF5F5F5);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
}

class AppTheme {
  static ThemeData get light => ThemeData(
        colorSchemeSeed: AppColors.primary,
        useMaterial3: true,
        brightness: Brightness.light,
      );

  static ThemeData get dark => ThemeData(
        colorSchemeSeed: AppColors.primary,
        useMaterial3: true,
        brightness: Brightness.dark,
      );
}
