import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/customer_providers.dart';
import '../widgets/customer_widgets.dart';

class StoreDetailScreen extends ConsumerWidget {
  const StoreDetailScreen({super.key, required this.storeId});
  final String storeId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(storeDetailProvider(storeId));
    final spareparts = ref.watch(sparepartsProvider(storeId));
    return CustomerScaffold(
      title: 'Detail Toko',
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/booking/$storeId'),
          icon: const Icon(Icons.add),
          label: const Text('Buat Order')),
      child: AsyncPage(
        value: detail,
        builder: (store) => DefaultTabController(
          length: 2,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(store.storeName,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    Text(store.address),
                    const SizedBox(height: 8),
                    Text(
                        'Rating ${store.ratingAvg.toStringAsFixed(1)} - ${store.phoneNumber}${store.verifiedAt != null ? ' - Verified' : ''}'),
                  ]),
            ),
            const TabBar(tabs: [Tab(text: 'Sparepart'), Tab(text: 'Ulasan')]),
            Expanded(
              child: TabBarView(children: [
                spareparts.when(
                  data: (items) => items.isEmpty
                      ? const EmptyMessage('Sparepart belum tersedia.')
                      : ListView(
                          children: items
                              .map((part) => ListTile(
                                  title: Text(part.partName),
                                  subtitle:
                                      Text('${part.brand} ${part.deviceModel}'),
                                  trailing: Text(part.availableQty <= 0
                                      ? 'Habis'
                                      : rupiah(part.price))))
                              .toList()),
                  loading: () => const SkeletonList(),
                  error: (_, __) =>
                      const EmptyMessage('Sparepart gagal dimuat.'),
                ),
                store.reviews.isEmpty
                    ? const EmptyMessage('Belum ada ulasan.')
                    : ListView(
                        children: store.reviews
                            .map((review) => ListTile(
                                title: Text('${review.rating}/5'),
                                subtitle:
                                    Text(review.comment ?? 'Tanpa komentar')))
                            .toList()),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
