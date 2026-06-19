import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/store_admin_providers.dart';
import '../widgets/store_admin_widgets.dart';

class ReviewsScreen extends ConsumerWidget {
  const ReviewsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(reviewsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Review Monitoring')),
      body: value.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorPanel(message: e.toString()),
        data: (page) => ListView(
          children: [
            for (final r in page.items)
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(r.customerName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          const Spacer(),
                          Text('${r.rating}/5',
                              style: const TextStyle(color: Colors.amber)),
                        ]),
                        if (r.comment.isNotEmpty) Text(r.comment),
                        Text(dateText(r.createdAt),
                            style: Theme.of(context).textTheme.bodySmall),
                        if (r.response != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text('Balasan: ${r.response}',
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary)),
                          ),
                      ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
