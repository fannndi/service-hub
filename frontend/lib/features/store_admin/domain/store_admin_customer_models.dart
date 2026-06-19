import '../../../core/json_helpers.dart';

class CustomerProfile {
  const CustomerProfile(
      {required this.id,
      required this.name,
      required this.phone,
      required this.totalOrders,
      required this.totalSpent});
  final String id;
  final String name;
  final String phone;
  final int totalOrders;
  final num totalSpent;
  factory CustomerProfile.fromJson(Map<String, dynamic> json) =>
      CustomerProfile(
        id: jsonString(json['id']),
        name: jsonString(json['fullName'] ?? json['full_name'] ?? json['name'],
            fallback: 'Pelanggan'),
        phone: jsonString(json['phoneNumber'] ?? json['phone_number']),
        totalOrders: jsonInt(json['totalOrders'] ?? json['total_orders']),
        totalSpent: jsonNum(json['totalSpent'] ?? json['total_spent']),
      );
}
