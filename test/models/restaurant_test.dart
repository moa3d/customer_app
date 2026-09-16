import 'package:flutter_test/flutter_test.dart';
import 'package:nomnow_app/features/restaurant/data/models/restaurant.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Restaurant', () {
    test('fromJson creates model correctly', () {
      final json = createTestRestaurantJson();
      final restaurant = Restaurant.fromJson(json);

      expect(restaurant.id, 'rest_1');
      expect(restaurant.name, 'Test Restaurant');
      expect(restaurant.description, 'Test description');
      expect(restaurant.imageUrl, 'https://example.com/image.jpg');
      expect(restaurant.rating, 4.5);
    });

    test('fromJson uses defaults for missing fields', () {
      final restaurant = Restaurant.fromJson({});
      expect(restaurant.id, '');
      expect(restaurant.name, 'No Name');
      expect(restaurant.description, 'Variety');
      expect(restaurant.imageUrl, 'https://via.placeholder.com/150');
      expect(restaurant.rating, 0.0);
    });

    test('fromJson falls back to img field when image is missing', () {
      final json = createTestRestaurantJson()
        ..remove('image')
        ..['img'] = {'url': 'https://example.com/fallback.jpg'};
      final restaurant = Restaurant.fromJson(json);
      expect(restaurant.imageUrl, 'https://example.com/fallback.jpg');
    });

    test('fromJson falls back to placeholder when image is a string URL', () {
      final json = createTestRestaurantJson()
        ..['image'] = 'https://example.com/string.jpg';
      final restaurant = Restaurant.fromJson(json);
      expect(restaurant.imageUrl, 'https://via.placeholder.com/150');
    });

    test('fromJson parses distance when provided', () {
      final json = createTestRestaurantJson()..['distance'] = 2.5;
      final restaurant = Restaurant.fromJson(json);
      expect(restaurant.distance, 2.5);
    });

    test('distance is null when not provided', () {
      final restaurant = Restaurant.fromJson(createTestRestaurantJson());
      expect(restaurant.distance, null);
    });

    test('rating is parsed as double even from int', () {
      final json = createTestRestaurantJson()..['rating'] = 4;
      final restaurant = Restaurant.fromJson(json);
      expect(restaurant.rating, 4.0);
    });
  });

  group('Restaurant — حقول الترتيب والعملة', () {
    test('يستخرج العملة والحالة', () {
      final json = createTestRestaurantJson()
        ..['currency'] = 'EUR'
        ..['status'] = 'open';
      final restaurant = Restaurant.fromJson(json);

      expect(restaurant.currency, 'EUR');
      expect(restaurant.status, 'open');
    });

    // المسافة تصل فقط عند locationUsed: true؛ في نتائج البحث الحقل غائب
    // تماماً لا null، ولا يجوز عرض «0 كم» بدلاً منها.
    test('distance تبقى null حين لا يرسلها الباك', () {
      final restaurant = Restaurant.fromJson(createTestRestaurantJson());

      expect(restaurant.distance, isNull);
      expect(restaurant.currency, isNull);
      expect(restaurant.status, isNull);
    });

    test('تقرأ distance حين يرسلها الباك', () {
      final json = createTestRestaurantJson()..['distance'] = 1.4;

      expect(Restaurant.fromJson(json).distance, 1.4);
    });
  });
}
