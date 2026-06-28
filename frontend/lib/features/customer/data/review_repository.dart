import '../domain/customer_models.dart';
import 'api_helper.dart';

import '../domain/review_models.dart';

class ReviewRepository {
  Future<ReviewResult> createReview(String orderId, {required int rating, String? comment}) async {
    final uid = sb.user?.id;
    if (uid == null) throw Exception('Not authenticated');
    final order = await sb.from('service_orders').select('store_id').eq('id', orderId).eq('user_id', uid).single();
    final data = await sb.from('reviews').insert({
      'order_id': orderId,
      'user_id': uid,
      'store_id': order['store_id'],
      'rating': rating,
      'comment': comment?.isEmpty == true ? null : comment,
    }).select().single();
    await sb.rpc('update_rating_avg', params: {'p_store_id': order['store_id']});
    return ReviewResult(
      review: ReviewItem.fromJson(data),
      coupon: null,
    );
  }

  Future<List<CouponReward>> getCoupons() async {
    final uid = sb.user?.id;
    if (uid == null) throw Exception('Not authenticated');
    final data = await sb.from('coupons').select('*').eq('user_id', uid).eq('is_used', false);
    return (data as List).map((json) => CouponReward.fromJson(json)).toList();
  }
}