import '../../../core/json_helpers.dart';
import 'store_admin_enums.dart';

class DisputeCase {
  const DisputeCase({required this.id, required this.orderId, required this.orderNumber, required this.customerName, required this.type, required this.description, required this.status, required this.createdAt});
  final String id;
  final String orderId;
  final String orderNumber;
  final String customerName;
  final String type;
  final String description;
  final DisputeStatus status;
  final DateTime createdAt;

  factory DisputeCase.fromJson(Map<String, dynamic> json) {
    final order = jsonMap(json['order']) ?? const {};
    final user = jsonMap(json['user'] ?? json['customer']) ?? const {};
    return DisputeCase(
      id: jsonString(json['id']),
      orderId: jsonString(json['orderId'] ?? json['order_id']),
      orderNumber: jsonString(order['orderNumber'] ?? order['order_number'] ?? json['orderNumber'], fallback: '-'),
      customerName: jsonString(user['fullName'] ?? user['full_name'] ?? json['customerName'], fallback: 'Pelanggan'),
      type: jsonString(json['disputeType'] ?? json['dispute_type'], fallback: 'warranty_claim'),
      description: jsonString(json['description']),
      status: DisputeStatus.fromJson(json['status']),
      createdAt: jsonDate(json['createdAt'] ?? json['created_at']),
    );
  }
}
