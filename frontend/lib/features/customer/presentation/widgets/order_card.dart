import 'package:flutter/material.dart';

import '../../../../ui/theme/app_spacing.dart';
import '../../../../ui/widgets/modern_card.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/customer_models.dart';
import 'formatters.dart';
import 'status_pill.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, required this.onTap});
  final CustomerOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final urgent = order.slaDeadline != null &&
        order.slaDeadline!.difference(DateTime.now()).inHours < 6 &&
        order.status.isActive;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: ModernCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.orderNumber,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                StatusPill(order.status),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              order.storeName ?? context.l10n.serviceStore,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text('${order.brand} ${order.deviceModel}'),
            const SizedBox(height: 4),
            Text(
              shortDate(order.createdAt),
              style: theme.textTheme.bodySmall,
            ),
            if (urgent) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: scheme.errorContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_outlined, size: 14, color: scheme.error),
                    const SizedBox(width: 4),
                    Text(
                      context.l10n.deadlineUnder6Hours,
                      style: TextStyle(
                        color: scheme.error,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
