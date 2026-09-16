import 'package:flutter_test/flutter_test.dart';
import 'package:nomnow_app/features/orders/bloc/order_tracker_state.dart';
import 'package:nomnow_app/features/orders/data/models/order_model.dart';

void main() {
  group('OrderTrackerState', () {
    test('OrderInitial is an instance', () {
      expect(OrderInitial(), isA<OrderTrackerState>());
    });

    test('OrderLoading is an instance', () {
      expect(OrderLoading(), isA<OrderTrackerState>());
    });

    test('OrderTracking stores order', () {
      final order = Order.fromMap({
        '_id': 'ord1',
        'orderNumber': 'ORD-001',
        'orderStatus': 'pending',
        'totalPrice': 10000,
      });
      final state = OrderTracking(order: order);
      expect(state.order.id, 'ord1');
      expect(state.order.status, OrderStatus.pending);
    });

    test('OrderDelivered is an instance', () {
      expect(OrderDelivered(), isA<OrderTrackerState>());
    });

    test('OrderCancelled is an instance', () {
      expect(OrderCancelled(), isA<OrderTrackerState>());
    });

    test('OrderFailed stores error', () {
      final state = OrderFailed(error: 'Network error');
      expect(state.error, 'Network error');
    });
  });
}
