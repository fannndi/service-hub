import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../ui/theme/app_spacing.dart';
import '../../application/customer_providers.dart';
import '../widgets/customer_widgets.dart';

class StoreDetailScreen extends ConsumerStatefulWidget {
  const StoreDetailScreen({super.key, required this.storeId});
  final String storeId;
  @override
  ConsumerState<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends ConsumerState<StoreDetailScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(storeDetailProvider(widget.storeId));
    final spareparts = ref.watch(sparepartsProvider(widget.storeId));
    final scheme = Theme.of(context).colorScheme;

    return CustomerScaffold(
      title: context.l10n.storeDetail,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/booking/${widget.storeId}'),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.createOrder),
      ),
      child: AsyncPage(
        value: detail,
        builder: (store) => Column(children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(store.storeName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: AppSpacing.xs),
                Text(store.address, style: TextStyle(color: scheme.onSurfaceVariant)),
                const SizedBox(height: AppSpacing.sm),
                Row(children: [
                  Icon(Icons.star_rounded, size: 18, color: scheme.tertiary),
                  const SizedBox(width: 4),
                  Text('${store.ratingAvg.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: AppSpacing.md),
                  Icon(Icons.phone_outlined, size: 16, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(store.phoneNumber, style: TextStyle(color: scheme.onSurfaceVariant)),
                  if (store.verifiedAt != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Icon(Icons.verified_rounded, size: 16, color: scheme.primary),
                  ],
                ]),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: SegmentedButton<int>(
              segments: [
                ButtonSegment(value: 0, label: Text(context.l10n.sparepart)),
                ButtonSegment(value: 1, label: Text(context.l10n.reviews)),
              ],
              selected: {_tab},
              onSelectionChanged: (v) => setState(() => _tab = v.first),
              showSelectedIcon: false,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: _tab == 0
              ? spareparts.when(
                  data: (items) => items.isEmpty
                    ? EmptyMessage(context.l10n.sparepartNotAvailable)
                    : ListView(children: items.map((part) => ListTile(
                        title: Text(part.partName),
                        subtitle: Text('${part.brand} ${part.deviceModel}'),
                        trailing: Text(part.availableQty <= 0
                          ? context.l10n.outOfStock
                          : rupiah(part.price)),
                      )).toList()),
                  loading: () => const SkeletonList(),
                  error: (_, __) => EmptyMessage(context.l10n.sparepartLoadError),
                )
              : store.reviews.isEmpty
                ? EmptyMessage(context.l10n.noReviews)
                : ListView(children: store.reviews.map((review) => ListTile(
                    title: Text('${review.rating}/5'),
                    subtitle: Text(review.comment ?? context.l10n.noComment),
                  )).toList()),
          ),
        ]),
      ),
    );
  }
}
