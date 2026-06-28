import 'api_helper.dart';

class StoreReviewRepository {
  String get storeId => sb.storeId ?? '';

  Future<Map<String, dynamic>> getReviews({int page = 1}) async {
    final items = await sb.from('reviews').select('*, users(full_name), orders!inner(store_id)')
      .eq('orders.store_id', storeId).order('created_at', ascending: false);
    return {'items': items, 'total': (items as List).length};
  }

  Future<void> respondReview(String reviewId, String response) async {
    await sb.from('reviews').update({'store_response': response}).eq('id', reviewId);
  }
}
