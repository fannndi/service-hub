import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

class ModernCard extends StatelessWidget {
  const ModernCard({
    super.key, required this.child, this.onTap, this.padding, this.gradient, this.color,
  });
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Gradient? gradient;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final decoration = gradient != null
        ? BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 2)),
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1)),
            ],
          )
        : BoxDecoration(
            color: color ?? Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 2)),
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1)),
            ],
          );
    final effectivePadding = padding ?? const EdgeInsets.all(AppSpacing.lg);
    if (onTap != null) {
      return Material(color: Colors.transparent, borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Ink(decoration: decoration, padding: effectivePadding, child: child)));
    }
    return Container(decoration: decoration, padding: effectivePadding, child: child);
  }
}

class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: b == Brightness.dark ? [const Color(0xFF0F172A), const Color(0xFF141824)] : [AppColors.bg, const Color(0xFFD6E0EB)],
        ),
      ),
      child: child,
    );
  }
}
