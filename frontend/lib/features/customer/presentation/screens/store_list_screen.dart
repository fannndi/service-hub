import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../application/customer_providers.dart';
import '../widgets/customer_widgets.dart';
import '../../../../ui/theme/app_spacing.dart';
import 'package:m3_expressive/m3_expressive.dart';

class StoreListScreen extends ConsumerStatefulWidget {
  const StoreListScreen({super.key});
  @override
  ConsumerState<StoreListScreen> createState() => _StoreListScreenState();
}

class _StoreListScreenState extends ConsumerState<StoreListScreen> {
  String _brand = 'All';
  final _model = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final deviceModels = ref.watch(deviceModelsProvider);
    final brands = deviceModels.valueOrNull
        ?.map((group) => group.brand)
        .toSet()
        .toList() ??
        const <String>[];
    brands.sort();
    final stores = ref.watch(storeListProvider((brand: _brand, model: _model.text)));

    return CustomerScaffold(
      title: context.l10n.selectStore,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
          child: SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              children: [
                SegmentedButton<String>(
                  segments: ['All', ...brands].map((brand) =>
                    ButtonSegment(value: brand, label: Text(brand, style: const TextStyle(fontSize: 12)))
                  ).toList(),
                  selected: {_brand},
                  onSelectionChanged: (v) => setState(() => _brand = v.first),
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
          child: TextField(
            controller: _model,
            decoration: InputDecoration(
              hintText: context.l10n.searchDeviceModelHint,
              prefixIcon: Icon(Icons.search, size: 20),
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        Expanded(
          child: stores.when(
            data: (list) => list.isEmpty
                ? EmptyMessage(context.l10n.noStores)
                : ListView(
                    children: list
                        .map((store) => StoreCard(
                              store: store,
                              onTap: () => context.push('/stores/${store.id}'),
                            ))
                        .toList(),
                  ),
            loading: () => const Center(child: M3LoadingIndicator()),
            error: (_, __) => EmptyMessage(context.l10n.noStores),
          ),
        ),
      ]),
    );
  }
}
