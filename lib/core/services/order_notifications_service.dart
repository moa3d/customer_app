import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'socket_service.dart';

class OrderNotificationRecord {
  final String id;
  final String orderId;
  final String status;
  final DateTime createdAt;
  bool isUnread;

  OrderNotificationRecord({
    required this.id,
    required this.orderId,
    required this.status,
    required this.createdAt,
    this.isUnread = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'status': status,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'isUnread': isUnread,
      };

  static OrderNotificationRecord? fromJson(Map<String, dynamic> j) {
    final id = j['id']?.toString();
    final orderId = j['orderId']?.toString();
    final status = j['status']?.toString();
    final ms = j['createdAt'];
    if (id == null || orderId == null || status == null || ms is! int) {
      return null;
    }
    return OrderNotificationRecord(
      id: id,
      orderId: orderId,
      status: status,
      createdAt: DateTime.fromMillisecondsSinceEpoch(ms),
      isUnread: j['isUnread'] == true,
    );
  }
}

/// تفضيلات إشعارات المستخدم، مقروءة من نفس مفاتيح `SettingsCubit`.
///
/// تُقرأ بالمفاتيح لا عبر الـ cubit لأن هذا الملف يعمل أيضاً داخل عزلة الخلفية
/// التي لا ترى أي bloc. المفاتيح مكرّرة هنا عمداً ولا مفرّ منه — أي تغيير في
/// `settings_cubit.dart` يجب أن يُقابله تغيير هنا.
class NotificationPrefs {
  final bool all;
  final bool orderStatus;
  final bool delivery;

  const NotificationPrefs({
    this.all = true,
    this.orderStatus = true,
    this.delivery = true,
  });

  static const String keyAll = 'all_notif';
  static const String keyOrderStatus = 'order_status_notif';
  static const String keyDelivery = 'delivery_notif';

  /// حالات مرحلة التوصيل — يحكمها مفتاح «التوصيل».
  static const Set<String> _deliveryStatuses = {
    'picked_up',
    'on_the_way',
    'delivered',
  };

  static NotificationPrefs fromPrefs(SharedPreferences prefs) {
    return NotificationPrefs(
      all: prefs.getBool(keyAll) ?? true,
      orderStatus: prefs.getBool(keyOrderStatus) ?? true,
      delivery: prefs.getBool(keyDelivery) ?? true,
    );
  }

  static Future<NotificationPrefs> load() async {
    try {
      return fromPrefs(await SharedPreferences.getInstance());
    } catch (_) {
      // تعذّر القراءة يعني السماح — إسكات المستخدم بالخطأ أسوأ من إزعاجه
      return const NotificationPrefs();
    }
  }

  bool allows(String status) {
    if (!all) return false;
    return _deliveryStatuses.contains(status) ? delivery : orderStatus;
  }
}

class OrderNotificationsService {
  static final OrderNotificationsService _instance =
      OrderNotificationsService._internal();

  factory OrderNotificationsService() => _instance;

  OrderNotificationsService._internal();

  /// مشترك مع عزلة الخلفية (`notification_background_handler.dart`) —
  /// أي تغيير هنا يغيّر ما تقرؤه وتكتبه العزلتان معاً.
  static const String storageKey = 'order_notifications';
  static const int maxRecords = 50;

  static const Set<String> notifiableStatuses = {
    'pending',
    'accepted',
    'preparing',
    'ready',
    'picked_up',
    'on_the_way',
    'delivered',
    'cancelled',
  };

  final ValueNotifier<List<OrderNotificationRecord>> notifications =
      ValueNotifier<List<OrderNotificationRecord>>([]);

  StreamSubscription<Map<String, dynamic>>? _sub;
  bool _initialized = false;

  NotificationPrefs _prefs = const NotificationPrefs();

  int get unreadCount => notifications.value.where((n) => n.isUnread).length;

  // ── القواعد المشتركة بين العزلتين ────────────────────────────────────────
  //
  // العزلة الرئيسية والعزلة الخلفية تطبّقان القواعد نفسها حرفياً — إلغاء
  // التكرار بـ `orderId::status`، وسقف العدد، والتفضيلات. نسختان تفترقان
  // كانتا ستنتجان سجلّاً مختلفاً حسب حالة التطبيق وقت وصول الخبر.

  /// يضيف حدثاً إلى [current] ويعيد القائمة الجديدة، أو `null` إن تُجوهل
  /// الحدث (حقول ناقصة، حالة غير معنيّة، تفضيل مطفأ، أو مكرّر).
  static List<OrderNotificationRecord>? appendEvent(
    List<OrderNotificationRecord> current,
    Map<String, dynamic> data,
    NotificationPrefs prefs,
  ) {
    final orderId = data['orderId']?.toString();
    final status = data['status']?.toString();
    if (orderId == null || status == null) return null;
    if (!notifiableStatuses.contains(status)) return null;
    if (!prefs.allows(status)) return null;

    final id = '$orderId::$status';
    if (current.any((n) => n.id == id)) return null;

    final next = List<OrderNotificationRecord>.from(current)
      ..insert(
        0,
        OrderNotificationRecord(
          id: id,
          orderId: orderId,
          status: status,
          createdAt: DateTime.now(),
        ),
      );

    if (next.length > maxRecords) {
      next.removeRange(maxRecords, next.length);
    }
    return next;
  }

  static List<OrderNotificationRecord> decode(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final list = <OrderNotificationRecord>[];
      for (final e in decoded) {
        if (e is! Map) continue;
        final rec =
            OrderNotificationRecord.fromJson(Map<String, dynamic>.from(e));
        if (rec != null) list.add(rec);
      }
      return list;
    } catch (e) {
      debugPrint('[NOTIF] decode failed: $e');
      return [];
    }
  }

  static String encode(List<OrderNotificationRecord> list) =>
      jsonEncode(list.map((n) => n.toJson()).toList());

  // ── دورة الحياة ──────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    _prefs = await NotificationPrefs.load();
    await _load();

    _sub?.cancel();
    _sub = SocketService().orderStatusStream.listen(
      _onOrderStatus,
      onError: (Object e) => debugPrint('[NOTIF] stream error: $e'),
    );
  }

  /// إعادة القراءة من التخزين.
  ///
  /// لازمة عند استئناف التطبيق: عزلة الخلفية قد تكون كتبت سجلّاً بينما كانت
  /// العملية الرئيسية موقوفة لا مقتولة، فقائمتها في الذاكرة صارت قديمة — وأول
  /// `_save()` بعدها كان سيدهس ما كتبته الخلفية.
  Future<void> reload() async {
    _prefs = await NotificationPrefs.load();
    await _load();
  }

  /// تُستدعى من `SettingsCubit` بعد كل تبديل، حتى يرى المستمع المتزامن
  /// `_onOrderStatus` القيمة الجديدة بلا قراءة async داخله.
  void setPreferences(NotificationPrefs prefs) => _prefs = prefs;

  /// v3.5 — مدخل إشعارات Push إلى نفس السجل.
  ///
  /// يمرّ بنفس مسار السوكيت عمداً: إلغاء التكرار عبر `orderId::status` يضمن
  /// أن وصول الخبر من القناتين معاً (سوكيت + push) لا ينتج سطرين مكرّرين.
  void ingestPush(Map<String, dynamic> data) => _onOrderStatus(data);

  void _onOrderStatus(Map<String, dynamic> data) {
    final next = appendEvent(notifications.value, data, _prefs);
    if (next == null) return;
    notifications.value = next;
    _save();
  }

  Future<void> markAllRead() async {
    for (final n in notifications.value) {
      n.isUnread = false;
    }
    notifications.value = List.from(notifications.value);
    await _save();
  }

  Future<void> markRead(String id) async {
    for (final n in notifications.value) {
      if (n.id == id) n.isUnread = false;
    }
    notifications.value = List.from(notifications.value);
    await _save();
  }

  Future<void> remove(String id) async {
    notifications.value =
        notifications.value.where((n) => n.id != id).toList();
    await _save();
  }

  Future<void> clear() async {
    notifications.value = [];
    await _save();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      notifications.value = decode(prefs.getString(storageKey));
    } catch (e) {
      debugPrint('[NOTIF] load failed: $e');
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(storageKey, encode(notifications.value));
    } catch (e) {
      debugPrint('[NOTIF] save failed: $e');
    }
  }

  Future<void> clearOnLogout() async {
    notifications.value = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(storageKey);
    } catch (_) {}
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    _initialized = false;
  }
}
