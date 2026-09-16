import 'package:flutter_test/flutter_test.dart';
import 'package:nomnow_app/features/coupons/domain/models/coupon.dart';

void main() {
  group('Coupon.fromJson', () {
    test('parses all fields correctly', () {
      final now = DateTime.now();
      final coupon = Coupon.fromJson({
        'code': 'SAVE10',
        'type': 'percentage',
        'value': 10,
        'maxDiscountAmount': 500,
        'minOrderValue': 1000,
        'hasExpiry': true,
        'endDate': now.add(const Duration(days: 5)).toIso8601String(),
        'usedByMe': 2,
        'maxUsesPerUser': 5,
        'isUsable': true,
      });

      expect(coupon.code, 'SAVE10');
      expect(coupon.type, 'percentage');
      expect(coupon.value, 10);
      expect(coupon.maxDiscountAmount, 500);
      expect(coupon.minOrderValue, 1000);
      expect(coupon.hasExpiry, isTrue);
      expect(coupon.endDate, isNotNull);
      expect(coupon.usedByMe, 2);
      expect(coupon.maxUsesPerUser, 5);
      expect(coupon.isUsable, isTrue);
    });

    test('applies safe defaults when fields missing', () {
      final coupon = Coupon.fromJson({'code': 'X'});
      expect(coupon.code, 'X');
      expect(coupon.type, 'fixed');
      expect(coupon.value, isNull);
      expect(coupon.hasExpiry, isFalse);
      expect(coupon.endDate, isNull);
      expect(coupon.usedByMe, 0);
      expect(coupon.maxUsesPerUser, isNull);
      expect(coupon.isUsable, isTrue);
    });

    test('defaults isUsable/hasExpiry to false only when explicitly false', () {
      final coupon = Coupon.fromJson({
        'code': 'Y',
        'hasExpiry': false,
        'isUsable': false,
      });
      expect(coupon.hasExpiry, isFalse);
      expect(coupon.isUsable, isFalse);
    });
  });

  group('Coupon.isExpired', () {
    test('false when no expiry', () {
      final coupon = const Coupon(code: 'X', type: 'fixed');
      expect(coupon.isExpired, isFalse);
    });

    test('true when endDate is in the past', () {
      final coupon = Coupon(
        code: 'PAST',
        type: 'fixed',
        hasExpiry: true,
        endDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(coupon.isExpired, isTrue);
    });

    test('false when endDate is in the future', () {
      final coupon = Coupon(
        code: 'FUTURE',
        type: 'fixed',
        hasExpiry: true,
        endDate: DateTime.now().add(const Duration(days: 1)),
      );
      expect(coupon.isExpired, isFalse);
    });
  });

  group('Coupon.remainingUses', () {
    test('returns null when maxUsesPerUser is null (unlimited)', () {
      const coupon = Coupon(code: 'X', type: 'fixed');
      expect(coupon.remainingUses, isNull);
    });

    test('computes remaining uses correctly', () {
      const coupon = Coupon(
        code: 'X',
        type: 'fixed',
        usedByMe: 2,
        maxUsesPerUser: 5,
      );
      expect(coupon.remainingUses, 3);
    });
  });

  group('Coupon.formatValue', () {
    test('percentage without max uses offer_percent key', () {
      const coupon = Coupon(code: 'P', type: 'percentage', value: 10);
      expect(coupon.formatValue(), contains('offer_percent'));
    });

    test('percentage with max includes offer_max key', () {
      const coupon = Coupon(
        code: 'P',
        type: 'percentage',
        value: 10,
        maxDiscountAmount: 500,
      );
      final value = coupon.formatValue(currency: 'ل.س');
      expect(value, contains('offer_percent'));
      expect(value, contains('offer_max'));
    });

    test('fixed uses offer_fixed key with formatted money', () {
      const coupon = Coupon(code: 'F', type: 'fixed', value: 2000);
      expect(
        coupon.formatValue(currency: 'ل.س'),
        contains('offer_fixed'),
      );
    });

    test('free_delivery uses free_delivery_value key', () {
      const coupon = Coupon(code: 'FD', type: 'free_delivery');
      expect(coupon.formatValue(), contains('free_delivery_value'));
    });
  });

  group('Coupon.expiryLabel', () {
    test('no_expiry when no expiry configured', () {
      const coupon = Coupon(code: 'X', type: 'fixed');
      expect(coupon.expiryLabel(), contains('no_expiry'));
    });

    test('expired_key when past expiry', () {
      final coupon = Coupon(
        code: 'X',
        type: 'fixed',
        hasExpiry: true,
        endDate: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      expect(coupon.expiryLabel(), contains('expired'));
    });

    test('expires_in_days for future expiry', () {
      final coupon = Coupon(
        code: 'X',
        type: 'fixed',
        hasExpiry: true,
        endDate: DateTime.now().add(const Duration(days: 3)),
      );
      expect(coupon.expiryLabel(), contains('expires_in_days'));
    });
  });
}
