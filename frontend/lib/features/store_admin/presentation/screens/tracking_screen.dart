import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/store_admin_providers.dart';
import '../../domain/store_admin_models.dart';
import '../widgets/store_admin_widgets.dart';

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
        ref.read(storeOperationsRepositoryProvider).getTracking(widget.orderId);
  }

  void _refresh() {
    setState(() {
      _trackingFuture =
          ref.read(storeOperationsRepositoryProvider).getTracking(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(storeOperationsRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Tracking Timeline')),
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
                  decoration: const InputDecoration(labelText: 'Judul event')),
              TextField(
                  controller: note,
                  decoration: const InputDecoration(labelText: 'Catatan')),
              FilledButton.icon(
                onPressed: () async {
                  await repo.addTracking(
                      widget.orderId, title.text, note.text, 'progress');
                  title.clear();
                  note.clear();
                  _refresh();
                },
                icon: const Icon(Icons.add),
                label: const Text('Tambah Event'),
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator()),
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
