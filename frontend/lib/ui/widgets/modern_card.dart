import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

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
    final scheme = Theme.of(context).colorScheme;
    final decoration = BoxDecoration(
      color: color ?? scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(AppRadius.xl),
    );
    final effectivePadding = padding ?? const EdgeInsets.all(AppSpacing.lg);
    if (onTap != null) {
      return Material(color: Colors.transparent, borderRadius: BorderRadius.circular(AppRadius.xl),
        child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(AppRadius.xl),
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
    return Container(color: Theme.of(context).colorScheme.surface, child: child);
  }
}
