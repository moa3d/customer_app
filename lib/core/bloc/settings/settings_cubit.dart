import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/order_notifications_service.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(SettingsState(
      locale: const Locale('ar'),
      themeMode: ThemeMode.system
  )) {
    loadSettings();
  }

  static const String _themeKey = 'theme_mode';
  static const String _langKey = 'language_code'; // مفتاح اللغة الموحد مع DioClient
  static const String _allNotifKey = 'all_notif';
  static const String _orderStatusKey = 'order_status_notif';
  static const String _deliveryKey = 'delivery_notif';
  static const String _offersKey = 'offers_notif';
  static const String _soundKey = 'notif_sound';
  static const String _vibrationKey = 'vibration_notif';

  // تحميل الإعدادات المحفوظة عند تشغيل التطبيق
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // تحميل الثيم
    int themeIndex = prefs.getInt(_themeKey) ?? 0;
    ThemeMode savedMode = ThemeMode.values[themeIndex];

    // تحميل اللغة المحفوظة (الافتراضية العربية)
    String langCode = prefs.getString(_langKey) ?? 'ar';

    emit(state.copyWith(
      locale: Locale(langCode),
      themeMode: savedMode,
      allNotificationsEnabled: prefs.getBool(_allNotifKey) ?? true,
      orderStatusNotifications: prefs.getBool(_orderStatusKey) ?? true,
      deliveryNotifications: prefs.getBool(_deliveryKey) ?? true,
      offersNotifications: prefs.getBool(_offersKey) ?? true,
      notificationSound: prefs.getBool(_soundKey) ?? true,
      notificationVibration: prefs.getBool(_vibrationKey) ?? true,
    ));
  }

  // ✅ تحديث: دالة تغيير اللغة مع الحفظ الدائم لربطها مع الباك أند
  Future<void> changeLanguage(Locale locale) async {
    emit(state.copyWith(locale: locale));
    final prefs = await SharedPreferences.getInstance();
    // حفظ كود اللغة ليقرأه DioClient في الهيدر Accept-Language تلقائياً في كل طلب
    await prefs.setString(_langKey, locale.languageCode);
  }

  // تحديث إعداد إشعار محدد
  Future<void> updateNotification(String type, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    switch (type) {
      case 'orderStatus':
        await prefs.setBool(_orderStatusKey, value);
        emit(state.copyWith(orderStatusNotifications: value));
        break;
      case 'delivery':
        await prefs.setBool(_deliveryKey, value);
        emit(state.copyWith(deliveryNotifications: value));
        break;
      case 'offers':
        await prefs.setBool(_offersKey, value);
        emit(state.copyWith(offersNotifications: value));
        break;
      case 'sound':
        await prefs.setBool(_soundKey, value);
        emit(state.copyWith(notificationSound: value));
        break;
      case 'vibration':
        await prefs.setBool(_vibrationKey, value);
        emit(state.copyWith(notificationVibration: value));
        break;
    }
    _syncNotificationPrefs();
  }

  // تفعيل أو إغلاق جميع الإشعارات دفعة واحدة
  Future<void> toggleAllNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    // المفاتيح الفرعية تُحفظ هي أيضاً: كانت تُبَثّ في الحالة بلا حفظ، فبعد
    // إعادة التشغيل يعود المفتاح الفرعي لقيمته القديمة بينما يبقى العام مطفأً
    // — فتظهر الشاشة متناقضة مع نفسها.
    await Future.wait([
      prefs.setBool(_allNotifKey, value),
      prefs.setBool(_orderStatusKey, value),
      prefs.setBool(_deliveryKey, value),
      prefs.setBool(_offersKey, value),
    ]);

    emit(state.copyWith(
      allNotificationsEnabled: value,
      orderStatusNotifications: value,
      deliveryNotifications: value,
      offersNotifications: value,
    ));
    _syncNotificationPrefs();
  }

  /// يدفع التفضيلات إلى `OrderNotificationsService` فور تغيّرها.
  ///
  /// الخدمة تفحص التفضيل داخل مستمع متزامن لأحداث السوكيت، فلا يمكنها قراءة
  /// `SharedPreferences` هناك (async). لذلك تحتفظ بنسخة في الذاكرة نُحدّثها من
  /// هنا. (عزلة الخلفية تقرأ من القرص مباشرة، ولذلك يجب أن يسبق الحفظ هذا
  /// النداء — وهو ما يحدث أعلاه.)
  void _syncNotificationPrefs() {
    OrderNotificationsService().setPreferences(NotificationPrefs(
      all: state.allNotificationsEnabled,
      orderStatus: state.orderStatusNotifications,
      delivery: state.deliveryNotifications,
    ));
  }

  // تغيير نمط العرض (ثيم)
  Future<void> changeTheme(ThemeMode mode) async {
    emit(state.copyWith(themeMode: mode));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }
}