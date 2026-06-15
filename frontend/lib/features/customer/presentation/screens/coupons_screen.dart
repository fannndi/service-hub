import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/customer_providers.dart';
import '../../data/customer_repositories.dart';
import '../../domain/customer_models.dart';
import '../../domain/user_session.dart';
import '../../../../shared_widgets/error_state.dart';
import '../../../../shared_widgets/status_badge.dart';
import '../../../../shared_widgets/empty_state.dart';
import '../../../../shared_widgets/formatters.dart';
import '../widgets/customer_widgets.dart';

class CouponsScreen extends ConsumerWidget {
  const CouponsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => CustomerScaffold(
        title: 'Kupon Saya',
        child: AsyncPage(
            value: ref.watch(couponsProvider),
            builder: (items) => items.isEmpty
                ? const EmptyMessage('Belum ada kupon.')
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: items
                        .map((coupon) => CouponRewardBanner(coupon: coupon))
                        .toList())),
      );
}
