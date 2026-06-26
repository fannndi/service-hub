import 'package:flutter/material.dart';

import '../../../../ui/theme/app_spacing.dart';
import '../../../../ui/widgets/modern_card.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/customer_models.dart';
import 'formatters.dart';

class CouponRewardBanner extends StatelessWidget {
  const CouponRewardBanner({super.key, required this.coupon});
  final CouponReward coupon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: ModernCard(
        color: scheme.primaryContainer,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.couponAdded.replaceFirst('{amount}', rupiah(coupon.amount)),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SelectableText(
              context.l10n.couponCode.replaceFirst('{code}', coupon.code),
              style: TextStyle(color: scheme.onPrimaryContainer),
            ),
            Text(
              context.l10n.validUntil.replaceFirst('{date}', shortDate(coupon.expiredAt)),
              style: TextStyle(
                color: scheme.onPrimaryContainer.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
