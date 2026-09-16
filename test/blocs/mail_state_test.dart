import 'package:flutter_test/flutter_test.dart';
import 'package:nomnow_app/features/cart/presentation/bloc/mail_state.dart';
import 'package:nomnow_app/features/cart/domain/models/mail_item.dart';

void main() {
  group('MailState', () {
    test('initial state has correct defaults', () {
      final state = MailState();
      expect(state.items, []);
      expect(state.orders, []);
      expect(state.status, CartStatus.initial);
      expect(state.deliveryFee, 0.0);
      expect(state.originalDeliveryFee, 0.0);
      expect(state.currency, "");
      expect(state.itemsPrice, 0.0);
      expect(state.errorMessage, null);
      expect(state.hasFreeDelivery, isFalse);
    });

    test('totalAmount returns 0 when no items and no backend price', () {
      expect(MailState().totalAmount, 0.0);
    });

    test('totalAmount uses backend items price when available', () {
      final state = MailState(itemsPrice: 15000);
      expect(state.totalAmount, 15000);
    });

    test('totalAmount sums item prices when no backend price', () {
      final items = [
        const MailItem(id: '1', foodId: 'f1', restaurantId: 'r1',
            title: 'Pizza', price: 5000, quantity: 2, imagePath: ''),
        const MailItem(id: '2', foodId: 'f2', restaurantId: 'r1',
            title: 'Drink', price: 1000, quantity: 3, imagePath: ''),
      ];
      final state = MailState(items: items);
      // 5000*2 + 1000*3 = 13000
      expect(state.totalAmount, 13000);
    });

    test('copyWith creates new state with updated fields', () {
      final original = MailState(deliveryFee: 1000, currency: 'SYR');
      final copied = original.copyWith(deliveryFee: 2000, currency: 'SYP');

      expect(copied.deliveryFee, 2000);
      expect(copied.currency, 'SYP');
      expect(original.deliveryFee, 1000);
    });

    test('Equatable equality works', () {
      final a = MailState(items: const [], status: CartStatus.initial);
      final b = MailState(items: const [], status: CartStatus.initial);
      expect(a, b);
    });

    test('Equatable inequality works', () {
      final a = MailState(status: CartStatus.initial);
      final b = MailState(status: CartStatus.loading);
      expect(a == b, false);
    });
  });
}
