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

class BookingSuccessScreen extends StatelessWidget {
  const BookingSuccessScreen(
      {super.key, required this.orderNumber, required this.isNewCustomer});
  final String orderNumber;
  final bool isNewCustomer;
  @override
  Widget build(BuildContext context) => CustomerScaffold(
        title: 'Order Berhasil',
        child: ListView(padding: const EdgeInsets.all(24), children: [
          const Icon(Icons.check_circle, size: 84, color: Colors.green),
          const SizedBox(height: 16),
          Text('Order berhasil dibuat!',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          SelectableText(orderNumber, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          const Text('Admin toko akan segera mengkonfirmasi perangkatmu.',
              textAlign: TextAlign.center),
          if (isNewCustomer)
            const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Card(
                    child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                            'Cek WhatsApp kamu. Admin toko akan mengirimkan informasi akun ServisGadget.')))),
          const SizedBox(height: 24),
          FilledButton(
              onPressed: () => context.go('/orders'),
              child: const Text('Lihat Pesanan Saya')),
          OutlinedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Kembali ke Beranda')),
        ]),
      );
}
