import '../../../../core/json_helpers.dart';

class NotificationItem {
  const NotificationItem(
      {required this.id,
      required this.title,
      required this.message,
      required this.createdAt,
      required this.isRead,
      this.linkTo});
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String? linkTo;
  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      NotificationItem(
        id: jsonString(json['id']),
        title: jsonString(json['title'], fallback: 'Notifikasi'),
        message: jsonString(json['message']),
        createdAt: jsonDate(json['createdAt'] ?? json['created_at']),
        isRead: jsonBool(json['isRead'] ?? json['is_read']),
        linkTo: jsonString(json['link_to'] ?? json['linkTo'], fallback: '') == '' ? null : jsonString(json['link_to'] ?? json['linkTo']),
      );
}
