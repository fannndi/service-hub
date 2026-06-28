import '../../../../core/json_helpers.dart';

class StoreListItem {
  const StoreListItem({
    required this.id,
    required this.storeName,
    required this.address,
    required this.phoneNumber,
    this.deviceTypes,
    required this.ratingAvg,
    required this.totalCompleted,
    required this.createdAt,
    required this.admins,
  });
  final String id;
  final String storeName;
  final String address;
  final String phoneNumber;
  final Map<String, dynamic>? deviceTypes;
  final double ratingAvg;
  final int totalCompleted;
  final String createdAt;
  final List<Map<String, dynamic>> admins;

  factory StoreListItem.fromJson(Map<String, dynamic> json) {
    final config = json['config'] as Map<String, dynamic>?;
    return StoreListItem(
      id: readString(json, 'id'),
      storeName: readString(json, 'store_name', 'storeName'),
      address: readString(json, 'address'),
      phoneNumber: readString(json, 'phone_number', 'phoneNumber'),
      deviceTypes: config?['device_types'] as Map<String, dynamic>?,
      ratingAvg: moneyFromJson(json['ratingAvg'] ?? json['rating_avg']),
      totalCompleted: (json['totalCompleted'] ?? json['total_completed'] ?? 0) as int,
      createdAt: readString(json, 'created_at', 'createdAt'),
      admins: (json['admins'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList(),
    );
  }
}
