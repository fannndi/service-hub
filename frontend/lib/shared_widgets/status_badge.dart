import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, this.isDanger = false});

  final String label;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? Colors.red : Theme.of(context).colorScheme.primary;
    return DecoratedBox(
      decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(999)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 12)),
      ),
    );
  }
}
