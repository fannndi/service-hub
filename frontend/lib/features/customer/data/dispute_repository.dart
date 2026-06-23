import 'api_helper.dart';

class DisputeRepository {
  Future<void> createDispute(String orderId, {required String disputeType, required String description, List<String>? evidenceUrls}) async {
    await sb.from('disputes').insert({
      'order_id': orderId,
      'user_id': sb.user!.id,
      'dispute_type': disputeType,
      'description': description,
      'evidence_urls': evidenceUrls ?? [],
    });
  }
}
