import 'package:flutter_test/flutter_test.dart';
import 'package:nomnow_app/features/restaurant/data/models/meal.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Meal', () {
    test('fromJson creates model correctly', () {
      final json = createTestMealJson();
      final meal = Meal.fromJson(json);

      expect(meal.id, 'meal_1');
      expect(meal.name, 'Test Meal');
      expect(meal.description, 'Yummy');
      expect(meal.image, 'https://example.com/meal.jpg');
      expect(meal.rating, 4.0);
      expect(meal.price, 5000);
      expect(meal.time, 20);
      expect(meal.restaurantId, 'rest_1');
      expect(meal.ingredients, ['Tomato', 'Cheese']);
      expect(meal.sizes.length, 1);
      expect(meal.extras.length, 1);
    });

    test('fromJson uses defaults for missing fields', () {
      final meal = Meal.fromJson({});
      expect(meal.id, '');
      expect(meal.name, 'No Name');
      expect(meal.description, '');
      expect(meal.image, 'https://via.placeholder.com/150');
      expect(meal.rating, 0.0);
      expect(meal.price, 0.0);
      expect(meal.time, 0.0);
      expect(meal.restaurantId, '');
      expect(meal.ingredients, []);
      expect(meal.sizes, []);
      expect(meal.extras, []);
    });

    test('fromJson handles restaurantId as populated object', () {
      final json = createTestMealJson()
        ..['restaurantId'] = {
          '_id': 'rest_1',
          'name': 'Populated Restaurant',
        };
      final meal = Meal.fromJson(json);
      expect(meal.restaurantId, 'rest_1');
      expect(meal.restaurantName, 'Populated Restaurant');
    });

    test('fromJson extracts restaurantName from direct field', () {
      final json = createTestMealJson()
        ..['restaurantName'] = 'Direct Name';
      final meal = Meal.fromJson(json);
      expect(meal.restaurantName, 'Direct Name');
    });

    test('fromJson handles non-list ingredients/sizes/extras', () {
      final json = createTestMealJson()
        ..['ingredients'] = 'not a list'
        ..['sizes'] = null
        ..['extras'] = 123;
      final meal = Meal.fromJson(json);
      expect(meal.ingredients, []);
      expect(meal.sizes, []);
      expect(meal.extras, []);
    });
  });

  group('Meal.activeDiscountPercent', () {
    test('returns the percent of an active discount promotion', () {
      final json = createTestMealJson()
        ..['promotions'] = [
          {'type': 'discount', 'discountValue': 20},
        ];
      final meal = Meal.fromJson(json);

      expect(meal.promotions.length, 1);
      expect(meal.activeDiscountPercent, 20);
    });

    // انحدار: الحقل الغائب هو سبب تعطّل فلتر العروض في الرئيسية سابقاً —
    // getAllFood لم يكن يرسل promotions فكان الفلتر يُرجع صفر نتائج دائماً.
    test('is null when the server omits the promotions field', () {
      final meal = Meal.fromJson(createTestMealJson());

      expect(meal.promotions, isEmpty);
      expect(meal.activeDiscountPercent, isNull);
    });

    test('ignores free_delivery promotions', () {
      final json = createTestMealJson()
        ..['promotions'] = [
          {'type': 'free_delivery', 'discountValue': null},
        ];
      final meal = Meal.fromJson(json);

      expect(meal.promotions.length, 1);
      expect(meal.activeDiscountPercent, isNull);
    });

    test('picks the discount when mixed with free_delivery', () {
      final json = createTestMealJson()
        ..['promotions'] = [
          {'type': 'free_delivery', 'discountValue': null},
          {'type': 'discount', 'discountValue': 35},
        ];
      final meal = Meal.fromJson(json);

      expect(meal.activeDiscountPercent, 35);
    });

    test('is null when a discount promotion carries no value', () {
      final json = createTestMealJson()
        ..['promotions'] = [
          {'type': 'discount', 'discountValue': null},
        ];
      final meal = Meal.fromJson(json);

      expect(meal.activeDiscountPercent, isNull);
    });

    test('fromJson handles a non-list promotions field', () {
      final json = createTestMealJson()..['promotions'] = 'not a list';
      final meal = Meal.fromJson(json);

      expect(meal.promotions, isEmpty);
      expect(meal.activeDiscountPercent, isNull);
    });
  });

  group('Meal.displayPrice', () {
    // قاعدة الباك: وجود sizes يُلغي price. لكن models/food.js يُبقي price
    // حقلاً required فلا يُصفَّر، فكان المنطق القديم (price > 0 ? price : ...)
    // يعرض price دائماً ويتجاهل الأحجام.
    test('يعيد أرخص حجم حين توجد أحجام — لا price', () {
      final json = createTestMealJson()
        ..['price'] = 5000
        ..['sizes'] = [
          {'name': 'large', 'price': 32000},
          {'name': 'small', 'price': 18000},
          {'name': 'medium', 'price': 25000},
        ];

      // الأرخص لا الأول: ترتيب المصفوفة يتبع إدخال الأدمن
      expect(Meal.fromJson(json).displayPrice, 18000);
    });

    test('يعيد price حين لا توجد أحجام', () {
      final json = createTestMealJson()
        ..['price'] = 5000
        ..['sizes'] = [];

      expect(Meal.fromJson(json).displayPrice, 5000);
    });

    test('يعيد price حين تكون الأحجام بلا أسعار صالحة', () {
      final json = createTestMealJson()
        ..['price'] = 5000
        ..['sizes'] = [
          {'name': 'large', 'price': null},
        ];

      expect(Meal.fromJson(json).displayPrice, 5000);
    });
  });

  group('Meal — حقول الشاشة الرئيسية', () {
    test('يستخرج العملة من restaurantId المُوسَّع', () {
      final json = createTestMealJson()
        ..['restaurantId'] = {
          '_id': 'rest_1',
          'name': 'Deutsches Restaurant',
          'currency': 'EUR',
        };

      expect(Meal.fromJson(json).currency, 'EUR');
    });

    test('العملة null حين يصل restaurantId كمعرّف مجرّد', () {
      expect(Meal.fromJson(createTestMealJson()).currency, isNull);
    });

    test('يستخرج القسم العام المُوسَّع', () {
      final json = createTestMealJson()
        ..['mainCategoryId'] = {
          '_id': 'cat_1',
          'name': 'وجبات سريعة',
          'image': {'url': 'https://example.com/ff.png'},
        };
      final meal = Meal.fromJson(json);

      expect(meal.mainCategoryId, 'cat_1');
      expect(meal.mainCategoryName, 'وجبات سريعة');
    });

    test('يقبل القسم العام كمعرّف مجرّد', () {
      final json = createTestMealJson()..['mainCategoryId'] = 'cat_1';
      final meal = Meal.fromJson(json);

      expect(meal.mainCategoryId, 'cat_1');
      expect(meal.mainCategoryName, isNull);
    });

    test('القسم العام null — اختياري في الباك', () {
      final json = createTestMealJson()..['mainCategoryId'] = null;

      expect(Meal.fromJson(json).mainCategoryId, isNull);
    });

    // الباك لا يفلتر الأصناف غير المتوفرة في GET /api/user/food
    test('status افتراضيه available وisAvailable يتبعه', () {
      expect(Meal.fromJson(createTestMealJson()).isAvailable, isTrue);

      final json = createTestMealJson()..['status'] = 'unavailable';
      final meal = Meal.fromJson(json);
      expect(meal.status, 'unavailable');
      expect(meal.isAvailable, isFalse);
    });
  });
}
