import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/routing/app_router.dart';
import '../../core/routing/routes.dart';
import '../services/auth_service.dart';
import '../services/token_storage.dart';


class DioClient {
  static final DioClient _instance = DioClient._internal();
  late Dio _dio;

  static const String baseUrl = "https://nomnow-o4ba.onrender.com/";

  /// مخزن واحد مشترك بين الاعتراض العام والخيارات الخاصة بكل نداء.
  static final _cacheStore = MemCacheStore(
    maxSize: 5 * 1024 * 1024,
    maxEntrySize: 512 * 1024,
  );

  /// السياسة العامة: بلا كاش. الكاش يُطلب صراحةً لكل نداء على حدة
  /// عبر [cached] أدناه.
  static final cacheOptions = CacheOptions(
    store: _cacheStore,
    policy: CachePolicy.noCache,
    hitCacheOnNetworkFailure: false,
  );

  /// خيارات نداء يُراد تخزينه مؤقتاً (قوائم المطاعم والأصناف والعروض).
  ///
  /// نستخدم [CachePolicy.forceCache] لا [CachePolicy.request] لأن الباك أند
  /// لا يُرسل ترويسات Cache-Control إطلاقاً، فسياسة request لن تُخزّن شيئاً.
  /// مع forceCache تكون [maxStale] هي مدة الصلاحية الفعلية.
  ///
  /// [hitCacheOnNetworkFailure] يعرض آخر نسخة مخزّنة عند فشل الشبكة بدل
  /// شاشة خطأ فارغة — مفيد جداً مع بطء استضافة Render عند الاستيقاظ.
  static Options cached({
    Duration maxStale = const Duration(minutes: 5),
  }) {
    return CacheOptions(
      store: _cacheStore,
      policy: CachePolicy.forceCache,
      hitCacheOnNetworkFailure: true,
      maxStale: maxStale,
    ).toOptions();
  }

  /// تجاوز الكاش وتحديثه — للسحب لأسفل (Pull to refresh).
  static Options get refreshed {
    return CacheOptions(
      store: _cacheStore,
      policy: CachePolicy.refresh,
      hitCacheOnNetworkFailure: true,
      maxStale: const Duration(minutes: 5),
    ).toOptions();
  }

  factory DioClient() => _instance;

  /// تفريغ الكاش — يُستدعى عند تسجيل الخروج حتى لا يرث الحساب التالي
  /// نتائج مخزّنة من الحساب السابق.
  static Future<void> clearCache() async {
    try {
      await _cacheStore.clean();
    } catch (_) {}
  }

  /// يمنع تنفيذ تسجيل الخروج والتوجيه أكثر من مرة عندما تفشل عدة طلبات
  /// متزامنة بـ 401 في اللحظة نفسها.
  static bool _handlingUnauthorized = false;

  DioClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(DioCacheInterceptor(options: cacheOptions));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final String? token = await TokenStorage().getToken();

        String languageCode = prefs.getString('language_code') ?? 'ar';
        options.headers["Accept-Language"] = languageCode;

        if (token != null && token.isNotEmpty) {
          options.headers["Authorization"] = "Bearer $token";
        }
        return handler.next(options);
      },

      onResponse: (response, handler) {
        debugPrint(" [API RESPONSE][${response.statusCode}]: ${response
            .requestOptions.path}");
        return handler.next(response);
      },

      onError: (DioException e, handler) async {
        debugPrint(
            "  [API ERROR][${e.response?.statusCode}]: ${e.requestOptions
                .path}");
        debugPrint("  [SERVER MESSAGE]: ${e.response?.data}");

        // --- معالجة حالة انتهت صلاحية التوكن (401) ---
        if (e.response?.statusCode == 401 && !_handlingUnauthorized) {
          _handlingUnauthorized = true;
          debugPrint("Token expired or unauthorized — redirecting to login");
          try {
            // logout تتكفّل بالتنظيف كاملاً: توكن FCM، قطع السوكيت، سجلّ
            // الإشعارات، والكاش — فالمسارات الثلاثة متطابقة بحكم البناء.
            await AuthService().logout();
            if (AppRouter.router.routerDelegate.navigatorKey.currentContext !=
                null) {
              AppRouter.router.go(Routes.authSelection);
            }
          } finally {
            _handlingUnauthorized = false;
          }
        }

        // --- معالجة حالات الحظر والرفض والانتظار (403) حسب تعليمات الباك أند ---
        if (e.response?.statusCode == 403) {
          final responseData = e.response?.data;
          final String message = responseData is Map
              ? (responseData['message'] ?? "").toString().toLowerCase()
              : "";

          final authService = AuthService();

          // 1. حالة الحظر (Blocked) - للمستخدم والسائق
          if (message.contains("blocked")) {
            await authService.logout(); // تسجيل خروج تلقائي
            // التوجيه لشاشة الحظر باستخدام GoRouter وتمرير حالة isRejected = false
            AppRouter.router.go(Routes.banned, extra: false);
          }

          // 2. حالة الرفض (Rejected) - للسائق
          else if (message.contains("rejected")) {
            await authService.logout(); // تسجيل خروج تلقائي
            // التوجيه لشاشة الحظر باستخدام GoRouter وتمرير حالة isRejected = true
            AppRouter.router.go(Routes.banned, extra: true);
          }

          // 3. حالة المراجعة/الانتظار (Pending) - للسائق
          else if (message.contains("review") || message.contains("approval")) {
            debugPrint("Driver account is under review.");
          }
        }

        return handler.next(e);
      },
    ));
  }

  Dio get instance => _dio;
}
