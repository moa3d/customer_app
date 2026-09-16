import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomnow_app/features/offers/domain/models/offer_model.dart';

void main() {
  group('Offer', () {
    final now = DateTime.now();
    final offer = Offer(
      id: '1',
      type: 'discount',
      discountValue: 50,
      startDate: now,
      endDate: now.add(const Duration(days: 7)),
      country: 'ALL',
      isActive: true,
      foodId: 'f1',
      foodName: 'Pizza Margherita',
      foodImage: 'https://example.com/pizza.jpg',
      foodPrice: 12.99,
      restaurantId: 'r1',
      restaurantName: 'Pizza Palace',
    );

    test('creates instance with correct values', () {
      expect(offer.id, '1');
      expect(offer.type, 'discount');
      expect(offer.discountValue, 50);
      expect(offer.startDate, now);
      expect(offer.endDate, now.add(const Duration(days: 7)));
      expect(offer.country, 'ALL');
      expect(offer.isActive, true);
      expect(offer.foodId, 'f1');
      expect(offer.foodName, 'Pizza Margherita');
      expect(offer.foodImage, 'https://example.com/pizza.jpg');
      expect(offer.foodPrice, 12.99);
      expect(offer.restaurantId, 'r1');
      expect(offer.restaurantName, 'Pizza Palace');
    });

    test('discountTag returns percentage for discount type', () {
      expect(offer.discountTag, '50%');
    });

    test('discountTag returns free delivery text', () {
      final freeOffer = Offer(
        id: '2',
        type: 'free_delivery',
        startDate: now,
        endDate: now.add(const Duration(days: 7)),
        country: 'ALL',
        isActive: true,
        foodId: 'f2',
        foodName: 'Burger',
        foodImage: 'https://example.com/burger.jpg',
        foodPrice: 8.99,
        restaurantId: 'r2',
        restaurantName: 'Burger Joint',
      );
      // يُقارن بـ `.tr()` لا بنصّ عربي مثبّت: المقصود أن النوع
      // `free_delivery` يُنتج لافتة التوصيل المجاني لا نسبة خصم — والمقارنة
      // ناجحة سواء كان easy_localization مهيّأً أم لا، ولا تكسرها أي تعديل
      // على ملفات الترجمة.
      expect(freeOffer.discountTag, 'free_delivery'.tr());
    });

    test('copyWith updates isActive', () {
      final deactivated = offer.copyWith(isActive: false);
      expect(deactivated.isActive, false);
      expect(deactivated.id, '1');
      expect(deactivated.restaurantName, 'Pizza Palace');
    });

    test('copyWith preserves values when not provided', () {
      final copy = offer.copyWith();
      expect(copy.isActive, true);
      expect(copy.id, '1');
      expect(copy.foodName, 'Pizza Margherita');
    });

    test('optional fields have correct defaults', () {
      expect(offer.foodRating, isNull);
      expect(offer.foodSizes, isEmpty);
      expect(offer.restaurantImage, isNull);
      expect(offer.restaurantAddress, isNull);
    });
  });
}
