import '../../../../core/json_helpers.dart';

class AdminSession {
  const AdminSession(
      {required this.id, required this.username, required this.fullName});
  final String id;
  final String username;
  final String fullName;

  factory AdminSession.fromJson(Map<String, dynamic> json) => AdminSession(
        id: readString(json, 'id'),
        username: readString(json, 'username'),
        fullName: readString(json, 'fullName'),
      );
}
