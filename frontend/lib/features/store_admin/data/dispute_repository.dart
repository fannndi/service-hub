import 'api_helper.dart';

class StoreDisputeRepository {
  String get storeId => sb.storeId ?? '';

  Future<Map<String, dynamic>> getDisputes({String? status, int page = 1}) async {
    var query = sb.from('disputes').select('*, user:users(full_name, phone_number)')
      .eq('store_id', storeId);
    if (status != null) query = query.eq('status', status);
    final items = await query.order('created_at', ascending: false);
    return {'items': items, 'total': (items as List).length};
  }

  Future<void> resolveDispute(String disputeId, bool accept, String reason) async {
    await sb.invoke('disputes', body: {
      'dispute_id': disputeId,
      'decision': accept ? 'store_accepted' : 'store_rejected',
      'store_response': reason,
    });
  }
}
