import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/customer_providers.dart';
import '../widgets/customer_widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(customerAuthProvider).valueOrNull;
    final summary = ref.watch(homeSummaryProvider);
    final recent = ref.watch(customerOrdersProvider('recent'));
    final scheme = Theme.of(context).colorScheme;
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
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: .75)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Halo, ${user?.fullName ?? 'Pelanggan'}',
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 6),
                            Text(
                                'Pantau servis, garansi, dan kupon tanpa chat bolak-balik.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: scheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      Icon(Icons.phone_iphone_outlined, color: scheme.primary),
                    ],
                  ),
                ),
              ),
            ),
            summary.when(
              data: (data) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  _SummaryTile(
                      label: 'Aktif',
                      value: data.activeOrders.toString(),
                      icon: Icons.pending_actions_outlined),
                  const SizedBox(width: 10),
                  _SummaryTile(
                      label: 'Kupon',
                      value: data.activeCoupons.toString(),
                      icon: Icons.local_offer_outlined),
                  const SizedBox(width: 10),
                  _SummaryTile(
                      label: 'Garansi',
                      value: data.activeWarranties.toString(),
                      icon: Icons.verified_outlined),
                ]),
              ),
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
                        icon: const Icon(Icons.add_task_outlined),
                        label: const Text('Servis'))),
                const SizedBox(width: 8),
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: () => context.push('/orders'),
                        icon: const Icon(Icons.receipt_long_outlined),
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                color: scheme.tertiaryContainer.withValues(alpha: .55),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.bolt_outlined,
                          color: scheme.onTertiaryContainer),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                            'Promo bulan ini: cek perangkat lebih cepat dan pantau progres langsung dari aplikasi.',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile(
      {required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 10),
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900)),
              Text(label,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant))
            ]),
          ),
        ),
      );
}
