import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomnow_app/core/bloc/settings/settings_state.dart';

void main() {
  group('SettingsState', () {
    final defaultState = SettingsState(
      locale: const Locale('ar'),
      themeMode: ThemeMode.system,
    );

    test('defaults are correct', () {
      expect(defaultState.locale, const Locale('ar'));
      expect(defaultState.themeMode, ThemeMode.system);
      expect(defaultState.allNotificationsEnabled, true);
      expect(defaultState.orderStatusNotifications, true);
      expect(defaultState.deliveryNotifications, true);
      expect(defaultState.offersNotifications, true);
      expect(defaultState.notificationSound, true);
      expect(defaultState.notificationVibration, true);
    });

    test('copyWith updates locale', () {
      final copied = defaultState.copyWith(locale: const Locale('en'));
      expect(copied.locale, const Locale('en'));
      expect(copied.themeMode, ThemeMode.system);
    });

    test('copyWith updates themeMode', () {
      final copied = defaultState.copyWith(themeMode: ThemeMode.dark);
      expect(copied.themeMode, ThemeMode.dark);
    });

    test('copyWith toggles notification settings', () {
      final copied = defaultState.copyWith(
        allNotificationsEnabled: false,
        orderStatusNotifications: false,
        notificationSound: false,
      );
      expect(copied.allNotificationsEnabled, false);
      expect(copied.orderStatusNotifications, false);
      expect(copied.notificationSound, false);
      expect(copied.deliveryNotifications, true);
    });

    test('copyWith preserves all when no args', () {
      final copied = defaultState.copyWith();
      expect(copied.locale, defaultState.locale);
      expect(copied.themeMode, defaultState.themeMode);
      expect(copied.allNotificationsEnabled, true);
    });
  });
}
