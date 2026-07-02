import 'api_helper.dart';

class StoreReviewRepository {
  String get storeId => sb.storeId ?? '';

  Future<Map<String, dynamic>> getReviews({int page = 1}) async {
    final items = await sb.from('reviews').select('*, users(full_name), orders!inner(store_id)')
      .eq('orders.store_id', storeId).order('created_at', ascending: false);
    return {'items': items, 'total': (items as List).length};
  }

  Future<void> respondReview(String reviewId, String responseText) async {
    final current = await sb.from('reviews').select('comment').eq('id', reviewId).single();
    final newComment = (current['comment'] as String? ?? '') + '\n\n— Respon toko:\n' + responseText;
    await sb.from('reviews').update({'comment': newComment}).eq('id', reviewId);
  }
}
