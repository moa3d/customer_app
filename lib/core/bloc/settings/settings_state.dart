import 'package:flutter/material.dart';

class SettingsState {
  final Locale locale;
  final ThemeMode themeMode;

  final bool allNotificationsEnabled;
  final bool orderStatusNotifications;
  final bool deliveryNotifications;
  final bool offersNotifications;
  final bool notificationSound;
  final bool notificationVibration;

  SettingsState({
    required this.locale,
    required this.themeMode,
    this.allNotificationsEnabled = true,
    this.orderStatusNotifications = true,
    this.deliveryNotifications = true,
    this.offersNotifications = true,
    this.notificationSound = true,
    this.notificationVibration = true,
  });

  SettingsState copyWith({
    Locale? locale,
    ThemeMode? themeMode,
    bool? allNotificationsEnabled,
    bool? orderStatusNotifications,
    bool? deliveryNotifications,
    bool? offersNotifications,
    bool? notificationSound,
    bool? notificationVibration,
  }) {
    return SettingsState(
      locale: locale ?? this.locale,
      themeMode: themeMode ?? this.themeMode,
      allNotificationsEnabled: allNotificationsEnabled ??
          this.allNotificationsEnabled,
      orderStatusNotifications: orderStatusNotifications ??
          this.orderStatusNotifications,
      deliveryNotifications: deliveryNotifications ??
          this.deliveryNotifications,
      offersNotifications: offersNotifications ?? this.offersNotifications,
      notificationSound: notificationSound ?? this.notificationSound,
      notificationVibration: notificationVibration ??
          this.notificationVibration,
    );
  }
}