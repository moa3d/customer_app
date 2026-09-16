import 'package:flutter_test/flutter_test.dart';
import 'package:nomnow_app/core/routing/routes.dart';

void main() {
  group('Routes', () {
    test('all route constants are non-empty', () {
      expect(Routes.splash, isNotEmpty);
      expect(Routes.authSelection, isNotEmpty);
      expect(Routes.banned, isNotEmpty);
      expect(Routes.welcome, isNotEmpty);
      expect(Routes.selectDisplay, isNotEmpty);
      expect(Routes.selectLanguage, isNotEmpty);
      expect(Routes.home, isNotEmpty);
      expect(Routes.cart, isNotEmpty);
      expect(Routes.orders, isNotEmpty);
      expect(Routes.favorites, isNotEmpty);
      expect(Routes.account, isNotEmpty);
      expect(Routes.editProfile, isNotEmpty);
      expect(Routes.addresses, isNotEmpty);
      expect(Routes.notifications, isNotEmpty);
      expect(Routes.language, isNotEmpty);
      expect(Routes.support, isNotEmpty);
      expect(Routes.restaurantDetails, isNotEmpty);
      expect(Routes.mealDetails, isNotEmpty);
      expect(Routes.offers, isNotEmpty);
    });

    test('nested routes are relative (no leading slash)', () {
      expect(Routes.editProfile.startsWith('/'), false);
      expect(Routes.addresses.startsWith('/'), false);
      expect(Routes.notifications.startsWith('/'), false);
      expect(Routes.language.startsWith('/'), false);
      expect(Routes.support.startsWith('/'), false);
    });

    test('top-level routes have leading slash', () {
      expect(Routes.splash.startsWith('/'), true);
      expect(Routes.authSelection.startsWith('/'), true);
      expect(Routes.banned.startsWith('/'), true);
      expect(Routes.welcome.startsWith('/'), true);
      expect(Routes.home.startsWith('/'), true);
      expect(Routes.cart.startsWith('/'), true);
      expect(Routes.account.startsWith('/'), true);
    });

    test('no duplicate route values', () {
      final routeValues = {
        Routes.splash,
        Routes.authSelection,
        Routes.banned,
        Routes.welcome,
        Routes.selectDisplay,
        Routes.selectLanguage,
        Routes.home,
        Routes.cart,
        Routes.orders,
        Routes.favorites,
        Routes.account,
        Routes.restaurantDetails,
        Routes.mealDetails,
        Routes.offers,
      };
      expect(routeValues.length, 14);
    });
  });
}
