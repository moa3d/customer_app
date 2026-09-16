import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nomnow_app/features/notifications/presentation/widgets/empty_notifications.dart';

Widget wrapWithApp(Widget child) {
  return EasyLocalization(
    supportedLocales: const [Locale('en')],
    path: 'assets/translations',
    fallbackLocale: const Locale('en'),
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  group('EmptyNotifications', () {
    testWidgets('displays notification icon', (tester) async {
      await tester.pumpWidget(wrapWithApp(const EmptyNotifications()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.notifications_none_outlined), findsOneWidget);
    });

    testWidgets('displays no notifications title', (tester) async {
      await tester.pumpWidget(wrapWithApp(const EmptyNotifications()));
      await tester.pumpAndSettle();

      expect(find.text('notifications.no_notifications'.tr()), findsOneWidget);
    });

    testWidgets('displays read all message', (tester) async {
      await tester.pumpWidget(wrapWithApp(const EmptyNotifications()));
      await tester.pumpAndSettle();

      expect(find.text('notifications.read_all_message'.tr()), findsOneWidget);
    });

    testWidgets('renders without overflow', (tester) async {
      await tester.pumpWidget(wrapWithApp(const EmptyNotifications()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('shows mark_read icon when isAllRead', (tester) async {
      await tester
          .pumpWidget(wrapWithApp(const EmptyNotifications(isAllRead: true)));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.mark_email_read_outlined), findsOneWidget);
    });

    testWidgets('shows no unread title when isAllRead', (tester) async {
      await tester
          .pumpWidget(wrapWithApp(const EmptyNotifications(isAllRead: true)));
      await tester.pumpAndSettle();

      expect(find.text('notifications.no_unread'.tr()), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none_outlined), findsNothing);
    });
  });
}
