import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/notifications/presentation/widgets/notification_permission_dialog.dart';
import 'push_notification_service.dart';

/// حالة صلاحية الإشعارات كما يراها نظام أندرويد.
enum NotificationPermissionStatus {
  /// الإشعارات مسموحة وتظهر فعلاً
  granted,

  /// مرفوضة ويمكن السؤال ثانية
  denied,

  /// رُفضت نهائياً — لا حوار نظام بعد الآن، الإصلاح من الإعدادات فقط
  permanentlyDenied,

  /// الصلاحية ليست العائق: المستخدم أغلق الإشعارات من إعدادات النظام
  /// (أو الجهاز دون أندرويد 13 حيث لا توجد صلاحية تشغيلية أصلاً)
  blockedBySettings,

  /// منصّة غير أندرويد أو تعذّر الوصول للقناة — لا نعرض شيئاً
  unsupported,
}

/// صلاحية الإشعارات على أندرويد — مستقلة تماماً عن Firebase.
///
/// `POST_NOTIFICATIONS` صلاحية نظام لا علاقة لها بـ FCM، ولذلك تُدار عبر قناة
/// أصلية في `MainActivity` بدل `FirebaseMessaging.requestPermission`. الفائدة
/// أنها تعمل من اليوم حتى قبل اكتمال إعدادات Firebase (راجع PUSH_SETUP.md).
///
/// iOS خارج نطاق هذه الخدمة عمداً — هناك يبقى مسار `requestPermission` في
/// [PushNotificationService] كما هو.
class NotificationPermissionService {
  static final NotificationPermissionService _instance =
      NotificationPermissionService._internal();

  factory NotificationPermissionService() => _instance;

  NotificationPermissionService._internal();

  static const MethodChannel _channel =
      MethodChannel('com.nomnow.app/notification_permission');

  /// هل عُرض حوار النظام فعلاً مرّة من قبل؟
  ///
  /// ضروري لأن `shouldShowRequestPermissionRationale` تعود false في حالتين
  /// مختلفتين تماماً: قبل أول سؤال، وبعد الرفض النهائي — فيميّز بينهما هذا
  /// العلم. يُرفع في [request] وحدها لأنها الوحيدة التي تعرض حوار النظام.
  static const String _askedKey = 'notif_perm_asked';

  /// هل رفض المستخدم الحوار التمهيدي ("لاحقاً")؟
  ///
  /// مفصول عن [_askedKey] عمداً: من ضغط "لاحقاً" لم يرَ حوار النظام قط، فما
  /// زال بإمكانه تفعيل الإشعارات بضغطة واحدة من شاشة الإعدادات بلا المرور
  /// بإعدادات النظام — والخلط بين العلمين كان سيحرمه ذلك.
  static const String _promptDeclinedKey = 'notif_perm_prompt_declined';

  NotificationPermissionStatus _parse(String? raw) {
    switch (raw) {
      case 'granted':
        return NotificationPermissionStatus.granted;
      case 'denied':
        return NotificationPermissionStatus.denied;
      case 'permanentlyDenied':
        return NotificationPermissionStatus.permanentlyDenied;
      case 'blockedBySettings':
        return NotificationPermissionStatus.blockedBySettings;
      default:
        return NotificationPermissionStatus.unsupported;
    }
  }

  /// قراءة الحالة الراهنة. لا ترمي أبداً — أي فشل يُعيد [unsupported].
  Future<NotificationPermissionStatus> check() async {
    if (!Platform.isAndroid) return NotificationPermissionStatus.unsupported;
    try {
      final raw = await _channel.invokeMethod<String>('status');
      return _parse(raw);
    } catch (e) {
      debugPrint('⚠️ [NOTIF-PERM]: status failed: $e');
      return NotificationPermissionStatus.unsupported;
    }
  }

  /// عرض حوار صلاحية النظام. يُعيد الحالة بعد رد المستخدم.
  Future<NotificationPermissionStatus> request() async {
    if (!Platform.isAndroid) return NotificationPermissionStatus.unsupported;
    try {
      final raw = await _channel.invokeMethod<String>('request');
      await _setFlag(_askedKey);
      final status = _parse(raw);

      // الصلاحية وحدها لا تكفي — التوكن يجب أن يصل الباك ليُرسل إشعاراً فعلياً
      if (status == NotificationPermissionStatus.granted) {
        await PushNotificationService().registerToken();
      }
      return status;
    } catch (e) {
      debugPrint('⚠️ [NOTIF-PERM]: request failed: $e');
      return NotificationPermissionStatus.unsupported;
    }
  }

  /// فتح شاشة إشعارات التطبيق في إعدادات النظام — المخرج الوحيد بعد الرفض النهائي.
  Future<void> openSystemSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('openSettings');
    } catch (e) {
      debugPrint('⚠️ [NOTIF-PERM]: openSettings failed: $e');
    }
  }

  Future<bool> _getFlag(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _setFlag(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, true);
    } catch (_) {
      // فقدان العلم يعني سؤالاً إضافياً لا أكثر — ليس حرجاً
    }
  }

  /// هل ما زال حوار النظام قادراً على الظهور؟
  ///
  /// [NotificationPermissionStatus.denied] تعني نعم بلا لبس. أما
  /// `permanentlyDenied` فتحتمل معنيين لأن النظام لا يفرّق بينهما: رفضٌ نهائي
  /// حقيقي، أو أننا لم نعرض الحوار أصلاً بعد. العلم المحفوظ يحسم أيّهما.
  Future<bool> canStillPrompt(NotificationPermissionStatus status) async {
    if (status == NotificationPermissionStatus.denied) return true;
    if (status != NotificationPermissionStatus.permanentlyDenied) return false;
    return !await _getFlag(_askedKey);
  }

  /// التدفّق الكامل بعد تسجيل دخول ناجح: شرح تمهيدي ثم حوار النظام.
  ///
  /// يُستدعى من نقطتي اكتمال الدخول قبل الانتقال لشاشة الموقع — فلا يتكدّس
  /// حوار الإشعارات فوق حوار صلاحية الموقع الذي تطلبه `SetLocationScreen`.
  ///
  /// لا يزعج المستخدم أكثر من مرة: الرفض يُسجَّل ولا يُعاد السؤال عند كل دخول.
  Future<void> maybeAskAfterLogin(BuildContext context) async {
    if (!Platform.isAndroid) return;

    final status = await check();

    // ممنوحة أصلاً، أو مغلقة من إعدادات النظام — لا شيء يفيده حوارنا هنا؛
    // شاشة إعدادات الإشعارات هي التي تعالج الحالة الثانية.
    if (status == NotificationPermissionStatus.granted ||
        status == NotificationPermissionStatus.blockedBySettings ||
        status == NotificationPermissionStatus.unsupported) {
      return;
    }

    // رفض نهائي فعلي: حوار النظام لن يظهر مهما فعلنا
    if (!await canStillPrompt(status)) return;

    // سبق أن قال "لاحقاً" أو رأى حوار النظام ورفضه — احترام القرار بدل
    // السؤال عند كل تسجيل دخول. شاشة الإعدادات تبقى مدخله متى أراد.
    if (await _getFlag(_promptDeclinedKey) || await _getFlag(_askedKey)) return;

    if (!context.mounted) return;
    final accepted = await showNotificationPermissionDialog(context);
    if (accepted != true) {
      await _setFlag(_promptDeclinedKey);
      return;
    }

    await request();
  }
}
