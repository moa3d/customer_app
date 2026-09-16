import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/dio_client.dart';
import '../routing/app_router.dart';
import '../routing/routes.dart';
import '../../features/orders/data/repositories/order_repository.dart';
import 'auth_service.dart';
import 'order_notifications_service.dart';

/// v3.5 — إشعارات Push لتحديثات حالة الطلب.
///
/// القناة الثانية بجانب السوكيت: السوكيت أسرع وأدق وهو المصدر الأساسي حين
/// يكون التطبيق مفتوحاً، وهذه القناة هي الوحيدة التي تصل حين يكون التطبيق
/// في الخلفية أو مغلقاً تماماً.
///
/// مبنية على نفس آلية إشعارات السائق في تطبيق التوصيل — نفس الـ SDK ونفس
/// دورة حياة التوكن؛ الفرق في `data.type` وفيما يحدث عند الوصول.
class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();

  factory PushNotificationService() => _instance;

  PushNotificationService._internal();

  /// نوع الإشعار الذي يعني هذا التطبيق — أي نوع آخر يُتجاهل بلا انهيار
  static const String kOrderStatusType = 'order:statusUpdated';

  /// آخر توكن أُرسل للسيرفر — نتفادى به نداءً متكرراً بلا فائدة عند كل إقلاع
  static const String _cachedTokenKey = 'user_fcm_token';

  bool _initialized = false;
  bool _available = false;

  /// هل تهيّأت Firebase فعلاً؟ تبقى false على الأجهزة بلا Google Services
  /// أو حين ينقص ملف إعدادات Firebase — وعندها يعمل التطبيق بالسوكيت وحده.
  bool get isAvailable => _available;

  /// تُستدعى بعد رسم أول إطار — غير حاجبة للإقلاع إطلاقاً.
  ///
  /// أي فشل هنا (جهاز بلا GMS، ملف إعدادات ناقص، انقطاع شبكة) لا يمنع
  /// التطبيق من العمل: السوكيت يبقى قناة التحديث حين يكون التطبيق مفتوحاً.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await Firebase.initializeApp();
      _available = true;
    } catch (e) {
      debugPrint('⚠️ [PUSH]: Firebase init failed — الإشعارات معطّلة: $e');
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;

      // إلزامي على iOS. أما أندرويد فصلاحيته يملكها NotificationPermissionService
      // عبر قناة أصلية وتُطلب بعد تسجيل الدخول لا على السبلاش — ولو تُرك هذا
      // النداء بلا حراسة لعاد حوار النظام للظهور على أول إطار فور إضافة
      // google-services.json مستقبلاً، فيُبطل التوقيت المقصود.
      if (!Platform.isAndroid) {
        await messaging.requestPermission(alert: true, badge: true, sound: true);
      }

      // 1) التطبيق مفتوح: السوكيت وصل الخبر غالباً قبل الـ push، فلا نعرض
      //    شيئاً فوق الشاشة — نكتفي بتسجيل الحدث تأكيداً (والتكرار يُلغى
      //    داخل OrderNotificationsService عبر معرّف orderId::status).
      FirebaseMessaging.onMessage.listen((message) {
        debugPrint('🔔 [PUSH foreground]: ${message.data}');
        _record(message.data);
      });

      // 2) التطبيق في الخلفية والمستخدم ضغط الإشعار
      FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

      // 3) التطبيق كان مغلقاً تماماً وفُتح بالضغط على الإشعار
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleTap(initialMessage);
      }

      // تجديد التوكن يحدث تلقائياً أحياناً (خاصة بعد إعادة تثبيت التطبيق)
      messaging.onTokenRefresh.listen((token) {
        _sendTokenToServer(token, force: true);
      });

      await registerToken();
    } catch (e) {
      debugPrint('⚠️ [PUSH]: setup failed: $e');
    }
  }

  /// تسجيل توكن الجهاز لدى الباك.
  ///
  /// تُستدعى بعد تسجيل الدخول، وعند كل فتح للتطبيق والمستخدم مسجّل دخول،
  /// وعند تجديد التوكن — حسب ما تفرضه المواصفة.
  Future<void> registerToken() async {
    if (!_available) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await _sendTokenToServer(token);
    } catch (e) {
      debugPrint('⚠️ [PUSH]: getToken failed: $e');
    }
  }

  /// يُرسل التوكن إلى `PATCH /api/user/fcm-token`.
  ///
  /// [force] يتجاوز الكاش — يُستعمل عند التجديد لأن التوكن تغيّر فعلاً.
  Future<void> _sendTokenToServer(String token, {bool force = false}) async {
    // بلا تسجيل دخول لا معنى لربط التوكن بحساب
    final authToken = await AuthService().getToken();
    if (authToken == null || authToken.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      if (!force && prefs.getString(_cachedTokenKey) == token) return;

      await DioClient().instance.patch(
        'api/user/fcm-token',
        data: {'fcmToken': token},
      );
      await prefs.setString(_cachedTokenKey, token);
      debugPrint('✅ [PUSH]: FCM token registered');
    } catch (e) {
      // فشل التسجيل لا يمنع استخدام التطبيق — نحاول ثانية عند الفتح التالي
      debugPrint('⚠️ [PUSH]: token registration failed: $e');
    }
  }

  /// يُنسى التوكن المحفوظ محلياً عند الخروج، حتى يُعاد إرساله كاملاً
  /// للمستخدم التالي على نفس الجهاز بدل أن يمنعه الكاش.
  Future<void> clearCachedToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedTokenKey);
    } catch (_) {
      // تنظيف الكاش ليس حرجاً
    }
  }

  /// يضيف الإشعار إلى سجل الإشعارات المحلي.
  ///
  /// السجل نفسه يتغذّى من السوكيت أيضاً، ويُلغي التكرار عبر `orderId::status`
  /// — لذلك وصول الخبر من القناتين معاً لا ينتج سطرين.
  void _record(Map<String, dynamic> data) {
    if (data['type'] != kOrderStatusType) return;
    OrderNotificationsService().ingestPush(data);
  }

  /// المعالجة الموحّدة عند الضغط على الإشعار (خلفية أو تطبيق مغلق).
  Future<void> _handleTap(RemoteMessage message) async {
    final data = message.data;
    debugPrint('👆 [PUSH tap]: $data');

    // أي نوع آخر (حملة تسويقية مستقبلية مثلاً) يُتجاهل بهدوء
    if (data['type'] != kOrderStatusType) return;

    _record(data);

    final orderId = data['orderId']?.toString();
    final status = data['status']?.toString();
    if (orderId == null || orderId.isEmpty) return;

    // الطلب الملغى لا شيء فيه لنتتبعه — نعيده لقائمة الطلبات
    if (status == 'cancelled') {
      _goToOrdersList();
      return;
    }

    await openOrderTracking(orderId);
  }

  /// شاشة التتبع تحتاج بيانات الطلب كاملة، والإشعار يحمل المعرّف فقط —
  /// فنجلب الطلبات ونلتقط المطلوب. إن تعذّر، نكتفي بقائمة الطلبات.
  ///
  /// عامّة لأن شاشة الإشعارات تفتح التتبّع بنفس المعطى (معرّف الطلب وحده)
  /// من زر «تتبع» في البطاقة.
  static Future<void> openOrderTracking(String orderId) async {
    try {
      final orders = await OrderRepository().getUserOrders();
      for (final o in orders) {
        if (o is! Map) continue;
        if (o['_id']?.toString() == orderId) {
          AppRouter.router.push(
            Routes.orderTracking,
            extra: Map<String, dynamic>.from(o),
          );
          return;
        }
      }
      _goToOrdersList();
    } catch (e) {
      debugPrint('⚠️ [PUSH]: could not open tracking: $e');
      _goToOrdersList();
    }
  }

  static void _goToOrdersList() {
    AppRouter.router.go(Routes.orders);
  }
}
