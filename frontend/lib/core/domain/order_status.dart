/// Canonical OrderStatus enum used across all features.
/// Replaces duplicate definitions in customer_models.dart and store_admin_models.dart.
library;

enum OrderStatus {
  waitingDevice('waiting_device', 'Menunggu Perangkat'),
  deviceReceived('device_received', 'Perangkat Diterima'),
  diagnosing('diagnosing', 'Diagnosa'),
  waitingApproval('waiting_approval', 'Menunggu Persetujuan'),
  waitingSparepart('waiting_sparepart', 'Menunggu Sparepart'),
  repairing('repairing', 'Diperbaiki'),
  qualityCheck('quality_check', 'Quality Check'),
  waitingPayment('waiting_payment', 'Menunggu Pembayaran'),
  completed('completed', 'Selesai'),
  cancelled('cancelled', 'Dibatalkan'),
  disputed('disputed', 'Klaim Garansi');

  const OrderStatus(this.apiValue, this.label);
  final String apiValue;
  final String label;

  bool get isActive => this != completed && this != cancelled;

  static OrderStatus fromJson(Object? value) => OrderStatus.values.firstWhere(
        (item) => item.apiValue == value,
        orElse: () => OrderStatus.waitingDevice,
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

  static PaymentRecordStatus fromJson(Object? value) =>
      PaymentRecordStatus.values.firstWhere(
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

  static DisputeStatus fromJson(Object? value) =>
      DisputeStatus.values.firstWhere(
        (item) => item.value == value,
        orElse: () => DisputeStatus.open,
      );
}

/// Generic paginated result.
class PageResult<T> {
  const PageResult({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });
  final List<T> items;
  final int page;
  final int limit;
  final int total;
}
