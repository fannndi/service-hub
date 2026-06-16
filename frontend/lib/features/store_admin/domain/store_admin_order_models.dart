import '../../../core/json_helpers.dart';
import 'store_admin_enums.dart';

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
      orderNumber: jsonString(json['orderNumber'] ?? json['order_number'], fallback: '-'),
      customerName: jsonString(user['fullName'] ?? user['full_name'] ?? json['customerName'], fallback: 'Pelanggan'),
      customerPhone: jsonString(user['phoneNumber'] ?? user['phone_number'] ?? json['customerPhone']),
      deviceName: jsonString(json['deviceName'] ?? json['device_name'] ?? device['model'] ?? json['deviceModel'], fallback: 'Device'),
      status: StoreOrderStatus.fromJson(json['status']),
      paymentStatus: jsonString(json['paymentStatus'] ?? json['payment_status'], fallback: 'unpaid'),
      createdAt: jsonDate(json['createdAt'] ?? json['created_at']),
      slaDeadline: jsonDateOrNull(json['slaDeadline'] ?? json['sla_deadline']),
      estimatedTotal: jsonNum(json['estimatedTotal'] ?? json['totalEstimasi'] ?? json['total_estimasi']),
      finalPrice: jsonNum(json['finalPrice'] ?? json['final_price']),
      allowedActions: jsonStringList(json['allowedActions'] ?? json['allowed_actions']),
      items: jsonList(json['items']).map(OrderItem.fromJson).toList(),
      payments: jsonList(json['payments']).map(PaymentRecord.fromJson).toList(),
      trackingEvents: jsonList(json['trackingEvents'] ?? json['tracking_events'] ?? json['timeline']).map(TrackingEvent.fromJson).toList(),
      credentialPanel: jsonMap(json['credentialPanel'] ?? json['credential_panel']) == null ? null : CredentialPanel.fromJson(jsonMap(json['credentialPanel'] ?? json['credential_panel'])!),
      deliveryAddress: json['deliveryAddress'] as String? ?? json['delivery_address'] as String?,
    );
  }
}

class OrderItem {
  const OrderItem({required this.id, required this.serviceType, required this.complaint, required this.sparepartName, required this.price, required this.status});
  final String id;
  final String serviceType;
  final String complaint;
  final String sparepartName;
  final num price;
  final String status;

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        id: jsonString(json['id']),
        serviceType: jsonString(json['serviceType'] ?? json['service_type'], fallback: 'Service'),
        complaint: jsonString(json['complaint'] ?? json['description']),
        sparepartName: jsonString(json['sparepartName'] ?? json['sparepart_name'], fallback: '-'),
        price: jsonNum(json['itemPrice'] ?? json['item_price'] ?? json['price']),
        status: jsonString(json['status'], fallback: 'pending'),
      );
}

class PaymentRecord {
  const PaymentRecord({required this.id, required this.amount, required this.method, required this.status, required this.createdAt, this.proofUrl});
  final String id;
  final num amount;
  final String method;
  final PaymentRecordStatus status;
  final DateTime createdAt;
  final String? proofUrl;

  factory PaymentRecord.fromJson(Map<String, dynamic> json) => PaymentRecord(
        id: jsonString(json['id']),
        amount: jsonNum(json['amount']),
        method: jsonString(json['paymentMethod'] ?? json['payment_method'], fallback: 'transfer_bank'),
        status: PaymentRecordStatus.fromJson(json['status']),
        createdAt: jsonDate(json['createdAt'] ?? json['created_at']),
        proofUrl: json['proofUrl'] as String? ?? json['proof_url'] as String?,
      );
}

class TrackingEvent {
  const TrackingEvent({required this.id, required this.title, required this.note, required this.status, required this.createdAt});
  final String id;
  final String title;
  final String note;
  final String status;
  final DateTime createdAt;
  factory TrackingEvent.fromJson(Map<String, dynamic> json) => TrackingEvent(
        id: jsonString(json['id']),
        title: jsonString(json['title'], fallback: 'Update'),
        note: jsonString(json['note'] ?? json['description']),
        status: jsonString(json['status']),
        createdAt: jsonDate(json['createdAt'] ?? json['created_at']),
      );
}

class CredentialPanel {
  const CredentialPanel({required this.isNewCustomer, required this.phoneNumber, required this.password, this.expiresAt, this.sentAt});
  final bool isNewCustomer;
  final String phoneNumber;
  final String? password;
  final DateTime? expiresAt;
  final DateTime? sentAt;
  bool get hasCredential => password != null && password!.isNotEmpty;

  factory CredentialPanel.fromJson(Map<String, dynamic> json) => CredentialPanel(
        isNewCustomer: jsonBool(json['isNewCustomer'] ?? json['is_new_customer']),
        phoneNumber: jsonString(json['phoneNumber'] ?? json['phone_number']),
        password: json['password'] as String? ?? json['credential'] as String?,
        expiresAt: jsonDateOrNull(json['expiresAt'] ?? json['expires_at']),
        sentAt: jsonDateOrNull(json['sentAt'] ?? json['sent_at']),
      );
}
