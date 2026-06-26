import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/store_admin_providers.dart';
import '../../domain/store_admin_review_models.dart';
import '../../domain/store_admin_models.dart';
import '../widgets/store_admin_widgets.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/supabase_service.dart';
import '../../../../../shared_widgets/formatters.dart';
import '../../../../../ui/theme/app_spacing.dart';
import '../../../../../ui/widgets/modern_card.dart';
import 'package:m3_expressive/m3_expressive.dart';

class ReviewsScreen extends ConsumerWidget {
  const ReviewsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(reviewsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.reviewMonitoring)),
      body: value.when(
        loading: () => const Center(child: M3LoadingIndicator()),
        error: (e, _) => ErrorPanel(message: e.toString()),
        data: (page) {
          final reviews = page
              .whereType<Map<String, dynamic>>()
              .map(ReviewItem.fromJson)
              .toList();
          return ListView(
            children: [
              for (final r in reviews)
                _ReviewCard(review: r),
            ],
          );
        },
      ),
    );
  }
}

class _ReviewCard extends ConsumerStatefulWidget {
  const _ReviewCard({required this.review});
  final ReviewItem review;
  @override
  ConsumerState<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends ConsumerState<_ReviewCard> {
  final _replyCtl = TextEditingController();
  bool _replying = false;
  bool _loading = false;

  @override
  void dispose() {
    _replyCtl.dispose();
    super.dispose();
  }

  Future<void> _sendReply(String reviewId) async {
    setState(() => _loading = true);
    try {
      await SupabaseService.instance.from('reviews').update({'store_response': _replyCtl.text.trim()}).eq('id', reviewId);
      ref.invalidate(reviewsProvider);
      setState(() { _replying = false; _replyCtl.clear(); });
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.review;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ModernCard(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(r.customerName, style: const TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('${r.rating}/5', style: const TextStyle(color: Colors.amber)),
          ]),
          if (r.comment.isNotEmpty) Text(r.comment),
          Text(dateText(r.createdAt), style: Theme.of(context).textTheme.bodySmall),
          if (r.response != null && r.response!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(context.l10n.reply.replaceFirst('{text}', r.response ?? ''),
                  style: TextStyle(color: Theme.of(context).colorScheme.primary)),
            ),
          if (r.response == null || r.response!.isEmpty)
            _replying
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(children: [
                      TextField(controller: _replyCtl, maxLines: 2,
                        decoration: const InputDecoration(hintText: 'Tulis balasan...', isDense: true),
                      ),
                      const SizedBox(height: 4),
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        TextButton(onPressed: () => setState(() => _replying = false), child: const Text('Batal')),
                        const SizedBox(width: 8),
                        FilledButton(onPressed: _loading ? null : () => _sendReply(r.id), child: Text(_loading ? '...' : 'Balas')),
                      ]),
                    ]),
                  )
                : TextButton.icon(
                    onPressed: () => setState(() => _replying = true),
                    icon: const Icon(Icons.reply, size: 16),
                    label: const Text('Balas'),
                  ),
        ]),
      ),
    );
  }
}
