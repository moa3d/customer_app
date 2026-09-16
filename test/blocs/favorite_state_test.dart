import 'package:flutter_test/flutter_test.dart';
import 'package:nomnow_app/features/favorite/cubit/favorite_state.dart';
import 'package:nomnow_app/features/restaurant/data/models/restaurant.dart';
import 'package:nomnow_app/features/restaurant/data/models/meal.dart';

void main() {
  group('FavoriteState', () {
    test('initial state has correct defaults', () {
      const state = FavoriteState();
      expect(state.favoriteMeals, []);
      expect(state.favoriteRestaurants, []);
      expect(state.isLoading, false);
    });

    test('copyWith updates meals', () {
      const state = FavoriteState();
      final meals = [Meal(id: 'm1', name: 'Pizza', description: 'Yum',
          image: '', rating: 4, price: 5000, restaurantId: 'r1', time: 20)];
      final copied = state.copyWith(favoriteMeals: meals);
      expect(copied.favoriteMeals.length, 1);
      expect(copied.favoriteRestaurants, []);
      expect(copied.isLoading, false);
    });

    test('copyWith updates restaurants', () {
      const state = FavoriteState();
      final restaurants = [Restaurant(id: 'r1', name: 'Test', description: 'D',
          imageUrl: '', rating: 4)];
      final copied = state.copyWith(favoriteRestaurants: restaurants);
      expect(copied.favoriteRestaurants.length, 1);
      expect(copied.favoriteMeals, []);
    });

    test('copyWith updates isLoading', () {
      const state = FavoriteState();
      final copied = state.copyWith(isLoading: true);
      expect(copied.isLoading, true);
    });

    test('copyWith preserves original when no args', () {
      const state = FavoriteState(isLoading: true);
      final copied = state.copyWith();
      expect(copied.isLoading, true);
      expect(copied.favoriteMeals, []);
    });
  });
}
