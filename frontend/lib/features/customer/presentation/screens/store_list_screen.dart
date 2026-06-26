import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../application/customer_providers.dart';
import '../widgets/customer_widgets.dart';

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
    final stores =
        ref.watch(storeListProvider((brand: _brand, model: _model.text)));
    return CustomerScaffold(
      title: context.l10n.selectStore,
      child: Column(children: [
        SizedBox(
          height: 54,
          child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: ['All', ...brands]
                  .map((brand) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 8),
                        child: FilterChip(
                            label: Text(brand),
                            selected: _brand == brand,
                            onSelected: (_) => setState(() => _brand = brand)),
                      ))
                  .toList()),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
              controller: _model,
                  decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: context.l10n.searchDeviceModelHint,
                  border: const OutlineInputBorder()),
              onSubmitted: (_) => setState(() {})),
        ),
        Expanded(
            child: AsyncPage(
                value: stores,
                builder: (items) => items.isEmpty
                    ? EmptyMessage(context.l10n.storeNotFound)
                    : ListView(
                        children: items
                            .map((store) => StoreCard(
                                store: store,
                                onTap: () =>
                                    context.push('/stores/${store.id}')))
                            .toList()))),
      ]),
    );
  }
}
