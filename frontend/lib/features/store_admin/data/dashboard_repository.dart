import '../domain/store_admin_models.dart';
import 'api_helper.dart';

class StoreDashboardRepository {
  String get storeId => sb.storeId ?? '';

  Future<DashboardSummary> getDashboardSummary() async {
    final data = await sb.client.rpc('get_dashboard_summary', params: {'p_store_id': storeId});
    if (data is! Map<String, dynamic>) throw Exception('Invalid response');
    return DashboardSummary.fromJson(data);
  }

  Future<Map<String, dynamic>> getAnalytics() async {
    final data = await sb.client.rpc('get_analytics', params: {'p_store_id': storeId});
    if (data is! Map<String, dynamic>) throw Exception('Invalid response');
    return data;
  }
}