import 'package:flutter/material.dart';

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

class AppRadius {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double full = 999;
}

class AppElevation {
  static const double none = 0;
  static const double low = 2;
  static const double medium = 8;
  static const double high = 16;
}

@immutable
class ServisSpacing extends ThemeExtension<ServisSpacing> {
  const ServisSpacing({
    this.xs = 4,
    this.sm = 8,
    this.md = 12,
    this.lg = 16,
    this.xl = 24,
    this.xxl = 32,
    this.xxxl = 48,
  });

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;
  final double xxxl;

  @override
  ServisSpacing copyWith({double? xs, double? sm, double? md, double? lg, double? xl, double? xxl, double? xxxl}) {
    return ServisSpacing(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
      xxxl: xxxl ?? this.xxxl,
    );
  }

  @override
  ServisSpacing lerp(ServisSpacing? other, double t) {
    if (other is! ServisSpacing) return this;
    return ServisSpacing(
      xs: xs + (other.xs - xs) * t,
      sm: sm + (other.sm - sm) * t,
      md: md + (other.md - md) * t,
      lg: lg + (other.lg - lg) * t,
      xl: xl + (other.xl - xl) * t,
      xxl: xxl + (other.xxl - xxl) * t,
      xxxl: xxxl + (other.xxxl - xxxl) * t,
    );
  }
}

extension ServisSpacingContext on BuildContext {
  ServisSpacing get spacing => Theme.of(this).extension<ServisSpacing>() ?? const ServisSpacing();
}
