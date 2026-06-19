import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/customer_models.dart';
import '../widgets/customer_widgets.dart';

class ReviewSuccessScreen extends StatelessWidget {
  const ReviewSuccessScreen({super.key, required this.result});
  final ReviewResult result;
  @override
  Widget build(BuildContext context) => CustomerScaffold(
        title: 'Ulasan Berhasil',
        child: ListView(padding: const EdgeInsets.all(24), children: [
          const Icon(Icons.celebration, size: 80, color: Colors.orange),
          Text('Ulasan berhasil dikirim!',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          if (result.coupon != null) CouponRewardBanner(coupon: result.coupon!),
          FilledButton(
              onPressed: () => context.go('/coupons'),
              child: const Text('Lihat Kupon Saya')),
          OutlinedButton(
              onPressed: () => context.go('/orders'),
              child: const Text('Kembali ke Pesanan')),
        ]),
      );
}
