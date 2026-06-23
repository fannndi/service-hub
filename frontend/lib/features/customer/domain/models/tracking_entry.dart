import '../../../../core/json_helpers.dart';
import '../../../../core/domain/order_status.dart' show OrderStatus;

class TrackingEntry {
  const TrackingEntry(
      {required this.id,
      required this.status,
      this.note,
      required this.createdAt});
  final String id;
  final OrderStatus status;
  final String? note;
  final DateTime createdAt;

  factory TrackingEntry.fromJson(Map<String, dynamic> json) => TrackingEntry(
        id: readString(json, 'id'),
        status: OrderStatus.fromJson(json['status']),
        note: json['note'] as String?,
        createdAt: dateFromJson(json['created_at'] ?? json['createdAt']) ??
            DateTime.now(),
      );
}
