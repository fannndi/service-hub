import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/store_admin_providers.dart';
import '../widgets/store_admin_widgets.dart';
import '../../../../ui/theme/app_theme.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(inventoryProvider);
    final query = ref.watch(inventoryQueryProvider);
    final brands = ref.watch(brandsProvider);

    return StoreAdminScaffold(
      title: 'Inventori',
      selectedIndex: 2,
      actions: [
        IconButton(
            onPressed: () => context.go('/store/inventory/new'),
            icon: const Icon(Icons.add),
            tooltip: 'Tambah sparepart')
      ],
      body: Column(children: [
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              SizedBox(
                width: 200,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Cari sparepart...',
                    prefixIcon: Icon(Icons.search, size: 18),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  ),
                  onChanged: (q) =>
                      ref.read(inventoryQueryProvider.notifier).state =
                          query.copyWith(search: q.isEmpty ? null : q, page: 1),
                ),
              ),
              const SizedBox(width: 8),
              brands.when(
                data: (list) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: query.brand,
                    hint: const Text('Brand', style: TextStyle(fontSize: 13)),
                    underline: const SizedBox(),
                    isDense: true,
                    icon: const Icon(Icons.expand_more, size: 18),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Semua Brand'))
                    ],
                    onChanged: (v) =>
                        ref.read(inventoryQueryProvider.notifier).state =
                            query.copyWith(brand: v, deviceModel: null, page: 1),
                  ),
                ),
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: query.partType,
                  hint: const Text('Tipe', style: TextStyle(fontSize: 13)),
                  underline: const SizedBox(),
                  isDense: true,
                  icon: const Icon(Icons.expand_more, size: 18),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Semua Tipe')),
                    DropdownMenuItem(
                        value: 'screen_replacement', child: Text('Layar')),
                    DropdownMenuItem(
                        value: 'battery_replacement', child: Text('Baterai')),
                    DropdownMenuItem(
                        value: 'charging_port', child: Text('Charging Port')),
                    DropdownMenuItem(value: 'camera', child: Text('Kamera')),
                    DropdownMenuItem(value: 'other', child: Text('Lainnya')),
                  ],
                  onChanged: (v) => ref
                      .read(inventoryQueryProvider.notifier)
                      .state = query.copyWith(partType: v, page: 1),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: data.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => ErrorPanel(
                message: err.toString(),
                onRetry: () => ref.invalidate(inventoryProvider)),
            data: (page) => page.items.isEmpty
                ? const Center(child: Text('Belum ada sparepart'))
                : ListView.builder(
                    itemCount: page.items.length,
                    itemBuilder: (context, index) {
                      final s = page.items[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.partName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14)),
                                    const SizedBox(height: 2),
                                    Text(
                                        '${s.brand} · ${s.deviceModel} · ${s.partTypeLabel}',
                                        style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(money(s.price),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13)),
                                        const SizedBox(width: 12),
                                        Text('Stok: ${s.availableStock}',
                                            style: TextStyle(
                                                color: s.isLowStock
                                                    ? Colors.red
                                                    : Colors.grey[700],
                                                fontSize: 12,
                                                fontWeight: s.isLowStock
                                                    ? FontWeight.w700
                                                    : FontWeight.normal)),
                                        if (s.qtyReserved > 0)
                                          Text(
                                              ' (${s.qtyReserved} direservasi)',
                                              style: TextStyle(
                                                  color: Colors.orange[700],
                                                  fontSize: 11)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                          Icons.remove_circle_outline,
                                          color: Colors.red),
                                      onPressed: s.qty > 0
                                          ? () => ref
                                              .read(inventoryProvider.notifier)
                                              .adjustStock(s.id, -1)
                                          : null,
                                      constraints: const BoxConstraints(
                                          minWidth: 32, minHeight: 32),
                                      padding: const EdgeInsets.all(2),
                                    ),
                                    Text('${s.qty}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16)),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline,
                                          color: Colors.green),
                                      onPressed: () => ref
                                          .read(inventoryProvider.notifier)
                                          .adjustStock(s.id, 1),
                                      constraints: const BoxConstraints(
                                          minWidth: 32, minHeight: 32),
                                      padding: const EdgeInsets.all(2),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => context
                                    .go('/store/inventory/${s.id}', extra: s),
                                constraints: const BoxConstraints(
                                    minWidth: 32, minHeight: 32),
                                padding: const EdgeInsets.all(2),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ]),
    );
  }
}
