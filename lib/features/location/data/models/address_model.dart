
class AddressModel {
  final String? id;
  final String addressName;
  final String country;
  final String city;
  final String area;
  final String streetChoice;
  final String buildingDetail;
  final double? lat;
  final double? lng;
  final bool isDefault;

  AddressModel({
    this.id,
    required this.addressName,
    required this.country,
    required this.city,
    required this.area,
    required this.streetChoice,
    required this.buildingDetail,
    this.lat,
    this.lng,
    this.isDefault = false,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    // السيرفر يخزن الإحداثيات في location.coordinates
    List<dynamic>? coordinates = json['location']?['coordinates'];

    return AddressModel(
      id: json['_id'],
      addressName: json['name'] ?? '',
      country: json['country'] ?? '',
      city: json['city'] ?? '',
      // الربط مع area و building حسب طلب السيرفر
      area: json['area'] ?? json['zone'] ?? '',
      streetChoice: json['street'] ?? '',
      buildingDetail: json['building'] ?? json['buildingNumber'] ?? '',
      isDefault: json['isDefault'] ?? false,
      lng: coordinates != null && coordinates.length >= 2
          ? (coordinates[0] as num).toDouble()
          : null,
      lat: coordinates != null && coordinates.length >= 2
          ? (coordinates[1] as num).toDouble()
          : null,
    );
  }

  /// هل يحمل العنوان إحداثيات حقيقية يصحّ التوصيل إليها؟
  ///
  /// تُفحص قبل تأكيد الطلب: العنوان بلا إحداثيات لا يُرسَل أصلاً.
  bool get hasCoordinates => lat != null && lng != null;

  /// حمولة العنوان في طلب `POST /api/user/order` — الاستعمال الوحيد لها.
  ///
  /// كانت تضع إحداثيات دمشق `[36.2833, 33.5101]` بديلاً عند غياب الموقع.
  /// وهي إحداثيات صالحة شكلاً، فكانت تعبر تحقّق الباك من الإحداثيات وتُنشئ
  /// طلباً يظنّ السائق أن وجهته وسط دمشق. الآن يُحذف الحقلان عند الغياب،
  /// فيردّ الباك 400 `invalidDeliveryAddress` — وهو الرفض الذي صُمِّم له.
  Map<String, dynamic> toJson() {
    return {
      "name": addressName,
      "fullAddress": "$city, $area, $streetChoice, $buildingDetail",

      // تحويل النص إلى كود الدولة الذي يقبله السيرفر
      "country": (country.contains("Syria") || country.contains("سوريا") || country.isEmpty)
          ? "SY"
          : country,

      "city": city,
      "area": area,
      "street": streetChoice,
      "building": buildingDetail,

      if (hasCoordinates) ...{
        // GeoJSON: الـ Longitude أولاً ثم الـ Latitude
        "location": {
          "type": "Point",
          "coordinates": [lng, lat],
        },
        // نبقي هذين الحقلين أيضاً لضمان التوافق مع أي دوال أخرى في السيرفر
        "lat": lat,
        "lng": lng,
      },

      "isDefault": isDefault,
    };
  }
}