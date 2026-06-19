import '../../../core/json_helpers.dart';

class ReviewItem {
  const ReviewItem(
      {required this.id,
      required this.customerName,
      required this.rating,
      required this.comment,
      required this.createdAt,
      this.response});
  final String id;
  final String customerName;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final String? response;
  factory ReviewItem.fromJson(Map<String, dynamic> json) => ReviewItem(
        id: jsonString(json['id']),
        customerName: jsonString(json['customerName'] ?? json['customer_name'],
            fallback: 'Pelanggan'),
        rating: jsonInt(json['rating']),
        comment: jsonString(json['comment']),
        createdAt: jsonDate(json['createdAt'] ?? json['created_at']),
        response: json['response'] as String?,
      );
}
