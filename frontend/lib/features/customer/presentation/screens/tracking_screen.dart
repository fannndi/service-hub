import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../application/customer_providers.dart';
import '../../data/customer_repositories.dart';
import '../../domain/customer_models.dart';
import '../../domain/user_session.dart';
import '../../../../shared_widgets/error_state.dart';
import '../../../../shared_widgets/status_badge.dart';
import '../../../../shared_widgets/empty_state.dart';
import '../../../../shared_widgets/formatters.dart';
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
        data: (order) => ListView(padding: const EdgeInsets.all(16), children: [
          OrderStatusTimeline(entries: order.tracking),
          const SizedBox(height: 12),
          Text(
              'Diperbarui: ${DateFormat('HH:mm', 'id_ID').format(DateTime.now())}',
              textAlign: TextAlign.center),
        ]),
        loading: () => const SkeletonList(),
        error: (error, _) => Center(child: Text(parseApiError(error))),
      ),
    );
  }
}
