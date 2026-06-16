import '../../../core/json_helpers.dart';

class ReviewItem {
  const ReviewItem({required this.id, required this.rating, this.comment, this.customerName, required this.createdAt});
  final String id;
  final int rating;
  final String? comment;
  final String? customerName;
  final DateTime createdAt;
  factory ReviewItem.fromJson(Map<String, dynamic> json) => ReviewItem(
        id: readString(json, 'id'),
        rating: json['rating'] as int? ?? 0,
        comment: json['comment'] as String?,
        customerName: json['customer_name'] as String? ?? json['customerName'] as String?,
        createdAt: dateFromJson(json['created_at'] ?? json['createdAt']) ?? DateTime.now(),
      );
}

class CouponReward {
  const CouponReward({required this.code, required this.amount, required this.expiredAt});
  final String code;
  final double amount;
  final DateTime expiredAt;
  factory CouponReward.fromJson(Map<String, dynamic> json) => CouponReward(
        code: readString(json, 'code'),
        amount: moneyFromJson(json['amount']),
        expiredAt: dateFromJson(json['expired_at'] ?? json['expiredAt']) ?? DateTime.now(),
      );
}

class ReviewResult {
  const ReviewResult({required this.review, this.coupon});
  final ReviewItem review;
  final CouponReward? coupon;
  factory ReviewResult.fromJson(Map<String, dynamic> json) => ReviewResult(
        review: ReviewItem.fromJson(json['review'] as Map<String, dynamic>),
        coupon: json['coupon'] is Map<String, dynamic> ? CouponReward.fromJson(json['coupon'] as Map<String, dynamic>) : null,
      );
}
