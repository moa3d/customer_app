import 'package:dio/dio.dart';
import '../network/dio_client.dart';

class AppService {
  final Dio _dio = DioClient().instance;



  // // --- العناوين (موجودة في AuthService) ---
  // Future<Response> getAddresses() => _dio.get('api/user/user-addresses');
  // Future<Response> addAddress(Map data) =>
  //     _dio.post('api/user/user-addresses', data: data);
  // Future<Response> updateAddress(Map data) =>
  //     _dio.patch('api/user/user-addresses', data: data);
  // Future<Response> deleteAddress(String id) =>
  //     _dio.delete('api/user/user-addresses', data: {'addressId': id});

  // // --- المطاعم والأكل (موجودة في RestaurantService) ---
  // Future<Response> getAllRestaurants({double? lat, double? lng}) {
  //   return _dio.get('api/user/restaurant', queryParameters: {
  //     if (lat != null) 'lat': lat,
  //     if (lng != null) 'lng': lng,
  //   });
  // }
  // Future<Response> getAllFood({double? lat, double? lng}) {
  //   return _dio.get('api/user/food', queryParameters: {
  //     if (lat != null) 'lat': lat,
  //     if (lng != null) 'lng': lng,
  //   });
  // }
  // Future<Response> getFoodInRestaurant(String id) =>
  //     _dio.get('api/user/food-in-restaurant/$id');

  // // --- المفضلة (موجودة في FavoriteService) ---
  // Future<Response> getFavorites() => _dio.get('api/user/favorite');
  // Future<Response> toggleFoodFav(String id) =>
  //     _dio.patch('api/user/favorite/food', data: {'foodId': id});
  // Future<Response> toggleResFav(String id) =>
  //     _dio.patch('api/user/favorite/restaurant', data: {'restaurantId': id});

  // --- التقييم ---
  Future<Response> rateFood(String id, double rate, String comment) =>
      _dio.post('api/user/rate/food', data: {
        'foodId': id,
        'rating': rate,
        'comment': comment
      });

  // --- تقييمات الأوردر ---

  // تقييم الطلب بالكامل (يُستدعى بعد وصول الطلب)
  Future<Response> rateOrder({
    required String orderId,
    required double rating,
    String? comment,
  }) {
    return _dio.post('api/user/rate/order', data: {
      'orderId': orderId,
      'rating': rating,
      'comment': comment,
    });
  }

  // تقييم السائق (يتم ربطه بالأوردر لضمان صحة البيانات)
  Future<Response> rateDriver({
    required String orderId,
    required double rating,
    String? comment,
  }) {
    return _dio.post('api/user/rate/driver', data: {
      'orderId': orderId,
      'rating': rating,
      'comment': comment,
    });
  }
}