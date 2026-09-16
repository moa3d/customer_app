import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';


class FavoriteService {
  final Dio _dio = DioClient().instance;

  // جلب قائمة المفضلات كاملة
  Future<Response> getMyFavorites() async {
    return await _dio.get('api/user/favorite');
  }

  // تبديل حالة المفضلة للمطعم (إضافة/حذف)
  Future<Response> toggleRestaurantFavorite(String restaurantId) async {
    return await _dio.patch(
      'api/user/favorite/restaurant',
      data: {'restaurantId': restaurantId},
    );
  }

  // تبديل حالة المفضلة للطعام (إضافة/حذف)
  Future<Response> toggleFoodFavorite(String foodId) async {
    return await _dio.patch(
      'api/user/favorite/food',
      data: {'foodId': foodId},
    );
  }
}
