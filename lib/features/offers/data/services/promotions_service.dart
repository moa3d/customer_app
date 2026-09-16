import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

class PromotionsService {
  final Dio _dio = DioClient().instance;

  Future<Response> getPromotions({bool forceRefresh = false}) async {
    try {
      return await _dio.get(
        'api/user/promotions',
        options: forceRefresh
            ? DioClient.refreshed
            : DioClient.cached(maxStale: const Duration(minutes: 10)),
      );
    } on DioException {
      rethrow;
    }
  }
}
