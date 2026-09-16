import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nomnow_app/core/bloc/settings/settings_cubit.dart';
import 'package:nomnow_app/core/bloc/settings/settings_state.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsCubit', () {
    blocTest<SettingsCubit, SettingsState>(
      'loads defaults when no saved preferences',
      build: () => SettingsCubit(),
      wait: const Duration(milliseconds: 50),
      expect: () => [
        isA<SettingsState>().having((s) => s.locale.languageCode, 'lang', 'ar')
            .having((s) => s.themeMode, 'theme', ThemeMode.system)
            .having((s) => s.allNotificationsEnabled, 'allNotif', true),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'changeLanguage updates locale and saves to SharedPreferences',
      build: () => SettingsCubit(),
      act: (cubit) => cubit.changeLanguage(const Locale('en')),
      wait: const Duration(milliseconds: 50),
      skip: 1, // skip loadSettings emission
      expect: () => [
        isA<SettingsState>().having((s) => s.locale.languageCode, 'lang', 'en'),
      ],
      verify: (_) async {
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('language_code'), 'en');
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'updateNotification toggles order status',
      build: () => SettingsCubit(),
      act: (cubit) => cubit.updateNotification('orderStatus', false),
      wait: const Duration(milliseconds: 50),
      expect: () => [
        isA<SettingsState>().having((s) => s.locale.languageCode, 'lang', 'ar'),
        isA<SettingsState>().having(
          (s) => s.orderStatusNotifications, 'orderStatus', false),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'updateNotification toggles delivery',
      build: () => SettingsCubit(),
      act: (cubit) => cubit.updateNotification('delivery', false),
      wait: const Duration(milliseconds: 50),
      skip: 1,
      expect: () => [
        isA<SettingsState>().having(
          (s) => s.deliveryNotifications, 'delivery', false),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'toggleAllNotifications disables all',
      build: () => SettingsCubit(),
      act: (cubit) => cubit.toggleAllNotifications(false),
      wait: const Duration(milliseconds: 50),
      skip: 1,
      expect: () => [
        isA<SettingsState>()
            .having((s) => s.allNotificationsEnabled, 'all', false)
            .having((s) => s.orderStatusNotifications, 'order', false)
            .having((s) => s.deliveryNotifications, 'delivery', false)
            .having((s) => s.offersNotifications, 'offers', false),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'changeTheme updates theme mode',
      build: () => SettingsCubit(),
      act: (cubit) => cubit.changeTheme(ThemeMode.dark),
      wait: const Duration(milliseconds: 50),
      skip: 1,
      expect: () => [
        isA<SettingsState>().having((s) => s.themeMode, 'theme', ThemeMode.dark),
      ],
      verify: (_) async {
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('theme_mode'), ThemeMode.dark.index);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'updateNotification toggles offers',
      build: () => SettingsCubit(),
      act: (cubit) => cubit.updateNotification('offers', false),
      wait: const Duration(milliseconds: 50),
      skip: 1,
      expect: () => [
        isA<SettingsState>().having(
          (s) => s.offersNotifications, 'offers', false),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'updateNotification toggles sound',
      build: () => SettingsCubit(),
      act: (cubit) => cubit.updateNotification('sound', false),
      wait: const Duration(milliseconds: 50),
      skip: 1,
      expect: () => [
        isA<SettingsState>().having(
          (s) => s.notificationSound, 'sound', false),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'updateNotification toggles vibration',
      build: () => SettingsCubit(),
      act: (cubit) => cubit.updateNotification('vibration', false),
      wait: const Duration(milliseconds: 50),
      skip: 1,
      expect: () => [
        isA<SettingsState>().having(
          (s) => s.notificationVibration, 'vibration', false),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'toggleAllNotifications enables all back',
      build: () => SettingsCubit(),
      act: (cubit) {
        cubit.toggleAllNotifications(false);
        cubit.toggleAllNotifications(true);
      },
      wait: const Duration(milliseconds: 100),
      skip: 1,
      expect: () => [
        isA<SettingsState>().having((s) => s.allNotificationsEnabled, 'all', false),
        isA<SettingsState>().having((s) => s.allNotificationsEnabled, 'all', true)
            .having((s) => s.orderStatusNotifications, 'order', true)
            .having((s) => s.deliveryNotifications, 'delivery', true)
            .having((s) => s.offersNotifications, 'offers', true),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'persists notification values to SharedPreferences',
      build: () => SettingsCubit(),
      act: (cubit) async {
        await cubit.updateNotification('orderStatus', false);
        await cubit.updateNotification('delivery', false);
        await cubit.updateNotification('offers', false);
        await cubit.updateNotification('sound', false);
        await cubit.updateNotification('vibration', false);
      },
      wait: const Duration(milliseconds: 100),
      verify: (_) async {
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('order_status_notif'), false);
        expect(prefs.getBool('delivery_notif'), false);
        expect(prefs.getBool('offers_notif'), false);
        expect(prefs.getBool('notif_sound'), false);
        expect(prefs.getBool('vibration_notif'), false);
      },
    );
  });
}
