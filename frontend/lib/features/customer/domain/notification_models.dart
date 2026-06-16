import '../../../core/json_helpers.dart';

class NotificationItem {
  const NotificationItem({required this.id, required this.title, required this.message, required this.createdAt, this.isRead = false});
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  factory NotificationItem.fromJson(Map<String, dynamic> json) => NotificationItem(
        id: readString(json, 'id'),
        title: readString(json, 'title'),
        message: readString(json, 'message'),
        createdAt: dateFromJson(json['created_at'] ?? json['createdAt']) ?? DateTime.now(),
        isRead: json['is_read'] as bool? ?? json['isRead'] as bool? ?? false,
      );
}
