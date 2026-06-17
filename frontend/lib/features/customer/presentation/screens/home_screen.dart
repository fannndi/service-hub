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

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(customerAuthProvider).valueOrNull;
    final summary = ref.watch(homeSummaryProvider);
    final recent = ref.watch(customerOrdersProvider('recent'));
    return CustomerScaffold(
      title: 'ServisGadget',
      actions: [
        IconButton(
            onPressed: () => context.push('/notifications'),
            icon: const Icon(Icons.notifications_outlined)),
        IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined)),
        IconButton(
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.person_outline)),
      ],
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(homeSummaryProvider);
          ref.invalidate(customerOrdersProvider('recent'));
          ref.invalidate(featuredStoresProvider);
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Halo, ${user?.fullName ?? 'Pelanggan'}!',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ),
            summary.when(
              data: (data) => Row(children: [
                _SummaryTile(
                    label: 'Aktif', value: data.activeOrders.toString()),
                _SummaryTile(
                    label: 'Kupon', value: data.activeCoupons.toString()),
                _SummaryTile(
                    label: 'Garansi', value: data.activeWarranties.toString()),
              ]),
              loading: () => const SizedBox(
                  height: 88,
                  child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Ringkasan belum tersedia.')),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(
                    child: FilledButton.icon(
                        onPressed: () => context.push('/stores'),
                        icon: const Icon(Icons.build),
                        label: const Text('Servis'))),
                const SizedBox(width: 8),
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: () => context.push('/orders'),
                        icon: const Icon(Icons.inventory_2),
                        label: const Text('Pesanan'))),
                const SizedBox(width: 8),
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: () => context.push('/coupons'),
                        icon: const Icon(Icons.local_offer),
                        label: const Text('Kupon'))),
              ]),
            ),
            SectionTitle('Pesanan Terbaru',
                action: TextButton(
                    onPressed: () => context.push('/orders'),
                    child: const Text('Lihat Semua'))),
            recent.when(
              data: (orders) => orders.isEmpty
                  ? const EmptyMessage('Belum ada pesanan.')
                  : Column(
                      children: orders
                          .map((order) => OrderCard(
                              order: order,
                              onTap: () => context.push('/orders/${order.id}')))
                          .toList()),
              loading: () =>
                  const SizedBox(height: 260, child: SkeletonList(count: 3)),
              error: (_, __) =>
                  const EmptyMessage('Pesanan belum bisa dimuat.'),
            ),
            Card(
              margin: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: const Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                    'Promo servis bulan ini: cek perangkat lebih cepat dan pantau progres langsung dari aplikasi.',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900)),
              Text(label)
            ]),
          ),
        ),
      );
}
