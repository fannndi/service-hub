import '../../../core/json_helpers.dart';

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
