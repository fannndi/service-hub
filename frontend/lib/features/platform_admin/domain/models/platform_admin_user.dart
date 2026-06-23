import '../../../../core/json_helpers.dart';

class PlatformAdminUser {
  PlatformAdminUser({required this.id, required this.username, required this.fullName});
  final String id;
  final String username;
  final String fullName;

  factory PlatformAdminUser.fromJson(Map<String, dynamic> json) => PlatformAdminUser(
    id: readString(json, 'id'),
    username: readString(json, 'username'),
    fullName: readString(json, 'fullName'),
  );
}
