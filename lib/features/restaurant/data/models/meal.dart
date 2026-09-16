class Meal {
  final String id;
  final String name;
  final String description;
  final String image;
  final double rating;
  final double time;
  final double price;
  final String restaurantId;
  final String? restaurantName;

  /// عملة المطعم (`SYP` / `EUR`) — تصل عبر `restaurantId` المُوسَّع.
  /// العملة خاصية بيانات لا خاصية لغة: مطعم ألماني يبقى باليورو مهما كانت
  /// لغة الواجهة.
  final String? currency;

  /// القسم العام (Main Category) الذي يديره الأدمن — اختياري في الباك
  /// (`mainCategoryId` قد يكون null).
  final String? mainCategoryId;
  final String? mainCategoryName;

  /// `available` أو `unavailable`. الباك **لا يفلتر** الأصناف غير المتوفرة في
  /// `GET /api/user/food`، فالتخفيت مسؤولية الواجهة.
  final String status;

  final List<String> ingredients; // ✅ أضفنا المكونات الأساسية
  final List<Map<String, dynamic>> extras;
  final List<Map<String, dynamic>> sizes;
  // العروض النشطة المرتبطة بهذا الصنف (type: discount/free_delivery) —
  // تصل من GET /api/user/food/:id أو /api/user/food-in-restaurant/:id.
  final List<Map<String, dynamic>> promotions;

  Meal({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.rating,
    required this.price,
    required this.restaurantId,
    this.restaurantName,
    this.currency,
    this.mainCategoryId,
    this.mainCategoryName,
    this.status = 'available',
    required this.time,
    this.ingredients = const [], // القيمة الافتراضية
    this.extras = const [],
    this.sizes = const [],
    this.promotions = const [],
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    // دالة مساعدة لجلب رابط الصورة من الهيكل { url: "..." }
    String getImageUrl(dynamic imgData) {
      if (imgData != null && imgData is Map && imgData['url'] != null) {
        return imgData['url'].toString();
      }
      return 'https://via.placeholder.com/150';
    }

    // استخراج الـ ID والاسم بذكاء (يدعم الـ Populated Object من الباك أند)
    String resId = '';
    String? resName = json['restaurantName']?.toString();
    String? resCurrency = json['currency']?.toString();

    if (json['restaurantId'] != null) {
      if (json['restaurantId'] is Map) {
        final res = json['restaurantId'] as Map;
        resId = res['_id']?.toString() ?? '';
        resName ??= res['name']?.toString();
        resCurrency ??= res['currency']?.toString();
      } else {
        resId = json['restaurantId'].toString();
      }
    }

    // القسم العام — مُوسَّع في /food، وقد يصل كـ ID مجرّد أو null من مسارات أخرى
    String? mainCatId;
    String? mainCatName;
    final rawMainCategory = json['mainCategoryId'];
    if (rawMainCategory is Map) {
      mainCatId = rawMainCategory['_id']?.toString();
      mainCatName = rawMainCategory['name']?.toString();
    } else if (rawMainCategory != null) {
      mainCatId = rawMainCategory.toString();
    }

    return Meal(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'No Name',
      description: json['description']?.toString() ?? '',
      image: getImageUrl(json['image']),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      time: (json['time'] as num?)?.toDouble() ?? 0.0,
      restaurantId: resId,
      restaurantName: resName,
      currency: resCurrency,
      mainCategoryId: mainCatId,
      mainCategoryName: mainCatName,
      status: json['status']?.toString() ?? 'available',

      // ✅ استخراج المكونات الأساسية بشكل آمن
      ingredients: (json['ingredients'] is List)
          ? List<String>.from(json['ingredients'])
          : [],

      // استخراج الأحجام بشكل آمن
      sizes: (json['sizes'] is List)
          ? List<Map<String, dynamic>>.from(json['sizes'])
          : [],

      // استخراج الإضافات (Extras) بشكل آمن
      extras: (json['extras'] is List)
          ? (json['extras'] as List)
          .map((e) =>
      e is Map ? Map<String, dynamic>.from(e) : <String,
          dynamic>{})
          .where((e) => e.isNotEmpty)
          .toList()
          : [],

      // استخراج العروض النشطة بشكل آمن
      promotions: (json['promotions'] is List)
          ? (json['promotions'] as List)
          .map((p) => p is Map ? Map<String, dynamic>.from(p) : <String,
          dynamic>{})
          .where((p) => p.isNotEmpty)
          .toList()
          : [],
    );
  }

  /// هل الصنف متاح للطلب الآن؟
  bool get isAvailable => status != 'unavailable';

  /// السعر المعروض على البطاقة.
  ///
  /// قاعدة الباك: وجود `sizes` **يُلغي** `price` (السعر يُحسب من الحجم
  /// المختار). لكن `models/food.js` يُبقي `price` حقلاً `required, min: 0`
  /// ولا يُصفّره، فلا يمكن الاستدلال على القاعدة من كون `price == 0`.
  /// لذلك نعتمد وجود `sizes` نفسه، ونعرض **أرخص** حجم لأنه سعر «ابتداءً من»:
  /// ترتيب المصفوفة يتبع إدخال الأدمن ولا يضمن أن الأول هو الأصغر.
  double get displayPrice {
    if (sizes.isNotEmpty) {
      final prices = sizes
          .map((s) => (s['price'] as num?)?.toDouble())
          .whereType<double>();
      if (prices.isNotEmpty) {
        return prices.reduce((a, b) => a < b ? a : b);
      }
    }
    return price;
  }

  // أعلى نسبة خصم نشطة على هذا الصنف حالياً (null إن لم يوجد عرض discount نشط)
  int? get activeDiscountPercent {
    for (final promo in promotions) {
      if (promo['type'] == 'discount' && promo['discountValue'] != null) {
        return (promo['discountValue'] as num).toInt();
      }
    }
    return null;
  }
}
