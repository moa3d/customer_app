
import '../data/models/order_model.dart';

abstract class OrderTrackerState{}

class OrderInitial extends OrderTrackerState{}
class OrderLoading extends OrderTrackerState{}

class OrderTracking extends OrderTrackerState{
  late final Order order;
  final Map<String, dynamic>? driverData;
  OrderTracking({required this.order, this.driverData});
}
class OrderDelivered extends OrderTrackerState{}
class OrderCancelled extends OrderTrackerState{}
class OrderFailed extends OrderTrackerState{
  final String error;
  OrderFailed({required this.error});
}