import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/coupon.dart';

class CouponService {
  final Dio _dio = DioClient().instance;

  /// GET api/user/coupons — يأخذ القائمة بحالة منعشة (force refresh)
  /// كي لا تبقى كوبونات قديمة بعد استخدام/انتهاء كوبون.
  Future<List<Coupon>> getCoupons() async {
    try {
      final response = await _dio.get(
        'api/user/coupons',
        options: DioClient.refreshed,
      );
      final data = response.data;
      final rawList = (data is Map ? (data['coupons'] ?? data['data']?['coupons']) : null);
      if (rawList is! List) return const [];
      return rawList
          .whereType<Map>()
          .map((e) => Coupon.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException {
      rethrow;
    }
  }
}
