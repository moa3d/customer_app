import 'package:flutter_test/flutter_test.dart';
import 'package:nomnow_app/features/orders/data/models/order_model.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Order', () {
    test('fromMap creates model correctly for pending', () {
      final order = Order.fromMap(createTestOrderJson());

      expect(order.id, 'order_1');
      expect(order.orderNumber, 'ORD-001');
      expect(order.status, OrderStatus.pending);
      expect(order.totalPrice, 15000);
      expect(order.restaurantName, 'Test Restaurant');
    });

    test('statuses are mapped correctly', () {
      // القائمة تطابق enum الباك في models/Order.js حرفياً.
      // كان الاختبار يفحص 'out_for_delivery' ولا وجود لها في الباك إطلاقاً؛
      // الحالة الصحيحة 'on_the_way'.
      final statusTests = {
        'not_confirmed': OrderStatus.notConfirmed,
        'pending': OrderStatus.pending,
        'accepted': OrderStatus.accepted,
        'preparing': OrderStatus.preparing,
        'ready': OrderStatus.ready,
        'picked_up': OrderStatus.pickedUp,
        'on_the_way': OrderStatus.onTheWay,
        'delivered': OrderStatus.delivered,
        'cancelled': OrderStatus.cancelled,
        // حالة مجهولة أو غائبة تُصنَّف `unknown` لا `pending`: تصنيفها
        // «قيد التنفيذ» كان سيُظهر طلباً مشكوكاً فيه كطلب جارٍ.
        'unknown_status': OrderStatus.unknown,
        null: OrderStatus.unknown,
      };

      for (final entry in statusTests.entries) {
        final json = createTestOrderJson(status: entry.key ?? 'unknown');
        if (entry.key == null) {
          json.remove('orderStatus');
        } else {
          json['orderStatus'] = entry.key;
        }
        final order = Order.fromMap(json);
        expect(order.status, entry.value,
            reason: 'Status "${entry.key}" should map to ${entry.value}');
      }
    });

    test('fromMap handles missing restaurantId gracefully', () {
      final json = createTestOrderJson()..remove('restaurantId');
      final order = Order.fromMap(json);
      expect(order.restaurantName, null);
    });

    test('copyWith creates new instance with updated fields', () {
      final order = Order.fromMap(createTestOrderJson());
      final copied = order.copyWith(status: OrderStatus.delivered, totalPrice: 20000);

      expect(copied.id, order.id);
      expect(copied.orderNumber, order.orderNumber);
      expect(copied.status, OrderStatus.delivered);
      expect(copied.totalPrice, 20000);
      expect(copied.restaurantName, order.restaurantName);
    });

    test('copyWith preserves original when no args given', () {
      final order = Order.fromMap(createTestOrderJson());
      final copied = order.copyWith();
      expect(copied.id, order.id);
      expect(copied.status, order.status);
      expect(copied.totalPrice, order.totalPrice);
    });

    test('default driverLocation is N/A', () {
      final order = Order.fromMap(createTestOrderJson());
      expect(order.driverLocation, 'N/A');
    });
  });
}
