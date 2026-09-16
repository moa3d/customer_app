import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nomnow_app/features/notifications/presentation/widgets/notifications_filter_tabs.dart';

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

  group('NotificationsFilterTabs', () {
    testWidgets('displays All and Unread tabs with counts', (tester) async {
      await tester.pumpWidget(wrapWithApp(
        NotificationsFilterTabs(
          totalCount: 5,
          unreadCount: 2,
          showOnlyUnread: false,
          onChanged: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('notifications.all (5)'), findsOneWidget);
      expect(find.text('notifications.unread (2)'), findsOneWidget);
    });

    testWidgets('calls onChanged(false) when All tab is tapped', (tester) async {
      bool? result;
      await tester.pumpWidget(wrapWithApp(
        NotificationsFilterTabs(
          totalCount: 3,
          unreadCount: 1,
          showOnlyUnread: true,
          onChanged: (val) => result = val,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('notifications.all (3)'));
      expect(result, false);
    });

    testWidgets('calls onChanged(true) when Unread tab is tapped', (tester) async {
      bool? result;
      await tester.pumpWidget(wrapWithApp(
        NotificationsFilterTabs(
          totalCount: 3,
          unreadCount: 1,
          showOnlyUnread: false,
          onChanged: (val) => result = val,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('notifications.unread (1)'));
      expect(result, true);
    });

    testWidgets('All tab is active when showOnlyUnread is false', (tester) async {
      await tester.pumpWidget(wrapWithApp(
        NotificationsFilterTabs(
          totalCount: 10,
          unreadCount: 3,
          showOnlyUnread: false,
          onChanged: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      final allBtn = tester.widget<AnimatedContainer>(
        find.byWidgetPredicate((w) {
          if (w is! AnimatedContainer) return false;
          final child = w.child;
          if (child is! Center) return false;
          final text = child.child;
          if (text is! Text) return false;
          return text.data?.contains('notifications.all') == true;
        }),
      );

      final dec = allBtn.decoration as BoxDecoration;
      expect(dec.color, isNotNull);
    });

    testWidgets('Unread tab is active when showOnlyUnread is true', (tester) async {
      await tester.pumpWidget(wrapWithApp(
        NotificationsFilterTabs(
          totalCount: 10,
          unreadCount: 3,
          showOnlyUnread: true,
          onChanged: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      final unreadBtn = tester.widget<AnimatedContainer>(
        find.byWidgetPredicate((w) {
          if (w is! AnimatedContainer) return false;
          final child = w.child;
          if (child is! Center) return false;
          final text = child.child;
          if (text is! Text) return false;
          return text.data?.contains('notifications.unread') == true;
        }),
      );

      final dec = unreadBtn.decoration as BoxDecoration;
      expect(dec.color, isNotNull);
    });
  });
}
