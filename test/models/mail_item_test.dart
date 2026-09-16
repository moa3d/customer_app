import 'package:flutter_test/flutter_test.dart';
import 'package:nomnow_app/features/cart/domain/models/mail_item.dart';

void main() {
  group('MailItem', () {
    const item = MailItem(
      id: 'item_1',
      foodId: 'food_1',
      restaurantId: 'rest_1',
      title: 'Pizza',
      price: 5000,
      size: 'Large',
      sizePrice: 1000,
      quantity: 2,
      imagePath: 'https://example.com/pizza.jpg',
      extras: [{'name': 'Cheese', 'price': 500}],
      notes: 'Extra spicy',
    );

    test('creates instance with correct values', () {
      expect(item.id, 'item_1');
      expect(item.foodId, 'food_1');
      expect(item.restaurantId, 'rest_1');
      expect(item.title, 'Pizza');
      expect(item.price, 5000);
      expect(item.size, 'Large');
      expect(item.sizePrice, 1000);
      expect(item.quantity, 2);
      expect(item.imagePath, 'https://example.com/pizza.jpg');
      expect(item.extras.length, 1);
      expect(item.notes, 'Extra spicy');
    });

    test('toJson produces correct map', () {
      final json = item.toJson();
      expect(json['foodId'], 'food_1');
      expect(json['quantity'], 2);
      expect(json['size'], {'name': 'Large', 'price': 1000});
      expect(json['extras'].length, 1);
      expect(json['notes'], 'Extra spicy');
    });

    test('toJson sets size to null for standard size', () {
      const standardItem = MailItem(
        id: 'i1', foodId: 'f1', restaurantId: 'r1',
        title: 'Test', price: 1000, quantity: 1,
        imagePath: '',
        size: 'standard',
      );
      expect(standardItem.toJson()['size'], null);
    });

    test('toJson sets size to null for empty size', () {
      const emptyItem = MailItem(
        id: 'i1', foodId: 'f1', restaurantId: 'r1',
        title: 'Test', price: 1000, quantity: 1,
        imagePath: '',
        size: '',
      );
      expect(emptyItem.toJson()['size'], null);
    });

    test('toJson sets size to null for null size', () {
      const noSizeItem = MailItem(
        id: 'i1', foodId: 'f1', restaurantId: 'r1',
        title: 'Test', price: 1000, quantity: 1,
        imagePath: '',
      );
      expect(noSizeItem.toJson()['size'], null);
    });

    test('Equatable props are correct', () {
      // الترتيب يطابق get props في mail_item.dart، وفيه originalPrice
      // (أُضيف مع حقول العروض) بين price و size.
      expect(item.props, [
        'item_1', 'food_1', 'rest_1', 'Pizza', 5000.0,
        null, // originalPrice
        'Large', 1000.0, 2, 'https://example.com/pizza.jpg',
        [{'name': 'Cheese', 'price': 500}], 'Extra spicy',
      ]);
    });

    test('Equatable equality works', () {
      const same = MailItem(
        id: 'item_1', foodId: 'food_1', restaurantId: 'rest_1',
        title: 'Pizza', price: 5000, size: 'Large', sizePrice: 1000,
        quantity: 2, imagePath: 'https://example.com/pizza.jpg',
        extras: [{'name': 'Cheese', 'price': 500}], notes: 'Extra spicy',
      );
      expect(item, same);

      const different = MailItem(
        id: 'item_2', foodId: 'food_1', restaurantId: 'rest_1',
        title: 'Pizza', price: 5000, quantity: 1, imagePath: '',
      );
      expect(item == different, false);
    });
  });
}
