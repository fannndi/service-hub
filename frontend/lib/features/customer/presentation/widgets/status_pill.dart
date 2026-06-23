import 'package:flutter/material.dart';

import '../../../../ui/theme/app_spacing.dart';
import '../../domain/customer_models.dart';

class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      OrderStatus.completed => const Color(0xFF10B981),
      OrderStatus.cancelled => const Color(0xFFEF4444),
      OrderStatus.waitingPayment => const Color(0xFFF59E0B),
      OrderStatus.waitingApproval => const Color(0xFF3B82F6),
      OrderStatus.disputed => const Color(0xFF8B5CF6),
      _ => const Color(0xFF06B6D4),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}
