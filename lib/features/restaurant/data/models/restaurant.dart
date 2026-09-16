class Restaurant {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double rating;

  /// المسافة بالكيلومتر — يرسلها الباك **فقط** عندما يتوفّر موقع للمستخدم
  /// (`locationUsed: true`). تبقى null في نتائج البحث وعند غياب الموقع،
  /// ولا يجوز عرض «0 كم» بدلاً منها.
  final double? distance;

  /// عملة المطعم (`SYP` / `EUR`) — تحدّد شكل عرض الأسعار.
  final String? currency;

  /// `open` / `closed` — المطاعم المحجوبة (`blocked`) مستبعدة أصلاً من الباك.
  final String? status;

  Restaurant({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.rating,
    this.distance,
    this.currency,
    this.status,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    String extractUrl(dynamic data) {
      if (data != null && data is Map && data['url'] != null) {
        return data['url'].toString();
      }
      return '';
    }

    String finalUrl = extractUrl(json['image']);
    if (finalUrl.isEmpty) {
      finalUrl = extractUrl(json['img']);
    }

    return Restaurant(
      id: json['_id']?.toString() ?? '',
      name: json['name'] ?? 'No Name',
      description: json['description'] ?? 'Variety',
      imageUrl: finalUrl.isNotEmpty
          ? finalUrl
          : 'https://via.placeholder.com/150',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      distance: (json['distance'] as num?)?.toDouble(),
      currency: json['currency']?.toString(),
      status: json['status']?.toString(),
    );
  }
}
