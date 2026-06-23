import '../../../../core/json_helpers.dart';
import 'admin_session.dart';

class AdminLoginResult {
  const AdminLoginResult(
      {required this.accessToken, this.refreshToken, required this.admin});
  final String accessToken;
  final String? refreshToken;
  final AdminSession admin;

  factory AdminLoginResult.fromJson(Map<String, dynamic> json) =>
      AdminLoginResult(
        accessToken: readString(json, 'accessToken'),
        refreshToken: json['refreshToken'] as String?,
        admin: AdminSession.fromJson(
            (json['admin'] as Map<String, dynamic>?) ?? {}),
      );
}
