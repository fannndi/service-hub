import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../application/customer_providers.dart';
import '../widgets/customer_widgets.dart';

class CouponsScreen extends ConsumerWidget {
  const CouponsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => CustomerScaffold(
        title: context.l10n.myCoupons,
        child: AsyncPage(
            value: ref.watch(couponsProvider),
            builder: (items) => items.isEmpty
                ? EmptyMessage(context.l10n.noCoupons)
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: items
                        .map((coupon) => CouponRewardBanner(coupon: coupon))
                        .toList())),
      );
}
