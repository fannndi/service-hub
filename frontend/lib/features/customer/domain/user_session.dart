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
        id: json['id'] as String,
        deviceInfo: json['deviceInfo'] as Map<String, dynamic>?,
        ipAddress: json['ipAddress'] as String?,
        lastActiveAt: DateTime.parse(json['lastActiveAt'] as String),
        isActive: json['isActive'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
