enum OrderStatus {
  notConfirmed,
  pending,
  accepted,
  preparing,
  ready,
  pickedUp,
  onTheWay,
  deliveredByDriver,
  delivered,
  cancelled,
  unknown,
}

class Order {
  final String id;
  final String orderNumber;
  final OrderStatus status;
  final double totalPrice;
  final String? restaurantName;
  final String driverLocation;

  Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.totalPrice,
    this.restaurantName,
    this.driverLocation = 'N/A',
  });

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['_id']?.toString() ?? '',
      orderNumber: map['orderNumber']?.toString() ?? '',
      status: mapStatus(map['orderStatus']?.toString()),
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
      restaurantName: map['restaurantId'] is Map
          ? map['restaurantId']['name']?.toString()
          : null,
      driverLocation: 'N/A',
    );
  }

  /// المصدر الوحيد لتحويل حالة الباك إلى Enum — يستخدمه الـ Cubit أيضاً.
  /// القيم مطابقة حرفياً لـ orderStatus enum في models/Order.js
  static OrderStatus mapStatus(String? status) {
    switch (status) {
      case 'not_confirmed':
        return OrderStatus.notConfirmed;
      case 'pending':
        return OrderStatus.pending;
      case 'accepted':
        return OrderStatus.accepted;
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready':
        return OrderStatus.ready;
      case 'picked_up':
        return OrderStatus.pickedUp;
      case 'on_the_way':
        return OrderStatus.onTheWay;
      case 'delivered_by_driver':
        return OrderStatus.deliveredByDriver;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.unknown;
    }
  }

  /// النص الخام المستخدم كمفتاح ترجمة في الواجهة
  static String rawOf(OrderStatus s) {
    switch (s) {
      case OrderStatus.notConfirmed:
        return 'not_confirmed';
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.accepted:
        return 'accepted';
      case OrderStatus.preparing:
        return 'preparing';
      case OrderStatus.ready:
        return 'ready';
      case OrderStatus.pickedUp:
        return 'picked_up';
      case OrderStatus.onTheWay:
        return 'on_the_way';
      case OrderStatus.deliveredByDriver:
        return 'delivered_by_driver';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
      case OrderStatus.unknown:
        return 'pending';
    }
  }

  String get statusKey => rawOf(status);

  /// هل الطلب ما زال جارياً (لاستعادة التتبّع عند فتح التطبيق)
  bool get isActive => const {
        OrderStatus.pending,
        OrderStatus.accepted,
        OrderStatus.preparing,
        OrderStatus.ready,
        OrderStatus.pickedUp,
        OrderStatus.onTheWay,
        OrderStatus.deliveredByDriver,
      }.contains(status);

  Order copyWith({
    String? id,
    String? orderNumber,
    OrderStatus? status,
    double? totalPrice,
    String? restaurantName,
    String? driverLocation,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      status: status ?? this.status,
      totalPrice: totalPrice ?? this.totalPrice,
      restaurantName: restaurantName ?? this.restaurantName,
      driverLocation: driverLocation ?? this.driverLocation,
    );
  }
}
