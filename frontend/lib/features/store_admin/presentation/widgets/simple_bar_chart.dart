import 'package:flutter/material.dart';
import '../../../../ui/widgets/modern_card.dart';
import '../../domain/store_admin_models.dart';

class SimpleBarChart extends StatelessWidget {
  const SimpleBarChart({super.key, required this.title, required this.items});
  final String title;
  final List<CategoryMetric> items;
  @override
  Widget build(BuildContext context) {
    final max = items.fold<num>(
        1, (value, item) => item.value > value ? item.value : value);
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (items.isEmpty) const Text('Data grafik belum tersedia dari API'),
          for (final item in items.take(8))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                SizedBox(
                    width: 120,
                    child: Text(item.label,
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                Expanded(
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                            value: (item.value / max).clamp(0, 1).toDouble(),
                            minHeight: 10))),
                const SizedBox(width: 8),
                Text(item.value.toString()),
              ]),
            ),
          ]),
        );
  }
}
