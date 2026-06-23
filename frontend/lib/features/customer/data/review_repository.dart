import '../domain/customer_models.dart';
import 'api_helper.dart';

class ReviewRepository {
  Future<void> createReview(String orderId, {required int rating, String? comment}) async {
    final order = await sb.from('service_orders').select('store_id').eq('id', orderId).single();
    await sb.from('reviews').insert({
      'order_id': orderId,
      'user_id': sb.user!.id,
      'store_id': order['store_id'],
      'rating': rating,
    });
    await sb.rpc('update_rating_avg', params: {'p_store_id': order['store_id']});
  }

  Future<List<CouponReward>> getCoupons() async {
    final data = await sb.from('coupons').select('*').eq('user_id', sb.user!.id).eq('is_used', false);
    return (data as List).map((json) => CouponReward.fromJson(json)).toList();
  }
}
