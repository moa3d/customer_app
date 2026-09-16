import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nomnow_app/features/notifications/data/models/notification_model.dart';
import 'package:nomnow_app/features/notifications/presentation/widgets/notification_card.dart';

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

  group('NotificationCard', () {
    late AppNotificationModel unreadNotification;
    late AppNotificationModel readNotification;
    late AppNotificationModel actionNotification;

    setUp(() {
      unreadNotification = AppNotificationModel(
        id: '1',
        orderId: 'order_1',
        title: 'Order on the way',
        body: 'Driver is coming',
        time: '5 min ago',
        icon: Icons.delivery_dining,
        iconBgColor: Colors.green,
        isUnread: true,
      );

      readNotification = AppNotificationModel(
        id: '2',
        orderId: 'order_2',
        title: 'Order accepted',
        body: 'Restaurant started preparing',
        time: '1 hour ago',
        icon: Icons.inventory_2,
        iconBgColor: Colors.blue,
        isUnread: false,
      );

      actionNotification = AppNotificationModel(
        id: '3',
        orderId: 'order_3',
        title: 'Track order',
        body: 'Your order is on the way',
        time: '10 min ago',
        icon: Icons.delivery_dining,
        iconBgColor: Colors.green,
        isUnread: true,
        hasAction: true,
        actionLabel: 'track',
      );
    });

    testWidgets('displays title, body, and time', (tester) async {
      await tester.pumpWidget(wrapWithApp(
        NotificationCard(
          item: readNotification,
          isRtl: false,
          onDelete: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Order accepted'), findsOneWidget);
      expect(find.text('Restaurant started preparing'), findsOneWidget);
      expect(find.text('1 hour ago'), findsOneWidget);
    });

    testWidgets('shows orange dot for unread notification', (tester) async {
      await tester.pumpWidget(wrapWithApp(
        NotificationCard(
          item: unreadNotification,
          isRtl: false,
          onDelete: () {},
        ),
      ));
      await tester.pumpAndSettle();

      final container = tester.widget<Container>(
        find.byWidgetPredicate((w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration?)?.shape == BoxShape.circle &&
            (w.decoration as BoxDecoration?)?.color == Colors.deepOrange),
      );
      expect(container, isNotNull);
    });

    testWidgets('hides orange dot for read notification', (tester) async {
      await tester.pumpWidget(wrapWithApp(
        NotificationCard(
          item: readNotification,
          isRtl: false,
          onDelete: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate((w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration?)?.shape == BoxShape.circle &&
            (w.decoration as BoxDecoration?)?.color == Colors.deepOrange),
        findsNothing,
      );
    });

    testWidgets('shows action button when hasAction is true', (tester) async {
      await tester.pumpWidget(wrapWithApp(
        NotificationCard(
          item: actionNotification,
          isRtl: false,
          onDelete: () {},
          onAction: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('notifications.track'.tr()), findsOneWidget);
    });

    // كان الزر يُرسم دائماً كـ Container بلا معالج ضغط: يبدو قابلاً للضغط
    // ولا يستجيب. الآن لا يظهر إلا حين يكون له إجراء فعلي.
    testWidgets('hides the action button when no action is given',
        (tester) async {
      await tester.pumpWidget(wrapWithApp(
        NotificationCard(
          item: actionNotification,
          isRtl: false,
          onDelete: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('notifications.track'.tr()), findsNothing);
    });

    testWidgets('action button invokes onAction when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrapWithApp(
        NotificationCard(
          item: actionNotification,
          isRtl: false,
          onDelete: () {},
          onAction: () => tapped = true,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('notifications.track'.tr()));
      expect(tapped, isTrue);
    });

    testWidgets('hides action button when hasAction is false', (tester) async {
      await tester.pumpWidget(wrapWithApp(
        NotificationCard(
          item: readNotification,
          isRtl: false,
          onDelete: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('notifications.track'.tr()), findsNothing);
    });

    testWidgets('calls onDelete when delete icon is tapped', (tester) async {
      bool deleted = false;
      await tester.pumpWidget(wrapWithApp(
        NotificationCard(
          item: readNotification,
          isRtl: false,
          onDelete: () => deleted = true,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      expect(deleted, true);
    });

    testWidgets('calls onMarkAsRead when check icon is tapped', (tester) async {
      bool markedRead = false;
      await tester.pumpWidget(wrapWithApp(
        NotificationCard(
          item: unreadNotification,
          isRtl: false,
          onDelete: () {},
          onMarkAsRead: () => markedRead = true,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.check));
      expect(markedRead, true);
    });

    testWidgets('does not show check icon for read notification', (tester) async {
      await tester.pumpWidget(wrapWithApp(
        NotificationCard(
          item: readNotification,
          isRtl: false,
          onDelete: () {},
          onMarkAsRead: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('shows icon in colored container', (tester) async {
      await tester.pumpWidget(wrapWithApp(
        NotificationCard(
          item: unreadNotification,
          isRtl: false,
          onDelete: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delivery_dining), findsOneWidget);
    });

    testWidgets('has orange border when unread', (tester) async {
      await tester.pumpWidget(wrapWithApp(
        NotificationCard(
          item: unreadNotification,
          isRtl: false,
          onDelete: () {},
        ),
      ));
      await tester.pumpAndSettle();

      final container = tester.widget<Container>(
        find.byWidgetPredicate((w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration?)?.border != null &&
            (w.decoration as BoxDecoration?)?.borderRadius != null),
      );
      expect(container, isNotNull);
    });

    testWidgets('has no border when read', (tester) async {
      await tester.pumpWidget(wrapWithApp(
        NotificationCard(
          item: readNotification,
          isRtl: false,
          onDelete: () {},
        ),
      ));
      await tester.pumpAndSettle();

      final containers = tester.widgetList<Container>(
        find.byWidgetPredicate((w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration?)?.borderRadius != null),
      );

      final hasBorder = containers.any((c) =>
          (c.decoration as BoxDecoration?)?.border != null);
      expect(hasBorder, false);
    });
  });
}
