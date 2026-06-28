import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/customer_providers.dart';
import '../../data/customer_repositories.dart';
import '../../domain/order_models.dart';
import '../widgets/customer_widgets.dart';

class TrackingScreen extends ConsumerWidget {
  const TrackingScreen({super.key, required this.orderId});
  final String orderId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracking = ref.watch(orderTrackingProvider(orderId));
    return CustomerScaffold(
      title: 'Tracking',
      child: tracking.when(
        data: (entries) {
          final parsed = entries
              .whereType<Map<String, dynamic>>()
              .map(TrackingEntry.fromJson)
              .toList();
          return ListView(padding: const EdgeInsets.all(16), children: [
            OrderStatusTimeline(entries: parsed),
            const SizedBox(height: 12),
            Text(
                'Diperbarui: ${DateFormat('HH:mm', 'id_ID').format(DateTime.now())}',
                textAlign: TextAlign.center),
          ]);
        },
        loading: () => const SkeletonList(),
        error: (error, _) => Center(child: Text(parseApiError(error))),
      ),
    );
  }
}
