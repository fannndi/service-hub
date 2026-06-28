import 'api_helper.dart';

class DisputeRepository {
  Future<void> createDispute(String orderId, {required String disputeType, required String description, List<String>? evidenceUrls}) async {
    final uid = sb.user?.id;
    if (uid == null) throw Exception('Not authenticated');
    await sb.from('disputes').insert({
      'order_id': orderId,
      'user_id': uid,
      'dispute_type': disputeType,
      'description': description,
      'evidence_urls': evidenceUrls ?? [],
    });
  }
}