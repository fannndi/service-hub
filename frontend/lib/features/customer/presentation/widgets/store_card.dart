import 'package:flutter/material.dart';

import '../../../../ui/theme/app_decorations.dart';
import '../../../../ui/theme/app_spacing.dart';
import '../../../../ui/widgets/modern_card.dart';
import '../../domain/customer_models.dart';

class StoreCard extends StatelessWidget {
  const StoreCard({super.key, required this.store, required this.onTap});
  final ServiceStore store;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: ModernCard(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: AppDecorations.iconBadge(
                scheme.primaryContainer.withValues(alpha: 0.8),
                size: 48,
              ),
              child: Icon(Icons.storefront_rounded, color: scheme.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.storeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    store.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, size: 14, color: scheme.tertiary),
                      const SizedBox(width: 4),
                      Text(
                        '${store.ratingAvg.toStringAsFixed(1)} (${store.reviewCount})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      if (store.verifiedAt != null) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.verified_rounded,
                            size: 14, color: scheme.primary),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
