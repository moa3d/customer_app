import 'package:easy_localization/easy_localization.dart';

class Offer {
  final String id;
  final String type;
  final int? discountValue;
  final DateTime startDate;
  final DateTime endDate;
  final String country;
  final bool isActive;

  final String foodId;
  final String foodName;
  final String foodImage;
  final double foodPrice;
  final double? foodRating;
  final List<dynamic> foodSizes;

  final String restaurantId;
  final String restaurantName;
  final String? restaurantImage;
  final String? restaurantAddress;

  Offer({
    required this.id,
    required this.type,
    this.discountValue,
    required this.startDate,
    required this.endDate,
    required this.country,
    required this.isActive,
    required this.foodId,
    required this.foodName,
    required this.foodImage,
    required this.foodPrice,
    this.foodRating,
    this.foodSizes = const [],
    required this.restaurantId,
    required this.restaurantName,
    this.restaurantImage,
    this.restaurantAddress,
  });

  /// نفس منطق getImageUrl في meal.dart — الباك يرسل { url, public_id }
  static String _extractUrl(dynamic data) {
    if (data is Map && data['url'] != null) return data['url'].toString();
    if (data is String) return data;
    return '';
  }

  /// address في موديل Restaurant كائن وليس نصاً
  static String? _extractAddress(dynamic data) {
    if (data is Map) {
      final full = data['fullAddress'];
      return full?.toString();
    }
    if (data is String) return data;
    return null;
  }

  factory Offer.fromJson(Map<String, dynamic> json) {
    final food = (json['foodId'] is Map)
        ? Map<String, dynamic>.from(json['foodId'])
        : <String, dynamic>{};
    final restaurant = (food['restaurantId'] is Map)
        ? Map<String, dynamic>.from(food['restaurantId'])
        : <String, dynamic>{};

    return Offer(
      id: json['_id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'discount',
      discountValue: (json['discountValue'] as num?)?.toInt(),
      startDate:
          DateTime.tryParse(json['startDate']?.toString() ?? '') ?? DateTime.now(),
      endDate:
          DateTime.tryParse(json['endDate']?.toString() ?? '') ?? DateTime.now(),
      country: json['country']?.toString() ?? 'ALL',
      isActive: json['isActive'] == null ? true : json['isActive'] == true,
      foodId: food['_id']?.toString() ?? '',
      foodName: food['name']?.toString() ?? '',
      foodImage: _extractUrl(food['image']),
      foodPrice: (food['price'] as num?)?.toDouble() ?? 0.0,
      foodRating: (food['rating'] as num?)?.toDouble(),
      foodSizes: (food['sizes'] is List)
          ? List<dynamic>.from(food['sizes'])
          : const [],
      restaurantId: restaurant['_id']?.toString() ?? '',
      restaurantName: restaurant['name']?.toString() ?? '',
      restaurantImage: () {
        final u = _extractUrl(restaurant['image']);
        return u.isEmpty ? null : u;
      }(),
      restaurantAddress: _extractAddress(restaurant['address']),
    );
  }

  String get discountTag {
    if (type == 'free_delivery') return 'free_delivery'.tr();
    if (discountValue != null) return '$discountValue%';
    return '';
  }

  double get effectivePrice {
    if (foodPrice > 0) return foodPrice;
    if (foodSizes.isNotEmpty) {
      final first = foodSizes[0];
      if (first is Map && first['price'] != null) {
        return (first['price'] as num).toDouble();
      }
    }
    return 0.0;
  }

  Offer copyWith({bool? isActive}) {
    return Offer(
      id: id,
      type: type,
      discountValue: discountValue,
      startDate: startDate,
      endDate: endDate,
      country: country,
      isActive: isActive ?? this.isActive,
      foodId: foodId,
      foodName: foodName,
      foodImage: foodImage,
      foodPrice: foodPrice,
      foodRating: foodRating,
      foodSizes: foodSizes,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      restaurantImage: restaurantImage,
      restaurantAddress: restaurantAddress,
    );
  }
}
