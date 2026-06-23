import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/customer_providers.dart';
import '../../data/customer_repositories.dart';
import '../widgets/customer_widgets.dart';

class ReviewFormScreen extends ConsumerStatefulWidget {
  const ReviewFormScreen({super.key, required this.orderId});
  final String orderId;
  @override
  ConsumerState<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

class _ReviewFormScreenState extends ConsumerState<ReviewFormScreen> {
  final _comment = TextEditingController();
  int _rating = 5;
  bool _loading = false;
  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await ref.read(reviewRepositoryProvider).createReview(
          widget.orderId, rating: _rating, comment: _comment.text);
      ref.invalidate(orderDetailProvider(widget.orderId));
      if (mounted) context.go('/review-success');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(parseApiError(error))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => CustomerScaffold(
        title: 'Beri Ulasan',
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                  5,
                  (index) => IconButton(
                      iconSize: 38,
                      onPressed: () => setState(() => _rating = index + 1),
                      icon: Icon(
                          index < _rating ? Icons.star : Icons.star_border,
                          color: Colors.amber)))),
          Text(
              [
                '',
                'Sangat Buruk',
                'Buruk',
                'Biasa',
                'Bagus',
                'Sangat Bagus'
              ][_rating],
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          TextField(
              controller: _comment,
              maxLength: 500,
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(
                  labelText: 'Komentar')),
          FilledButton(
              onPressed: _loading ? null : _submit,
              child: Text(_loading ? 'Mengirim...' : 'Kirim Ulasan')),
        ]),
      );
}
