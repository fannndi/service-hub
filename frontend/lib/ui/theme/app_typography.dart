import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static String get fontFamily => GoogleFonts.plusJakartaSans().fontFamily!;

  static TextStyle get heading1 => GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      );

  static TextStyle get heading2 => GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      );

  static TextStyle get heading3 => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get body => GoogleFonts.plusJakartaSans(fontSize: 14);

  static TextStyle get bodySmall => GoogleFonts.plusJakartaSans(fontSize: 12);

  static TextStyle get caption => GoogleFonts.plusJakartaSans(fontSize: 11);

  static TextStyle get button => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      );

  static TextStyle get overline => GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      );
}
