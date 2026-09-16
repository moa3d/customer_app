import 'package:dio/dio.dart';
import '../../../../core/network/app_error.dart';
import '../../../../core/network/dio_client.dart';


class CartRepository {
  final Dio _dio = DioClient().instance;

  // 1. إضافة إلى السلة
  /// [replaceCart] يستبدل سلة مطعم آخر بهذه الوجبة في نداء واحد بدل تفريغها
  /// أولاً. بدونه يردّ الباك 400 `differentRestaurant`.
  Future<void> addToCart({
    required String foodId,
    required int quantity,
    Map<String, dynamic>? size, //  تم جعله اختيارياً (Nullable) ليقبل null
    List<Map<String, dynamic>>? extras,
    String? notes,
    String? restaurantId,
    bool replaceCart = false,
  }) async {
    try {
      final payload = {
        "foodId": foodId,
        "quantity": quantity,
        "size": size, //  سيتم إرساله كـ null إذا لم تكن الوجبة تملك أحجاماً
        "extras": extras ?? [],
        "notes": notes ?? "",
        if (replaceCart) "replaceCart": true,
      };
      if (restaurantId != null && restaurantId.isNotEmpty) {
        payload["restaurantId"] = restaurantId;
      }

      await _dio.post('api/user/cart', data: payload);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // 2. جلب السلة (تكامل مع getCart في Node.js)
  Future<Map<String, dynamic>> getCart() async {
    try {
      final response = await _dio.get('api/user/cart');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // 3. حذف عنصر (تكامل مع removeFoodFromCart في Node.js)
  Future<Map<String, dynamic>> removeFromCart({
    required String itemId,
  }) async {
    try {
      final response = await _dio.delete('api/user/cart', data: {
        "itemId": itemId,
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// 4. تحديث كمية عنصر بمكانه.
  ///
  /// كان هذا النداء `DELETE` ثم `POST` لأن الباك لم يكن يملك `PATCH`. وكان
  /// الحل التعويضي مكلفاً: حذف آخر عنصر يحذف وثيقة السلة كاملةً ومعها
  /// `couponCode`، وفشل الـ`POST` بعد نجاح الـ`DELETE` يترك السلة ناقصة
  /// عنصراً. الآن `PATCH` يعدّل العنصر في مكانه ويعيد حساب المجموع بلا حذف
  /// شيء، فالكوبون لا يمكن أن يضيع والعملية إمّا تنجح كاملة أو لا تغيّر شيئاً.
  Future<Map<String, dynamic>> updateCartItem({
    required String itemId,
    required int quantity,
  }) async {
    try {
      final response = await _dio.patch('api/user/cart', data: {
        "itemId": itemId,
        "quantity": quantity,
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// تفريغ السلة بحذف عناصرها واحداً واحداً.
  ///
  /// **لا يوجد endpoint لتفريغ السلة في الباك.** المسار `/cart` يحمل
  /// `get/post/delete` فقط، و`DELETE` موصول بـ `removeFoodFromCart` التي تتطلّب
  /// `itemId` في الجسم. وكان هذا النداء يُرسل `DELETE` بلا جسم، فيعود الباك
  /// بـ 404 `itemNotFound` والسلة لا تُمسّ إطلاقاً — وهو ما كان يكسر «حذف
  /// وإضافة» عند تبديل المطعم: تبقى السلة للمطعم القديم فيرفض `addToCart`
  /// الوجبة الجديدة بـ `differentRestaurant`.
  ///
  /// المعرّفات تُقرأ من الخادم لا من حالة الواجهة، لأن الشاشة قد تكون فتحت
  /// بلا جلب سلة بعد. وحذف آخر عنصر يحذف وثيقة السلة كاملةً في الباك — وهو
  /// المطلوب هنا بالضبط.
  Future<void> clearCart() async {
    try {
      final response = await getCart();
      final cart = response['cart'] ?? response['data']?['cart'];
      final items = cart is Map ? cart['items'] : null;
      if (items is! List || items.isEmpty) return;

      for (final item in items) {
        final id = item is Map ? item['_id']?.toString() : null;
        if (id == null || id.isEmpty) continue;
        await removeFromCart(itemId: id);
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  // 5. تطبيق كوبون على السلة (تكامل مع applyCoupon في Node.js)
  Future<Map<String, dynamic>> applyCoupon({required String code}) async {
    try {
      final response = await _dio.post('api/user/cart/coupon', data: {
        "code": code,
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // 6. إزالة الكوبون من السلة (تكامل مع removeCoupon في Node.js)
  Future<Map<String, dynamic>> removeCoupon() async {
    try {
      final response = await _dio.delete('api/user/cart/coupon');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// يُصنَّف الخطأ مرة واحدة هنا ويُحمل كما هو إلى الواجهة.
  ///
  /// كان يلفّ الخطأ في `Exception(message)` عادي، فيصنّفه `AppError.from`
  /// لاحقاً `unknown` ويستبدل رسالة الخادم برسالة عامة — فكانت كل رسائل 400
  /// المفيدة في `addToCart` (سلة من مطعم آخر، وجبة غير متاحة، حجم مطلوب،
  /// حجم غير صالح، كمية غير صالحة) تصل المستخدم كـ«خطأ غير متوقع».
  Exception _handleError(dynamic e) => ApiException(AppError.from(e));
}