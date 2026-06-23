import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../ui/theme/app_spacing.dart';
import '../../domain/customer_models.dart';
import 'empty_message.dart';

class OrderStatusTimeline extends StatelessWidget {
  const OrderStatusTimeline({super.key, required this.entries});
  final List<TrackingEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const EmptyMessage('Tracking belum tersedia.');
    final sorted = [...entries]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final scheme = Theme.of(context).colorScheme;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final entry = sorted[index];
        final isActive = index == 0;
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isActive
                          ? scheme.primaryContainer
                          : const Color(0xFF10B981).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isActive
                          ? Icons.radio_button_checked_rounded
                          : Icons.check_circle_rounded,
                      size: 18,
                      color: isActive
                          ? scheme.primary
                          : const Color(0xFF10B981),
                    ),
                  ),
                  if (index < sorted.length - 1)
                    Container(
                      width: 2,
                      height: 32,
                      color: scheme.outlineVariant,
                    ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.status.label,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        entry.note ?? 'Status diperbarui.',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
                            .format(entry.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
