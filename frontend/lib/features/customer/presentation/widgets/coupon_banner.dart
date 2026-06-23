import 'package:flutter/material.dart';

import '../../../../ui/theme/app_decorations.dart';
import '../../../../ui/theme/app_spacing.dart';
import '../../../../ui/widgets/modern_card.dart';
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
              'Kupon diskon ${rupiah(coupon.amount)} sudah ditambahkan.',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SelectableText(
              'Kode: ${coupon.code}',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              'Berlaku s/d ${shortDate(coupon.expiredAt)}',
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
