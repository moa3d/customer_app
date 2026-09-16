import 'package:flutter_test/flutter_test.dart';
import 'package:nomnow_app/features/cart/presentation/bloc/mail_event.dart';
import 'package:nomnow_app/features/cart/domain/models/mail_item.dart';
import 'package:nomnow_app/features/location/data/models/address_model.dart';

void main() {
  group('MailEvent', () {
    test('FetchCartEvent has no props', () {
      expect(FetchCartEvent().props, []);
    });

    test('AddToCartEvent stores item', () {
      const item = MailItem(id: '1', foodId: 'f1', restaurantId: 'r1',
          title: 'Test', price: 1000, quantity: 1, imagePath: '');
      final event = AddToCartEvent(item);
      expect(event.item, item);
    });

    test('RemoveItemEvent stores id and restaurantId', () {
      final event = RemoveItemEvent(id: '1', restaurantId: 'r1');
      expect(event.id, '1');
      expect(event.restaurantId, 'r1');
    });

    test('ConfirmOrderEvent stores address and notes', () {
      final address = AddressModel(
        addressName: 'Home', country: 'SY', city: 'D',
        area: 'A', streetChoice: 'S', buildingDetail: 'B',
      );
      final event = ConfirmOrderEvent(deliveryAddress: address, notes: 'Fast');
      expect(event.deliveryAddress, address);
      expect(event.notes, 'Fast');
    });

    test('ConfirmOrderEvent notes can be null', () {
      final address = AddressModel(
        addressName: 'H', country: 'SY', city: 'D',
        area: 'A', streetChoice: 'S', buildingDetail: 'B',
      );
      final event = ConfirmOrderEvent(deliveryAddress: address);
      expect(event.notes, null);
    });

    test('CancelOrderEvent stores orderId', () {
      expect(CancelOrderEvent('ord1').orderId, 'ord1');
    });

    test('FetchUserOrdersEvent has no props', () {
      expect(FetchUserOrdersEvent().props, []);
    });

    test('ClearCartEvent has no props', () {
      expect(ClearCartEvent().props, []);
    });
  });
}
