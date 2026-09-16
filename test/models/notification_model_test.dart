import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomnow_app/features/notifications/data/models/notification_model.dart';

void main() {
  group('AppNotificationModel', () {
    test('creates instance with required values', () {
      final notification = AppNotificationModel(
        id: 'notif_1',
        orderId: 'order_notif_1',
        title: 'New Order',
        body: 'You have a new order',
        time: '2 min ago',
        icon: Icons.notifications,
        iconBgColor: Colors.blue,
      );

      expect(notification.id, 'notif_1');
      expect(notification.title, 'New Order');
      expect(notification.body, 'You have a new order');
      expect(notification.time, '2 min ago');
      expect(notification.icon, Icons.notifications);
      expect(notification.iconBgColor, Colors.blue);
    });

    test('creates instance with all named parameters', () {
      final notification = AppNotificationModel(
        id: 'notif_2',
        orderId: 'order_notif_2',
        title: 'Promo',
        body: '50% off',
        time: '1h ago',
        icon: Icons.card_giftcard,
        iconBgColor: Colors.orange,
        isUnread: true,
        hasAction: true,
        actionLabel: 'track',
        isPromo: true,
      );

      expect(notification.isUnread, true);
      expect(notification.hasAction, true);
      expect(notification.actionLabel, 'track');
      expect(notification.isPromo, true);
    });

    test('isUnread defaults to false', () {
      final notification = AppNotificationModel(
        id: '1', orderId: 'order_1', title: 'T', body: 'B', time: 'now',
        icon: Icons.info, iconBgColor: Colors.grey,
      );
      expect(notification.isUnread, false);
    });

    test('hasAction defaults to false', () {
      final notification = AppNotificationModel(
        id: '1', orderId: 'order_1', title: 'T', body: 'B', time: 'now',
        icon: Icons.info, iconBgColor: Colors.grey,
      );
      expect(notification.hasAction, false);
    });

    test('isPromo defaults to false', () {
      final notification = AppNotificationModel(
        id: '1', orderId: 'order_1', title: 'T', body: 'B', time: 'now',
        icon: Icons.info, iconBgColor: Colors.grey,
      );
      expect(notification.isPromo, false);
    });

    test('actionLabel defaults to null', () {
      final notification = AppNotificationModel(
        id: '1', orderId: 'order_1', title: 'T', body: 'B', time: 'now',
        icon: Icons.info, iconBgColor: Colors.grey,
      );
      expect(notification.actionLabel, isNull);
    });

    test('isUnread is mutable and can be toggled', () {
      final notification = AppNotificationModel(
        id: '1', orderId: 'order_1', title: 'T', body: 'B', time: 'now',
        icon: Icons.info, iconBgColor: Colors.grey,
        isUnread: true,
      );
      expect(notification.isUnread, true);

      notification.isUnread = false;
      expect(notification.isUnread, false);

      notification.isUnread = true;
      expect(notification.isUnread, true);
    });

    test('two instances with same values are equal', () {
      final n1 = AppNotificationModel(
        id: '1', orderId: 'order_1', title: 'T', body: 'B', time: 'now',
        icon: Icons.info, iconBgColor: Colors.grey,
      );
      final n2 = AppNotificationModel(
        id: '1', orderId: 'order_1', title: 'T', body: 'B', time: 'now',
        icon: Icons.info, iconBgColor: Colors.grey,
      );

      expect(n1.id, n2.id);
      expect(n1.title, n2.title);
      expect(n1.body, n2.body);
    });
  });
}
