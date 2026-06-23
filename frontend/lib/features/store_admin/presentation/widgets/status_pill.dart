import 'package:flutter/material.dart';

import '../../../../ui/theme/app_spacing.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, this.warning = false});
  final String label;
  final bool warning;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: warning
              ? const Color(0xFFF59E0B).withValues(alpha: 0.14)
              : Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: warning
                    ? const Color(0xFFB45309)
                    : Theme.of(context).colorScheme.primary,
              ),
        ),
      );
}
