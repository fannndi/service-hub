import '../../../../core/json_helpers.dart';
import '../../../../core/domain/order_status.dart' show OrderStatus;

class CreateOrderResult {
  const CreateOrderResult(
      {required this.id,
      required this.orderNumber,
      required this.status,
      required this.totalEstimasi,
      required this.isNewCustomer,
      required this.message});
  final String id;
  final String orderNumber;
  final OrderStatus status;
  final double totalEstimasi;
  final bool isNewCustomer;
  final String message;
  factory CreateOrderResult.fromJson(Map<String, dynamic> json) =>
      CreateOrderResult(
        id: readString(json, 'id'),
        orderNumber: readString(json, 'order_number', 'orderNumber'),
        status: OrderStatus.fromJson(json['status']),
        totalEstimasi:
            moneyFromJson(json['total_estimasi'] ?? json['totalEstimasi']),
        isNewCustomer: json['is_new_customer'] as bool? ??
            json['isNewCustomer'] as bool? ??
            false,
        message: readString(json, 'message'),
      );
}
