import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'order_notifications_service.dart';
import 'push_notification_service.dart';

/// معالج إشعارات الخلفية.
///
/// النظام يعرض الإشعار في الدرج بنفسه لأن رسالة الباك تحمل `notification`،
/// لكنه لا يخبر التطبيق بشيء. فبلا هذا المعالج كان الخبر يصل المستخدم في درج
/// النظام ثم **لا يجده** في شاشة الإشعارات ما لم يضغطه — والباك لا يخزّن شيئاً
/// (`PERSISTED_NOTIFICATION_KEYS` فارغة) والسوكيت لا يعيد بثّ ما فات، فلا سبيل
/// لاستدراكه لاحقاً.
///
/// يعمل في عزلة (isolate) مستقلة تماماً: لا ترى `OrderNotificationsService`
/// الحيّ ولا أي حالة في الذاكرة، فيكتب مباشرة في `SharedPreferences` بنفس
/// المفتاح وبنفس القواعد المشتركة (`appendEvent`) — إلغاء التكرار بـ
/// `orderId::status`، سقف العدد، واحترام تفضيلات المستخدم.
@pragma('vm:entry-point')
Future<void> handleBackgroundMessage(RemoteMessage message) async {
  // العزلة تبدأ فارغة: لا ربط للإضافات ولا Firebase مهيّأة.
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('⚠️ [PUSH bg]: Firebase init failed: $e');
    return;
  }

  final data = message.data;
  if (data['type'] != PushNotificationService.kOrderStatusType) return;

  try {
    final prefs = await SharedPreferences.getInstance();
    // إعادة القراءة من القرص لا من الذاكرة: هذه العزلة لا تملك ذاكرة مشتركة
    // مع العملية الرئيسية، فالقرص هو مصدر الحقيقة الوحيد بينهما.
    final current =
        OrderNotificationsService.decode(prefs.getString(OrderNotificationsService.storageKey));

    final next = OrderNotificationsService.appendEvent(
      current,
      Map<String, dynamic>.from(data),
      NotificationPrefs.fromPrefs(prefs),
    );
    if (next == null) return;

    await prefs.setString(
      OrderNotificationsService.storageKey,
      OrderNotificationsService.encode(next),
    );
    debugPrint('🔔 [PUSH bg]: recorded ${data['status']}');
  } catch (e) {
    // فشل التسجيل لا يعني ضياع الإشعار — النظام عرضه أصلاً في الدرج
    debugPrint('⚠️ [PUSH bg]: record failed: $e');
  }
}
