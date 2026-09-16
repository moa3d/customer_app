import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nomnow_app/core/services/order_notifications_service.dart';
import 'package:nomnow_app/features/notifications/presentation/pages/notifications_page.dart';

/// الشاشة كانت تعرض بيانات تجريبية ثابتة، فكانت الاختبارات تفحص نصوصاً عربية
/// مكتوبة بأحرفها. صارت تقرأ من `OrderNotificationsService` الذي يبني نفسه من
/// أحداث السوكيت ويُحفظ في `SharedPreferences` — فالحقن يتم من هناك.

Widget wrapWithApp(Widget child) {
  return EasyLocalization(
    supportedLocales: const [Locale('en')],
    path: 'assets/translations',
    fallbackLocale: const Locale('en'),
    child: MaterialApp(home: child),
  );
}

/// سجلّ جاهز للحقن. `id` بصيغة `orderId::status` كما يبنيه `appendEvent`.
Map<String, dynamic> record(
  String orderId,
  String status, {
  bool isUnread = true,
}) =>
    {
      'id': '$orderId::$status',
      'orderId': orderId,
      'status': status,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'isUnread': isUnread,
    };

/// يزرع السجلّات في التخزين ثم يعيد تهيئة الخدمة لتقرأها.
Future<void> seed(List<Map<String, dynamic>> records) async {
  SharedPreferences.setMockInitialValues({
    OrderNotificationsService.storageKey: jsonEncode(records),
  });
  // الخدمة singleton: لا بدّ من تصفيرها بين الاختبارات وإلا سرّبت حالة سابقة
  OrderNotificationsService().dispose();
  await OrderNotificationsService().init();
}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // يسبق ensureInitialized لأن EasyLocalization يقرأ SharedPreferences
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    // الخدمة singleton تحتفظ بقائمتها في الذاكرة، فلا يكفي تصفير التخزين —
    // بلا هذا الزرع الفارغ تتسرّب سجلّات الاختبار السابق إلى التالي.
    await seed([]);
  });

  tearDown(() => OrderNotificationsService().dispose());

  group('NotificationsPage', () {
    testWidgets('يعرض سطراً لكل سجلّ محفوظ', (tester) async {
      await seed([
        record('order_a', 'on_the_way'),
        record('order_b', 'accepted', isUnread: false),
      ]);

      await tester.pumpWidget(wrapWithApp(NotificationsPage(movePage: (_) {})));
      await tester.pumpAndSettle();

      expect(find.text('notifications.status.on_the_way'.tr()), findsOneWidget);
      expect(find.text('notifications.status.accepted'.tr()), findsOneWidget);
    });

    testWidgets('يعرض العنوان في الشريط العلوي', (tester) async {
      await tester.pumpWidget(wrapWithApp(NotificationsPage(movePage: (_) {})));
      await tester.pumpAndSettle();

      expect(find.text('notifications.title'.tr()), findsOneWidget);
    });

    testWidgets('يعرض شرائح التصفية', (tester) async {
      await tester.pumpWidget(wrapWithApp(NotificationsPage(movePage: (_) {})));
      await tester.pumpAndSettle();

      expect(find.textContaining('notifications.all'), findsOneWidget);
      expect(find.textContaining('notifications.unread'), findsOneWidget);
    });

    testWidgets('يعرض زر «قراءة الكل»', (tester) async {
      await tester.pumpWidget(wrapWithApp(NotificationsPage(movePage: (_) {})));
      await tester.pumpAndSettle();

      expect(find.text('notifications.read_all'.tr()), findsOneWidget);
    });

    testWidgets('زر «مسح الكل» يظهر مع وجود سجلّات فقط', (tester) async {
      await tester.pumpWidget(wrapWithApp(NotificationsPage(movePage: (_) {})));
      await tester.pumpAndSettle();
      expect(find.text('notifications.clear_all'.tr()), findsNothing);

      await seed([record('order_a', 'delivered')]);
      await tester.pumpWidget(wrapWithApp(NotificationsPage(movePage: (_) {})));
      await tester.pumpAndSettle();
      expect(find.text('notifications.clear_all'.tr()), findsOneWidget);
    });

    testWidgets('«قراءة الكل» يُطفئ نقاط غير المقروء', (tester) async {
      await seed([record('order_a', 'accepted')]);

      await tester.pumpWidget(wrapWithApp(NotificationsPage(movePage: (_) {})));
      await tester.pumpAndSettle();

      await tester.tap(find.text('notifications.read_all'.tr()));
      await tester.pumpAndSettle();

      final unreadDots = find.byWidgetPredicate((w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration?)?.shape == BoxShape.circle &&
          (w.decoration as BoxDecoration?)?.color == Colors.deepOrange);
      expect(unreadDots, findsNothing);
    });

    testWidgets('«مسح الكل» يُفرغ القائمة', (tester) async {
      await seed([record('order_a', 'accepted')]);

      await tester.pumpWidget(wrapWithApp(NotificationsPage(movePage: (_) {})));
      await tester.pumpAndSettle();

      await tester.tap(find.text('notifications.clear_all'.tr()));
      await tester.pumpAndSettle();

      expect(find.text('notifications.status.accepted'.tr()), findsNothing);
    });

    testWidgets('زر الرجوع يستدعي movePage(0)', (tester) async {
      int? result;
      await tester.pumpWidget(
          wrapWithApp(NotificationsPage(movePage: (page) => result = page)));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back));
      expect(result, 0);
    });

    testWidgets('تصفية «غير المقروء» تُخفي المقروء', (tester) async {
      await seed([
        record('order_a', 'on_the_way'),
        record('order_b', 'accepted', isUnread: false),
      ]);

      await tester.pumpWidget(wrapWithApp(NotificationsPage(movePage: (_) {})));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('notifications.unread'));
      await tester.pumpAndSettle();

      expect(find.text('notifications.status.on_the_way'.tr()), findsOneWidget);
      expect(find.text('notifications.status.accepted'.tr()), findsNothing);
    });

    testWidgets('العودة إلى «الكل» تُظهر الجميع', (tester) async {
      await seed([
        record('order_a', 'on_the_way'),
        record('order_b', 'accepted', isUnread: false),
      ]);

      await tester.pumpWidget(wrapWithApp(NotificationsPage(movePage: (_) {})));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('notifications.unread'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('notifications.all'));
      await tester.pumpAndSettle();

      expect(find.text('notifications.status.on_the_way'.tr()), findsOneWidget);
      expect(find.text('notifications.status.accepted'.tr()), findsOneWidget);
    });

    testWidgets('لا overflow عند العرض', (tester) async {
      await seed([record('order_a', 'on_the_way')]);

      await tester.pumpWidget(wrapWithApp(NotificationsPage(movePage: (_) {})));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
