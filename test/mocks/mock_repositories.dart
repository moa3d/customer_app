import 'package:mocktail/mocktail.dart';
import 'package:nomnow_app/features/cart/data/repositories/cart_repository.dart';
import 'package:nomnow_app/features/orders/data/repositories/order_repository.dart';

class MockCartRepository extends Mock implements CartRepository {}

class MockOrderRepository extends Mock implements OrderRepository {}
