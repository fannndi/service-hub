import '../../../../core/json_helpers.dart';

class TrackingEvent {
  const TrackingEvent(
      {required this.id,
      required this.title,
      required this.note,
      required this.status,
      required this.createdAt});
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
