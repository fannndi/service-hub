import 'package:flutter/material.dart';

import '../../../../ui/theme/app_decorations.dart';
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: ModernCard(
        gradient: AppGradients.primary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.couponAdded.replaceFirst('{amount}', rupiah(coupon.amount)),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SelectableText(
              context.l10n.couponCode.replaceFirst('{code}', coupon.code),
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              context.l10n.validUntil.replaceFirst('{date}', shortDate(coupon.expiredAt)),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
