import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/socket_service.dart';
import '../data/models/order_model.dart';
import '../data/repositories/order_repository.dart';
import 'order_tracker_state.dart';

class OrderTrackerCubit extends Cubit<OrderTrackerState> {
  final SocketService _socketService;
  final OrderRepository _orderRepository;

  Order? _currentOrder;
  Map<String, dynamic>? _driverData;
  StreamSubscription<Map<String, dynamic>>? _orderStatusSub;

  OrderTrackerCubit({
    SocketService? socketService,
    OrderRepository? orderRepository,
  })  : _socketService = socketService ?? SocketService(),
        _orderRepository = orderRepository ?? OrderRepository(),
        super(OrderInitial());

  void startTracking(Order initialOrder, {Map<String, dynamic>? driverData}) {
    _currentOrder = initialOrder;
    _driverData = driverData;
    emit(OrderTracking(order: initialOrder, driverData: _driverData));

    _orderStatusSub?.cancel();
    _orderStatusSub = _socketService.listenToOrderStatus((data) {
      if (isClosed) return;
      if (data['orderId']?.toString() != initialOrder.id) return;

      final newStatus = Order.mapStatus(data['status']?.toString());

      // حالة غير معروفة → نتجاهلها بدل الرجوع لـ pending
      if (newStatus == OrderStatus.unknown) return;

      if (newStatus == OrderStatus.delivered) {
        emit(OrderDelivered());
        return;
      }
      if (newStatus == OrderStatus.cancelled) {
        emit(OrderCancelled());
        return;
      }

      _currentOrder =
          (_currentOrder ?? initialOrder).copyWith(status: newStatus);
      emit(OrderTracking(order: _currentOrder!, driverData: _driverData));

      // السائق يُسنَد فعلياً عند picked_up وليس accepted
      final driverAssigned = newStatus == OrderStatus.pickedUp ||
          newStatus == OrderStatus.onTheWay ||
          newStatus == OrderStatus.deliveredByDriver;

      if (_driverData == null && driverAssigned) {
        _refetchOrderWithDriver(initialOrder.id);
      }
    });
  }

  @override
  Future<void> close() {
    _orderStatusSub?.cancel();
    return super.close();
  }

  Future<void> _refetchOrderWithDriver(String orderId) async {
    try {
      final orders = await _orderRepository.getUserOrders();
      for (final o in orders) {
        if (o is! Map) continue;
        if (o['_id']?.toString() != orderId) continue;

        final driver = o['driverId'];
        if (driver is Map && driver['name'] != null) {
          _driverData = Map<String, dynamic>.from(driver);
          if (!isClosed && _currentOrder != null) {
            emit(OrderTracking(order: _currentOrder!, driverData: _driverData));
          }
        }
        return;
      }
    } catch (_) {
      // فشل الجلب لا يوقف التتبّع — سنحاول عند التحديث التالي
    }
  }

  // v3.0 — حُذفت دالة confirmDelivery: كانت تستدعي
  // _socketService.confirmOrderDelivery المحذوفة (حدث order:confirmDelivery
  // لم يعد له مستمع في الباك). لم يعد للزبون أي إجراء تأكيد تسليم.
}
