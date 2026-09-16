import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nomnow_app/core/bloc/settings/settings_cubit.dart';
import 'package:nomnow_app/features/notifications/presentation/pages/notification_settings_page.dart';

Widget wrapWithApp(Widget child, SettingsCubit cubit) {
  return EasyLocalization(
    supportedLocales: const [Locale('en')],
    path: 'assets/translations',
    fallbackLocale: const Locale('en'),
    child: BlocProvider<SettingsCubit>.value(
      value: cubit,
      child: MaterialApp(home: child),
    ),
  );
}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  group('NotificationSettingsPage', () {
    late SettingsCubit cubit;

    setUp(() {
      cubit = SettingsCubit();
    });

    tearDown(() {
      cubit.close();
    });

    testWidgets('displays page title', (tester) async {
      await tester.pumpWidget(wrapWithApp(
        const NotificationSettingsPage(),
        cubit,
      ));
      await tester.pumpAndSettle();

      expect(find.text('notifications_title'.tr()), findsOneWidget);
    });

    testWidgets('displays all notifications card with master switch', (tester) async {
      await tester.pumpWidget(wrapWithApp(
        const NotificationSettingsPage(),
        cubit,
      ));
      await tester.pumpAndSettle();

      expect(find.text('all_notifications_title'.tr()), findsOneWidget);
      expect(find.text('all_notifications_subtitle'.tr()), findsOneWidget);
    });

    testWidgets('displays notification types section', (tester) async {
      await tester.pumpWidget(wrapWithApp(
        const NotificationSettingsPage(),
        cubit,
      ));
      await tester.pumpAndSettle();

      expect(find.text('notification_types_title'.tr()), findsOneWidget);
      expect(find.text('order_status_title'.tr()), findsOneWidget);
      expect(find.text('delivery_title'.tr()), findsOneWidget);
      // «العروض» محذوف: لا وجود لإشعارات عروض في النظام، وكان مفتاحاً لا
      // يقرؤه شيء
      expect(find.text('offers_and_discounts_title'.tr()), findsNothing);
    });

    // الصوت والاهتزاز يحكمهما إعداد قناة النظام (order_status) لا التطبيق،
    // فحُذف القسم بدل إبقاء مفتاحين لا أثر لهما.
    testWidgets('no longer shows the unenforceable system section',
        (tester) async {
      await tester.pumpWidget(wrapWithApp(
        const NotificationSettingsPage(),
        cubit,
      ));
      await tester.pumpAndSettle();

      expect(find.text('notification_settings_title'.tr()), findsNothing);
      expect(find.text('sound_title'.tr()), findsNothing);
      expect(find.text('vibration_title'.tr()), findsNothing);
    });

    testWidgets('master switch toggles all notifications', (tester) async {
      await tester.pumpWidget(wrapWithApp(
        const NotificationSettingsPage(),
        cubit,
      ));
      await tester.pumpAndSettle();

      final switches = find.byType(Switch);
      await tester.tap(switches.first);
      await tester.pumpAndSettle();

      expect(cubit.state.allNotificationsEnabled, false);
      expect(cubit.state.orderStatusNotifications, false);
      expect(cubit.state.deliveryNotifications, false);
      expect(cubit.state.offersNotifications, false);
    });

    testWidgets('order status switch toggles independently', (tester) async {
      await tester.pumpWidget(wrapWithApp(
        const NotificationSettingsPage(),
        cubit,
      ));
      await tester.pumpAndSettle();

      final switches = find.byType(Switch);
      await tester.tap(switches.at(1));
      await tester.pumpAndSettle();

      expect(cubit.state.orderStatusNotifications, false);
      expect(cubit.state.deliveryNotifications, true);
    });

    testWidgets('renders without overflow', (tester) async {
      await tester.pumpWidget(wrapWithApp(
        const NotificationSettingsPage(),
        cubit,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
