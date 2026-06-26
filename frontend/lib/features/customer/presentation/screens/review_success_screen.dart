import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../ui/theme/app_spacing.dart';
import '../../domain/customer_models.dart';
import '../widgets/customer_widgets.dart';

class ReviewSuccessScreen extends StatelessWidget {
  const ReviewSuccessScreen({super.key, required this.result});
  final ReviewResult result;
  @override
  Widget build(BuildContext context) => CustomerScaffold(
        title: context.l10n.reviewSuccess,
        child: ListView(padding: const EdgeInsets.all(24), children: [
          Icon(Icons.celebration, size: 80, color: Theme.of(context).colorScheme.tertiary),
          Text(context.l10n.reviewSubmitted,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          if (result.coupon != null) CouponRewardBanner(coupon: result.coupon!),
          FilledButton(
              onPressed: () => context.go('/coupons'),
              child: Text(context.l10n.viewMyCoupons)),
          OutlinedButton(
              onPressed: () => context.go('/orders'),
              child: Text(context.l10n.backToOrders)),
        ]),
      );
}
