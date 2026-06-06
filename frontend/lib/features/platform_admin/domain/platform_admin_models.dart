double moneyParse(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

String strRead(Map<String, dynamic> json, String key, [String? alt]) =>
    (json[key] ?? (alt != null ? json[alt] : null) ?? '').toString();

class AdminSession {
  const AdminSession({required this.id, required this.username, required this.fullName});
  final String id;
  final String username;
  final String fullName;

  factory AdminSession.fromJson(Map<String, dynamic> json) => AdminSession(
        id: strRead(json, 'id'),
        username: strRead(json, 'username'),
        fullName: strRead(json, 'fullName'),
      );
}

class AdminLoginResult {
  const AdminLoginResult({required this.accessToken, required this.admin});
  final String accessToken;
  final AdminSession admin;

  factory AdminLoginResult.fromJson(Map<String, dynamic> json) => AdminLoginResult(
        accessToken: strRead(json, 'accessToken'),
        admin: AdminSession.fromJson((json['admin'] as Map<String, dynamic>?) ?? {}),
      );
}

class StoreListItem {
  const StoreListItem({
    required this.id,
    required this.storeName,
    required this.address,
    required this.phoneNumber,
    this.deviceTypes,
    required this.ratingAvg,
    required this.totalCompleted,
    required this.createdAt,
    required this.admins,
  });
  final String id;
  final String storeName;
  final String address;
  final String phoneNumber;
  final Map<String, dynamic>? deviceTypes;
  final double ratingAvg;
  final int totalCompleted;
  final String createdAt;
  final List<Map<String, dynamic>> admins;

  factory StoreListItem.fromJson(Map<String, dynamic> json) {
    final config = json['config'] as Map<String, dynamic>?;
    return StoreListItem(
      id: strRead(json, 'id'),
      storeName: strRead(json, 'storeName'),
      address: strRead(json, 'address'),
      phoneNumber: strRead(json, 'phoneNumber'),
      deviceTypes: config?['device_types'] as Map<String, dynamic>?,
      ratingAvg: moneyParse(json['ratingAvg']),
      totalCompleted: json['totalCompleted'] as int? ?? 0,
      createdAt: strRead(json, 'createdAt'),
      admins: (json['admins'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>().toList(),
    );
  }
}
