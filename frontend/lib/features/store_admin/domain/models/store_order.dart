import '../../../../core/json_helpers.dart';
import '../store_admin_enums.dart';
import 'order_item.dart';
import 'payment_record.dart';
import 'tracking_event.dart';
import 'credential_panel.dart';

class StoreOrder {
  const StoreOrder({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.customerPhone,
    required this.deviceName,
    required this.status,
    required this.paymentStatus,
    required this.createdAt,
    required this.estimatedTotal,
    required this.finalPrice,
    required this.allowedActions,
    required this.items,
    required this.payments,
    required this.trackingEvents,
    this.slaDeadline,
    this.credentialPanel,
    this.deliveryAddress,
  });

  final String id;
  final String orderNumber;
  final String customerName;
  final String customerPhone;
  final String deviceName;
  final StoreOrderStatus status;
  final String paymentStatus;
  final DateTime createdAt;
  final DateTime? slaDeadline;
  final num estimatedTotal;
  final num finalPrice;
  final List<String> allowedActions;
  final List<OrderItem> items;
  final List<PaymentRecord> payments;
  final List<TrackingEvent> trackingEvents;
  final CredentialPanel? credentialPanel;
  final String? deliveryAddress;

  factory StoreOrder.fromJson(Map<String, dynamic> json) {
    final user = jsonMap(json['user'] ?? json['customer']) ?? const {};
    final device = jsonMap(json['device']) ?? const {};
    return StoreOrder(
      id: jsonString(json['id']),
      orderNumber: jsonString(json['orderNumber'] ?? json['order_number'],
          fallback: '-'),
      customerName: jsonString(
          user['fullName'] ?? user['full_name'] ?? json['customerName'],
          fallback: 'Pelanggan'),
      customerPhone: jsonString(
          user['phoneNumber'] ?? user['phone_number'] ?? json['customerPhone']),
      deviceName: jsonString(
          json['deviceName'] ??
              json['device_name'] ??
              device['model'] ??
              json['deviceModel'],
          fallback: 'Device'),
      status: StoreOrderStatus.fromJson(json['status']),
      paymentStatus: jsonString(json['paymentStatus'] ?? json['payment_status'],
          fallback: 'unpaid'),
      createdAt: jsonDate(json['createdAt'] ?? json['created_at']),
      slaDeadline: jsonDateOrNull(json['slaDeadline'] ?? json['sla_deadline']),
      estimatedTotal: jsonNum(json['estimatedTotal'] ??
          json['totalEstimasi'] ??
          json['total_estimasi']),
      finalPrice: jsonNum(json['finalPrice'] ?? json['final_price']),
      allowedActions:
          jsonStringList(json['allowedActions'] ?? json['allowed_actions']),
      items: jsonList(json['items']).map(OrderItem.fromJson).toList(),
      payments: jsonList(json['payments']).map(PaymentRecord.fromJson).toList(),
      trackingEvents: jsonList(json['trackingEvents'] ??
              json['tracking_events'] ??
              json['timeline'])
          .map(TrackingEvent.fromJson)
          .toList(),
      credentialPanel: jsonMap(
                  json['credentialPanel'] ?? json['credential_panel']) ==
              null
          ? null
          : CredentialPanel.fromJson(
              jsonMap(json['credentialPanel'] ?? json['credential_panel'])!),
      deliveryAddress: json['deliveryAddress'] as String? ??
          json['delivery_address'] as String?,
    );
  }
}
