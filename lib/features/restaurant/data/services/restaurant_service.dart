import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';


class RestaurantService {
  final Dio _dio = DioClient().instance;

  // جلب كافة المطاعم - يدعم الإحداثيات والترتيب (الجديد في 1.1)
  //
  // [sort]: 'popular' أو 'rating'. **null يعني حذف البارامتر** وهو ترتيب
  // «الأقرب» الافتراضي في الباك — لا ترسل 'nearest'، فهي قيمة غير معرّفة.
  // [lat]/[lng]: خطة بديلة فقط؛ الباك يفضّل العنوان الافتراضي المحفوظ عليها.
  Future<Response> getAllRestaurants({
    double? lat,
    double? lng,
    String? sort,
    bool forceRefresh = false,
  }) async {
    try {
      return await _dio.get(
        'api/user/restaurant',
        queryParameters: {
          'lat': ?lat,
          'lng': ?lng,
          'sort': ?sort,
        },
        options: forceRefresh ? DioClient.refreshed : DioClient.cached(),
      );
    } on DioException {
      rethrow;
    }
  }

  // جلب كافة الأطعمة - يدعم الإحداثيات والترتيب (الجديد في 1.1)
  //
  // [sort]: كما في getAllRestaurants — null = الأقرب (بلا بارامتر).
  // [mainCategory]: معرّف القسم العام. مدعوم على هذا المسار **فقط**، ولا
  // يوجد ما يقابله في /restaurant.
  Future<Response> getAllFood({
    double? lat,
    double? lng,
    String? sort,
    String? mainCategory,
    bool forceRefresh = false,
  }) async {
    try {
      return await _dio.get(
        'api/user/food',
        queryParameters: {
          'lat': ?lat,
          'lng': ?lng,
          'sort': ?sort,
          'mainCategory': ?mainCategory,
        },
        options: forceRefresh ? DioClient.refreshed : DioClient.cached(),
      );
    } on DioException {
      rethrow;
    }
  }

  // جلب الأقسام العامة — GET /api/user/main-categories
  //
  // بيانات شبه ثابتة يديرها الأدمن، فنُطيل صلاحية الكاش بدل الخمس دقائق
  // الافتراضية الموجّهة لقوائم تتغيّر مع الموقع والترتيب.
  Future<Response> getMainCategories({bool forceRefresh = false}) async {
    try {
      return await _dio.get(
        'api/user/main-categories',
        options: forceRefresh
            ? DioClient.refreshed
            : DioClient.cached(maxStale: const Duration(hours: 1)),
      );
    } on DioException {
      rethrow;
    }
  }

  // جلب تصنيفات أصناف مطعم معيّن — GET /api/user/categories/:id
  Future<Response> getCategories(String restaurantId) async {
    try {
      return await _dio.get(
        'api/user/categories/$restaurantId',
        options: DioClient.cached(),
      );
    } on DioException {
      rethrow;
    }
  }

  // البحث الشامل عن المطاعم والوجبات (جديد 1.1)
  Future<Response> search(String query) async {
    try {
      return await _dio.get(
        'api/user/search',
        queryParameters: {'q': query},
      );
    } on DioException {
      rethrow;
    }
  }

  // جلب أطعمة مطعم معين - تم التحديث لدعم الفلترة بالكاتيغوري والترتيب (جديد 1.1)
  Future<Response> getFoodByRestaurant(String restaurantId, {
    String? category,
    String? sort,
    bool forceRefresh = false,
  }) async {
    try {
      return await _dio.get(
        'api/user/food-in-restaurant/$restaurantId',
        queryParameters: {
          'category': ?category,
          'sort': ?sort,
        },
        options: forceRefresh ? DioClient.refreshed : DioClient.cached(),
      );
    } on DioException {
      rethrow;
    }
  }

  // جلب تفاصيل صنف واحد محدَّثة (سعر/عروض/توفر حالي) — GET /api/user/food/:id
  Future<Response> getFoodById(String foodId) async {
    try {
      return await _dio.get(
        'api/user/food/$foodId',
        options: DioClient.refreshed, // نريد أحدث بيانات دائماً (سعر/توفر)
      );
    } on DioException {
      rethrow;
    }
  }

  // // تقييم مطعم (ملغى — لا يوجد endpoint في الباكند)
  // Future<Response> rateRestaurant({
  //   required String resId,
  //   required double rating,
  //   String? comment,
  // }) async {
  //   try {
  //     return await _dio.post('api/user/rate/restaurant', data: {
  //       'restaurantId': resId,
  //       'rating': rating,
  //       'comment': comment,
  //     });
  //   } on DioException catch (e) {
  //     rethrow;
  //   }
  // }

  Future<Response> rateFood({
    required String foodId,
    required double rating,
    String? comment,
    String? orderId,
  }) async {
    try {
      return await _dio.post('api/user/rate/food', data: {
        'foodId': foodId,
        'rating': rating,
        'comment': comment,
        'orderId': ?orderId,
      });
    } on DioException {
      rethrow;
    }
  }
}
