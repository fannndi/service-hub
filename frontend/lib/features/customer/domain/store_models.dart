import '../../../core/json_helpers.dart';
import 'review_models.dart';

class ServiceStore {
  const ServiceStore({
    required this.id,
    required this.storeName,
    required this.address,
    required this.phoneNumber,
    this.ratingAvg = 0,
    this.reviewCount = 0,
    this.verifiedAt,
    this.operationalHours = const {},
    this.reviews = const [],
  });

  final String id;
  final String storeName;
  final String address;
  final String phoneNumber;
  final double ratingAvg;
  final int reviewCount;
  final DateTime? verifiedAt;
  final Map<String, dynamic> operationalHours;
  final List<ReviewItem> reviews;

  factory ServiceStore.fromJson(Map<String, dynamic> json) => ServiceStore(
        id: readString(json, 'id'),
        storeName: readString(json, 'store_name', 'storeName'),
        address: readString(json, 'address'),
        phoneNumber: readString(json, 'phone_number', 'phoneNumber'),
        ratingAvg: moneyFromJson(json['rating_avg'] ?? json['ratingAvg']),
        reviewCount: json['review_count'] as int? ??
            json['reviewCount'] as int? ??
            json['totalReviews'] as int? ??
            0,
        verifiedAt: dateFromJson(json['verified_at'] ?? json['verifiedAt']),
        operationalHours: json['operational_hours'] is Map<String, dynamic>
            ? json['operational_hours'] as Map<String, dynamic>
            : json['operationalHours'] is Map<String, dynamic>
                ? json['operationalHours'] as Map<String, dynamic>
                : const {},
        reviews: (json['reviews'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(ReviewItem.fromJson)
            .toList(),
      );
}

class StoreMatchResult {
  const StoreMatchResult({
    required this.storeId,
    required this.storeName,
    required this.address,
    required this.phoneNumber,
    required this.ratingAvg,
    required this.totalCompleted,
    required this.spareparts,
    required this.estimatedCost,
  });

  final String storeId;
  final String storeName;
  final String address;
  final String phoneNumber;
  final double ratingAvg;
  final int totalCompleted;
  final List<MatchSparePart> spareparts;
  final double estimatedCost;

  factory StoreMatchResult.fromJson(Map<String, dynamic> json) {
    final sparepartsJson = json['spareparts'] as List? ?? const [];
    return StoreMatchResult(
      storeId: readString(json, 'storeId'),
      storeName: readString(json, 'storeName'),
      address: readString(json, 'address'),
      phoneNumber: readString(json, 'phoneNumber'),
      ratingAvg: (json['ratingAvg'] as num?)?.toDouble() ?? 0,
      totalCompleted: json['totalCompleted'] as int? ?? 0,
      spareparts: sparepartsJson
          .whereType<Map<String, dynamic>>()
          .map(MatchSparePart.fromJson)
          .toList(),
      estimatedCost: moneyFromJson(json['estimatedCost']),
    );
  }
}

class MatchSparePart {
  const MatchSparePart({
    required this.id,
    required this.partName,
    required this.partType,
    required this.price,
    required this.availableQty,
    required this.status,
  });

  final String id;
  final String partName;
  final String partType;
  final double price;
  final int availableQty;
  final String status;

  factory MatchSparePart.fromJson(Map<String, dynamic> json) => MatchSparePart(
        id: readString(json, 'id'),
        partName: readString(json, 'partName'),
        partType: readString(json, 'partType'),
        price: moneyFromJson(json['price']),
        availableQty: json['availableQty'] as int? ?? 0,
        status: readString(json, 'status'),
      );
}
