import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

Future<T?> showServisBottomSheet<T>(BuildContext context, {
  required String title,
  required List<T> items,
  required Widget Function(T item) itemBuilder,
  String? emptyMessage,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (ctx, controller) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(title, style: Theme.of(ctx).textTheme.titleMedium),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        emptyMessage ?? 'Tidak ada data',
                        style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: controller,
                    itemCount: items.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (_, index) => itemBuilder(items[index]),
                  ),
          ),
        ],
      ),
    ),
  );
}
