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
        deviceInfo: (json['device_info'] ?? json['deviceInfo']) as Map<String, dynamic>?,
        ipAddress: (json['ip_address'] ?? json['ipAddress']) as String?,
        lastActiveAt: _parseDate(json['last_active_at'] ?? json['lastActiveAt']),
        isActive: (json['is_active'] ?? json['isActive']) == true,
        createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
      );

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }
}
