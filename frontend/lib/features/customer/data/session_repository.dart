import 'api_helper.dart';

class SessionRepository {
  Future<List<dynamic>> getSessions() async {
    final uid = sb.user?.id;
    if (uid == null) return [];
    final data = await sb.from('user_sessions').select('*').eq('user_id', uid).order('created_at', ascending: false);
    return data;
  }

  Future<void> revokeSession(String id) async {
    await sb.from('user_sessions').update({'is_active': false}).eq('id', id);
  }

  Future<void> logoutAll() async {
    final uid = sb.user?.id;
    if (uid == null) return;
    await sb.from('user_sessions').update({'is_active': false}).eq('user_id', uid);
  }
}
