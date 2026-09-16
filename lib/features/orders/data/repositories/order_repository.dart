import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/app_error.dart';
import '../../../../core/network/dio_client.dart';


class OrderCreationException implements Exception {
  final String message;
  final List<Map<String, dynamic>> changedItems;

  OrderCreationException({required this.message, required this.changedItems});

  @override
  String toString() => message;
}

class PaymentIntentException implements Exception {
  final String message;

  PaymentIntentException(this.message);

  @override
  String toString() => message;
}


class OrderRepository {
  final Dio _dio = DioClient().instance;

  /// الحالات التي تعني أن الطلب ما زال جارياً
  static const Set<String> activeStatuses = {
    'pending',
    'accepted',
    'preparing',
    'ready',
    'picked_up',
    'on_the_way',
    'delivered_by_driver',
  };

  /// أحدث طلب غير منتهٍ — الباك يرجع الطلبات مرتبة تنازلياً بالفعل
  Future<Map<String, dynamic>?> getActiveOrder() async {
    try {
      final orders = await getUserOrders();
      for (final o in orders) {
        if (o is! Map) continue;
        if (activeStatuses.contains(o['orderStatus']?.toString())) {
          return Map<String, dynamic>.from(o);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> createOrder({
    required Map<String, dynamic> deliveryAddress,
    String? notes,
    String paymentMethod = "cash",
  }) async {
    try {
      final response = await _dio.post('api/user/order', data: {
        "deliveryAddress": deliveryAddress,
        "notes": notes ?? "",
        "paymentMethod": paymentMethod,
      });
      return response.data;
    } catch (e) {
      if (e is DioException && e.response != null) {
        debugPrint("🚨 [BACKEND REJECTED ORDER]: ${e.response?.data}");

        final data = e.response?.data as Map?;

        // 409 Price Changed — نمرر changedItems مع الاستثناء
        if (e.response?.statusCode == 409 && data?['changedItems'] != null) {
          throw OrderCreationException(
            message: (data?['message'] ?? "Server error").toString(),
            changedItems: List<Map<String, dynamic>>.from(data!['changedItems']),
          );
        }
      }

      // بقية الحالات تمرّ من المصنِّف كسائر دوال هذا المستودع. كانت تُلفّ في
      // `Exception(errorMessage)` عادي، فيصنّفه `AppError.from` مجهولاً
      // ويستبدل رسالة الخادم بـ«خطأ غير متوقع» — فتضيع كل رسائل 400 التي
      // يرسلها الباك عند رفض الطلب (عنوان توصيل غير صالح، مطعم مغلق، سلة
      // فارغة، وجبة لم تعد متاحة).
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getUserOrders() async {
    try {
      final response = await _dio.get('api/user/order');
      return response.data['orders'];
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> cancelOrder(String orderId) async {
    try {
      final response = await _dio.patch('api/user/order/cancelfromuser', data: {
        "orderId": orderId,
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// إنشاء Stripe PaymentIntent لسلة المستخدم الحالية — مخصص فقط لطلبات
  /// المطاعم في ألمانيا (DE). الباك يحسب الضريبة والمبلغ النهائي بنفسه.
  /// يرجع: { clientSecret, paymentIntentId, amount, currency, taxBreakdown }
  Future<Map<String, dynamic>> createPaymentIntent() async {
    try {
      final response = await _dio.post('api/user/payment/create-intent');
      return response.data;
    } catch (e) {
      if (e is DioException && e.response != null) {
        final data = e.response?.data as Map?;
        throw PaymentIntentException(
            (data?['message'] ?? "Payment initialization failed").toString());
      }
      throw PaymentIntentException("Network Error");
    }
  }

  /// يُصنَّف الخطأ مرة واحدة هنا. كانت الرسالتان الاحتياطيتان نصّين عربيّين
  /// مثبّتين بلا `.tr()`، فيراهما مستخدم الإنجليزية أو الألمانية عربيةً.
  Exception _handleError(dynamic e) {
    if (e is DioException) {
      debugPrint("⚠️ Repository Error: ${e.response?.data}");
    }
    return ApiException(AppError.from(e));
  }
}