enum StoreOrderStatus {
  waitingDevice('waiting_device', 'Menunggu Device'),
  deviceReceived('device_received', 'Device Diterima'),
  diagnosing('diagnosing', 'Diagnosa'),
  waitingApproval('waiting_approval', 'Menunggu Approval'),
  waitingSparepart('waiting_sparepart', 'Menunggu Sparepart'),
  repairing('repairing', 'Perbaikan'),
  qualityCheck('quality_check', 'Quality Check'),
  waitingPayment('waiting_payment', 'Menunggu Bayar'),
  completed('completed', 'Selesai'),
  cancelled('cancelled', 'Dibatalkan'),
  disputed('disputed', 'Dispute');

  const StoreOrderStatus(this.value, this.label);
  final String value;
  final String label;

  static StoreOrderStatus fromJson(Object? value) => StoreOrderStatus.values.firstWhere(
        (item) => item.value == value,
        orElse: () => StoreOrderStatus.waitingDevice,
      );
}

enum PaymentRecordStatus {
  pending('pending', 'Pending'),
  confirmed('confirmed', 'Terkonfirmasi'),
  failed('failed', 'Gagal'),
  refunded('refunded', 'Refund');

  const PaymentRecordStatus(this.value, this.label);
  final String value;
  final String label;

  static PaymentRecordStatus fromJson(Object? value) => PaymentRecordStatus.values.firstWhere(
        (item) => item.value == value,
        orElse: () => PaymentRecordStatus.pending,
      );
}

enum DisputeStatus {
  open('open', 'Open'),
  storeAccepted('store_accepted', 'Diterima Toko'),
  storeRejected('store_rejected', 'Ditolak Toko'),
  escalated('escalated', 'Eskalasi'),
  resolved('resolved', 'Selesai'),
  closed('closed', 'Ditutup');

  const DisputeStatus(this.value, this.label);
  final String value;
  final String label;

  static DisputeStatus fromJson(Object? value) => DisputeStatus.values.firstWhere(
        (item) => item.value == value,
        orElse: () => DisputeStatus.open,
      );
}

class StoreAdminSession {
  const StoreAdminSession({
    required this.adminId,
    required this.adminName,
    required this.phoneNumber,
    required this.storeId,
    required this.storeName,
    required this.isFirstLogin,
  });

  final String adminId;
  final String adminName;
  final String phoneNumber;
  final String storeId;
  final String storeName;
  final bool isFirstLogin;

  factory StoreAdminSession.fromJson(Map<String, dynamic> json) {
    final admin = _map(json['store_admin']) ?? json;
    return StoreAdminSession(
      adminId: _string(admin['id']),
      adminName: _string(admin['full_name'] ?? admin['fullName'] ?? admin['name'], fallback: 'Admin Toko'),
      phoneNumber: _string(admin['phone_number'] ?? admin['phoneNumber']),
      storeId: _string(admin['store_id'] ?? admin['storeId'] ?? json['storeId']),
      storeName: _string(admin['store_name'] ?? admin['storeName'] ?? json['storeName'], fallback: 'Toko Servis'),
      isFirstLogin: _bool(admin['is_first_login'] ?? admin['isFirstLogin']),
    );
  }

  Map<String, String> toStorage() => {
        'adminId': adminId,
        'adminName': adminName,
        'phoneNumber': phoneNumber,
        'storeId': storeId,
        'storeName': storeName,
        'isFirstLogin': isFirstLogin.toString(),
      };

  factory StoreAdminSession.fromStorage(Map<String, String?> values) => StoreAdminSession(
        adminId: values['adminId'] ?? '',
        adminName: values['adminName'] ?? 'Admin Toko',
        phoneNumber: values['phoneNumber'] ?? '',
        storeId: values['storeId'] ?? '',
        storeName: values['storeName'] ?? 'Toko Servis',
        isFirstLogin: values['isFirstLogin'] == 'true',
      );

  StoreAdminSession copyWith({bool? isFirstLogin}) => StoreAdminSession(
        adminId: adminId,
        adminName: adminName,
        phoneNumber: phoneNumber,
        storeId: storeId,
        storeName: storeName,
        isFirstLogin: isFirstLogin ?? this.isFirstLogin,
      );
}

class DashboardSummary {
  const DashboardSummary({
    required this.adminName,
    required this.storeName,
    required this.ratingAvg,
    required this.todayOrders,
    required this.activeOrders,
    required this.pendingOrders,
    required this.customers,
    required this.pendingPayments,
    required this.waitingApproval,
    required this.activeDisputes,
    required this.revenueToday,
    required this.revenueMonth,
    required this.completionRate,
    required this.statusBreakdown,
    required this.revenueTrend,
    required this.ordersTrend,
    required this.serviceCategories,
    required this.sparepartConsumption,
    required this.recentOrders,
  });

  final String adminName;
  final String storeName;
  final double ratingAvg;
  final int todayOrders;
  final int activeOrders;
  final int pendingOrders;
  final int customers;
  final int pendingPayments;
  final int waitingApproval;
  final int activeDisputes;
  final num revenueToday;
  final num revenueMonth;
  final double completionRate;
  final Map<String, int> statusBreakdown;
  final List<MetricPoint> revenueTrend;
  final List<MetricPoint> ordersTrend;
  final List<CategoryMetric> serviceCategories;
  final List<CategoryMetric> sparepartConsumption;
  final List<StoreOrder> recentOrders;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) => DashboardSummary(
        adminName: _string(json['adminName'] ?? json['admin_name'], fallback: 'Admin Toko'),
        storeName: _string(json['storeName'] ?? json['store_name'], fallback: 'Toko Servis'),
        ratingAvg: _double(json['ratingAvg'] ?? json['rating_avg']),
        todayOrders: _int(json['todayOrders'] ?? json['today_orders']),
        activeOrders: _int(json['activeOrders'] ?? json['active_orders'] ?? json['active']),
        pendingOrders: _int(json['pendingOrders'] ?? json['pending_orders'] ?? json['pending']),
        customers: _int(json['customers'] ?? json['customer_count']),
        pendingPayments: _int(json['pendingPayments'] ?? json['pending_payments']),
        waitingApproval: _int(json['waitingApproval'] ?? json['waiting_approval']),
        activeDisputes: _int(json['activeDisputes'] ?? json['active_disputes'] ?? json['disputes']),
        revenueToday: _num(json['revenueToday'] ?? json['revenue_today']),
        revenueMonth: _num(json['revenueMonth'] ?? json['revenue_month']),
        completionRate: _double(json['completionRate'] ?? json['completion_rate']),
        statusBreakdown: _intMap(json['statusBreakdown'] ?? json['status_breakdown']),
        revenueTrend: _list(json['revenueTrend'] ?? json['revenue_trend']).map(MetricPoint.fromJson).toList(),
        ordersTrend: _list(json['ordersTrend'] ?? json['orders_trend']).map(MetricPoint.fromJson).toList(),
        serviceCategories: _list(json['serviceCategories'] ?? json['service_categories']).map(CategoryMetric.fromJson).toList(),
        sparepartConsumption: _list(json['sparepartConsumption'] ?? json['sparepart_consumption']).map(CategoryMetric.fromJson).toList(),
        recentOrders: _list(json['recentOrders'] ?? json['recent_orders']).map(StoreOrder.fromJson).toList(),
      );

  factory DashboardSummary.empty(StoreAdminSession? session) => DashboardSummary(
        adminName: session?.adminName ?? 'Admin Toko',
        storeName: session?.storeName ?? 'Toko Servis',
        ratingAvg: 0,
        todayOrders: 0,
        activeOrders: 0,
        pendingOrders: 0,
        customers: 0,
        pendingPayments: 0,
        waitingApproval: 0,
        activeDisputes: 0,
        revenueToday: 0,
        revenueMonth: 0,
        completionRate: 0,
        statusBreakdown: const {},
        revenueTrend: const [],
        ordersTrend: const [],
        serviceCategories: const [],
        sparepartConsumption: const [],
        recentOrders: const [],
      );
}

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
    final user = _map(json['user'] ?? json['customer']) ?? const {};
    final device = _map(json['device']) ?? const {};
    return StoreOrder(
      id: _string(json['id']),
      orderNumber: _string(json['orderNumber'] ?? json['order_number'], fallback: '-'),
      customerName: _string(user['fullName'] ?? user['full_name'] ?? json['customerName'], fallback: 'Pelanggan'),
      customerPhone: _string(user['phoneNumber'] ?? user['phone_number'] ?? json['customerPhone']),
      deviceName: _string(json['deviceName'] ?? json['device_name'] ?? device['model'] ?? json['deviceModel'], fallback: 'Device'),
      status: StoreOrderStatus.fromJson(json['status']),
      paymentStatus: _string(json['paymentStatus'] ?? json['payment_status'], fallback: 'unpaid'),
      createdAt: _date(json['createdAt'] ?? json['created_at']),
      slaDeadline: _dateOrNull(json['slaDeadline'] ?? json['sla_deadline']),
      estimatedTotal: _num(json['estimatedTotal'] ?? json['totalEstimasi'] ?? json['total_estimasi']),
      finalPrice: _num(json['finalPrice'] ?? json['final_price']),
      allowedActions: _stringList(json['allowedActions'] ?? json['allowed_actions']),
      items: _list(json['items']).map(OrderItem.fromJson).toList(),
      payments: _list(json['payments']).map(PaymentRecord.fromJson).toList(),
      trackingEvents: _list(json['trackingEvents'] ?? json['tracking_events'] ?? json['timeline']).map(TrackingEvent.fromJson).toList(),
      credentialPanel: _map(json['credentialPanel'] ?? json['credential_panel']) == null ? null : CredentialPanel.fromJson(_map(json['credentialPanel'] ?? json['credential_panel'])!),
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
        id: _string(json['id']),
        serviceType: _string(json['serviceType'] ?? json['service_type'], fallback: 'Service'),
        complaint: _string(json['complaint'] ?? json['description']),
        sparepartName: _string(json['sparepartName'] ?? json['sparepart_name'], fallback: '-'),
        price: _num(json['itemPrice'] ?? json['item_price'] ?? json['price']),
        status: _string(json['status'], fallback: 'pending'),
      );
}

class Sparepart {
  const Sparepart({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.qty,
    required this.qtyReserved,
    required this.status,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String description;
  final num price;
  final int qty;
  final int qtyReserved;
  final String status;
  final String? imageUrl;
  int get availableStock => qty - qtyReserved;
  bool get isLowStock => availableStock <= 2;

  factory Sparepart.fromJson(Map<String, dynamic> json) => Sparepart(
        id: _string(json['id']),
        name: _string(json['name'], fallback: 'Sparepart'),
        description: _string(json['description']),
        price: _num(json['price']),
        qty: _int(json['qty']),
        qtyReserved: _int(json['qtyReserved'] ?? json['qty_reserved']),
        status: _string(json['status'], fallback: 'available'),
        imageUrl: json['imageUrl'] as String? ?? json['image_url'] as String?,
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
        id: _string(json['id']),
        amount: _num(json['amount']),
        method: _string(json['paymentMethod'] ?? json['payment_method'], fallback: 'transfer_bank'),
        status: PaymentRecordStatus.fromJson(json['status']),
        createdAt: _date(json['createdAt'] ?? json['created_at']),
        proofUrl: json['proofUrl'] as String? ?? json['proof_url'] as String?,
      );
}

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
    final order = _map(json['order']) ?? const {};
    final user = _map(json['user'] ?? json['customer']) ?? const {};
    return DisputeCase(
      id: _string(json['id']),
      orderId: _string(json['orderId'] ?? json['order_id']),
      orderNumber: _string(order['orderNumber'] ?? order['order_number'] ?? json['orderNumber'], fallback: '-'),
      customerName: _string(user['fullName'] ?? user['full_name'] ?? json['customerName'], fallback: 'Pelanggan'),
      type: _string(json['disputeType'] ?? json['dispute_type'], fallback: 'warranty_claim'),
      description: _string(json['description']),
      status: DisputeStatus.fromJson(json['status']),
      createdAt: _date(json['createdAt'] ?? json['created_at']),
    );
  }
}

class ReviewItem {
  const ReviewItem({required this.id, required this.customerName, required this.rating, required this.comment, required this.createdAt, this.response});
  final String id;
  final String customerName;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final String? response;
  factory ReviewItem.fromJson(Map<String, dynamic> json) => ReviewItem(
        id: _string(json['id']),
        customerName: _string(json['customerName'] ?? json['customer_name'], fallback: 'Pelanggan'),
        rating: _int(json['rating']),
        comment: _string(json['comment']),
        createdAt: _date(json['createdAt'] ?? json['created_at']),
        response: json['response'] as String?,
      );
}

class NotificationItem {
  const NotificationItem({required this.id, required this.title, required this.message, required this.createdAt, required this.isRead});
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  factory NotificationItem.fromJson(Map<String, dynamic> json) => NotificationItem(
        id: _string(json['id']),
        title: _string(json['title'], fallback: 'Notifikasi'),
        message: _string(json['message']),
        createdAt: _date(json['createdAt'] ?? json['created_at']),
        isRead: _bool(json['isRead'] ?? json['is_read']),
      );
}

class CustomerProfile {
  const CustomerProfile({required this.id, required this.name, required this.phone, required this.totalOrders, required this.totalSpent});
  final String id;
  final String name;
  final String phone;
  final int totalOrders;
  final num totalSpent;
  factory CustomerProfile.fromJson(Map<String, dynamic> json) => CustomerProfile(
        id: _string(json['id']),
        name: _string(json['fullName'] ?? json['full_name'] ?? json['name'], fallback: 'Pelanggan'),
        phone: _string(json['phoneNumber'] ?? json['phone_number']),
        totalOrders: _int(json['totalOrders'] ?? json['total_orders']),
        totalSpent: _num(json['totalSpent'] ?? json['total_spent']),
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
        id: _string(json['id']),
        title: _string(json['title'], fallback: 'Update'),
        note: _string(json['note'] ?? json['description']),
        status: _string(json['status']),
        createdAt: _date(json['createdAt'] ?? json['created_at']),
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
        isNewCustomer: _bool(json['isNewCustomer'] ?? json['is_new_customer']),
        phoneNumber: _string(json['phoneNumber'] ?? json['phone_number']),
        password: json['password'] as String? ?? json['credential'] as String?,
        expiresAt: _dateOrNull(json['expiresAt'] ?? json['expires_at']),
        sentAt: _dateOrNull(json['sentAt'] ?? json['sent_at']),
      );
}

class MetricPoint {
  const MetricPoint(this.label, this.value);
  final String label;
  final num value;
  factory MetricPoint.fromJson(Map<String, dynamic> json) => MetricPoint(_string(json['label'] ?? json['date']), _num(json['value'] ?? json['total']));
}

class CategoryMetric {
  const CategoryMetric(this.label, this.value);
  final String label;
  final num value;
  factory CategoryMetric.fromJson(Map<String, dynamic> json) => CategoryMetric(_string(json['label'] ?? json['name']), _num(json['value'] ?? json['count']));
}

class PageResult<T> {
  const PageResult({required this.items, required this.page, required this.limit, required this.total});
  final List<T> items;
  final int page;
  final int limit;
  final int total;
}

Map<String, dynamic>? _map(Object? value) => value is Map ? value.cast<String, dynamic>() : null;
List<Map<String, dynamic>> _list(Object? value) => value is List ? value.whereType<Map>().map((item) => item.cast<String, dynamic>()).toList() : const [];
String _string(Object? value, {String fallback = ''}) => value?.toString() ?? fallback;
int _int(Object? value) => value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
num _num(Object? value) => value is num ? value : num.tryParse(value?.toString() ?? '') ?? 0;
double _double(Object? value) => value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;
bool _bool(Object? value) => value == true || value?.toString() == 'true';
DateTime _date(Object? value) => DateTime.tryParse(value?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
DateTime? _dateOrNull(Object? value) => value == null ? null : DateTime.tryParse(value.toString());
List<String> _stringList(Object? value) => value is List ? value.map((item) => item.toString()).toList() : const [];
Map<String, int> _intMap(Object? value) => value is Map ? value.map((key, item) => MapEntry(key.toString(), _int(item))) : const {};
