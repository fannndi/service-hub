import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/order_providers.dart';
import '../../domain/store_admin_models.dart';
import '../widgets/store_admin_widgets.dart';
import '../../../../../core/l10n/app_localizations.dart';
import 'package:m3_expressive/m3_expressive.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key, required this.orderId});
  final String orderId;
  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  final title = TextEditingController();
  final note = TextEditingController();
  late Future<List<dynamic>> _trackingFuture;

  @override
  void initState() {
    super.initState();
    _trackingFuture =
        ref.read(storeOrderRepositoryProvider).getTracking(widget.orderId);
  }

  void _refresh() {
    setState(() {
      _trackingFuture =
          ref.read(storeOrderRepositoryProvider).getTracking(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(storeOrderRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.trackingTimeline)),
      body: FutureBuilder<List<dynamic>>(
        future: _trackingFuture,
        builder: (context, snapshot) {
          final events = (snapshot.data ?? [])
              .whereType<Map<String, dynamic>>()
              .map(TrackingEvent.fromJson)
              .toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                  controller: title,
                  decoration:
                      InputDecoration(labelText: context.l10n.eventTitle)),
              TextField(
                  controller: note,
                  decoration:
                      InputDecoration(labelText: context.l10n.notes)),
              FilledButton.icon(
                onPressed: () async {
                  await repo.addTracking(
                      widget.orderId, title.text, note.text, 'progress');
                  title.clear();
                  note.clear();
                  _refresh();
                },
                icon: const Icon(Icons.add),
                label: Text(context.l10n.addEvent),
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: M3LoadingIndicator()),
              for (final event in events)
                ListTile(
                    leading: const Icon(Icons.check_circle_outline),
                    title: Text(event.title),
                    subtitle: Text('${event.note}\n${dateText(event.createdAt)}')),
            ],
          );
        },
      ),
    );
  }
}
