class UserSession {
  final String id;
  final Map<String, dynamic>? deviceInfo;
  final String? ipAddress;
  final DateTime lastActiveAt;
  final bool isActive;
  final DateTime createdAt;

  const UserSession({
    required this.id,
    this.deviceInfo,
    this.ipAddress,
    required this.lastActiveAt,
    required this.isActive,
    required this.createdAt,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) => UserSession(
        id: (json['id'] ?? '').toString(),
        deviceInfo: json['deviceInfo'] as Map<String, dynamic>?,
        ipAddress: json['ipAddress'] as String?,
        lastActiveAt: _parseDate(json['lastActiveAt']),
        isActive: json['isActive'] == true,
        createdAt: _parseDate(json['createdAt']),
      );

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }
}
