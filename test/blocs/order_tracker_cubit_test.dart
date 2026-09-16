import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nomnow_app/core/services/socket_service.dart';
import 'package:nomnow_app/features/orders/bloc/order_tracker_cubit.dart';
import 'package:nomnow_app/features/orders/bloc/order_tracker_state.dart';
import 'package:nomnow_app/features/orders/data/models/order_model.dart';

class MockSocketService extends Mock implements SocketService {}

void main() {
  late MockSocketService mockSocket;
  late StreamController<Map<String, dynamic>> statusController;

  setUp(() {
    mockSocket = MockSocketService();
    statusController = StreamController<Map<String, dynamic>>.broadcast();
    // `listenToOrderStatus` يُرجع StreamSubscription غير قابل للعدم. وبلا هذا
    // التوكيد كان الـ mock يُرجع null فيسقط الاختبار بـ
    // "type 'Null' is not a subtype of type 'StreamSubscription<...>'" —
    // عيب في الاختبار لا في الكود.
    when(() => mockSocket.listenToOrderStatus(any())).thenAnswer(
      (invocation) => statusController.stream.listen(
        invocation.positionalArguments.first as void Function(
            Map<String, dynamic>),
      ),
    );
  });

  tearDown(() => statusController.close());

  group('OrderTrackerCubit', () {
    final order = Order(
      id: 'ord_1', orderNumber: 'ORD-001', totalPrice: 15000,
      status: OrderStatus.pending,
    );

    blocTest<OrderTrackerCubit, OrderTrackerState>(
      'initial state is OrderInitial',
      build: () => OrderTrackerCubit(socketService: mockSocket),
      expect: () => [],
    );

    blocTest<OrderTrackerCubit, OrderTrackerState>(
      'startTracking emits OrderTracking',
      build: () => OrderTrackerCubit(socketService: mockSocket),
      act: (cubit) => cubit.startTracking(order),
      expect: () => [
        isA<OrderTracking>().having((s) => s.order.id, 'id', 'ord_1'),
      ],
    );

    blocTest<OrderTrackerCubit, OrderTrackerState>(
      'startTracking registers socket listener',
      build: () => OrderTrackerCubit(socketService: mockSocket),
      act: (cubit) => cubit.startTracking(order),
      verify: (_) {
        verify(() => mockSocket.listenToOrderStatus(any())).called(1);
      },
    );
  });
}
