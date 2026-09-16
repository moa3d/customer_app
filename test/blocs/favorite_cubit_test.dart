import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:nomnow_app/features/favorite/cubit/favorite_cubit.dart';
import 'package:nomnow_app/features/favorite/cubit/favorite_state.dart';
import 'package:nomnow_app/features/favorite/data/services/favorite_service.dart';
import 'package:nomnow_app/features/restaurant/data/models/meal.dart';
import 'package:nomnow_app/features/restaurant/data/models/restaurant.dart';

class MockFavoriteService extends Mock implements FavoriteService {}

void main() {
  late MockFavoriteService mockService;

  setUp(() {
    mockService = MockFavoriteService();
  });

  group('FavoriteCubit', () {
    final meal1 = Meal(id: 'm1', name: 'Pizza', description: 'Yummy', image: '',
        rating: 4, price: 5000, restaurantId: 'r1', time: 20);
    final meal2 = Meal(id: 'm2', name: 'Burger', description: 'Good', image: '',
        rating: 3, price: 3000, restaurantId: 'r1', time: 15);
    final rest1 = Restaurant(id: 'r1', name: 'Test Res', description: '', imageUrl: '', rating: 4);

    blocTest<FavoriteCubit, FavoriteState>(
      'initial state is empty',
      build: () => FavoriteCubit(favoriteService: mockService),
      expect: () => [],
    );

    blocTest<FavoriteCubit, FavoriteState>(
      'toggleFavorite adds meal optimistically',
      setUp: () {
        when(() => mockService.toggleFoodFavorite(any())).thenAnswer((_) async =>
          Response(requestOptions: RequestOptions(path: ''), data: {}, statusCode: 200));
        when(() => mockService.getMyFavorites()).thenAnswer((_) async =>
          Response(requestOptions: RequestOptions(path: ''), data: {}, statusCode: 200));
      },
      build: () => FavoriteCubit(favoriteService: mockService),
      act: (cubit) => cubit.toggleFavorite(meal1),
      expect: () => [
        isA<FavoriteState>().having((s) => s.favoriteMeals.length, 'length', 1),
      ],
    );

    blocTest<FavoriteCubit, FavoriteState>(
      'toggleFavorite removes meal optimistically',
      setUp: () {
        when(() => mockService.toggleFoodFavorite(any())).thenAnswer((_) async =>
          Response(requestOptions: RequestOptions(path: ''), data: {}, statusCode: 200));
        when(() => mockService.getMyFavorites()).thenAnswer((_) async =>
          Response(requestOptions: RequestOptions(path: ''), data: {}, statusCode: 200));
      },
      build: () => FavoriteCubit(favoriteService: mockService),
      seed: () => FavoriteState(favoriteMeals: [meal1, meal2]),
      act: (cubit) => cubit.toggleFavorite(meal1),
      expect: () => [
        isA<FavoriteState>().having((s) => s.favoriteMeals.length, 'length', 1),
      ],
    );

    test('isFavorite returns correct value', () {
      final cubit = FavoriteCubit(favoriteService: mockService);
      expect(cubit.isFavorite('m1'), false);
      cubit.emit(FavoriteState(favoriteMeals: [meal1]));
      expect(cubit.isFavorite('m1'), true);
      expect(cubit.isFavorite('m2'), false);
    });

    test('isRestaurantFavorite returns correct value', () {
      final cubit = FavoriteCubit(favoriteService: mockService);
      expect(cubit.isRestaurantFavorite('r1'), false);
      cubit.emit(FavoriteState(favoriteRestaurants: [rest1]));
      expect(cubit.isRestaurantFavorite('r1'), true);
    });

    blocTest<FavoriteCubit, FavoriteState>(
      'fetchFavorites emits [loading, loaded] on success',
      setUp: () {
        when(() => mockService.getMyFavorites()).thenAnswer((_) async =>
          Response(requestOptions: RequestOptions(path: ''), data: {
            'favoritesfood': [
              {'_id': 'm1', 'name': 'Pizza', 'description': 'Yummy', 'image': {'url': ''}, 'rating': 4, 'price': 5000, 'time': 20, 'restaurantId': 'r1'},
            ],
            'favoritesres': [
              {'_id': 'r1', 'name': 'Test Res', 'description': '', 'image': {'url': ''}, 'rating': 4},
            ],
          }, statusCode: 200),
        );
      },
      build: () => FavoriteCubit(favoriteService: mockService),
      act: (cubit) => cubit.fetchFavorites(),
      expect: () => [
        isA<FavoriteState>().having((s) => s.isLoading, 'loading', true),
        isA<FavoriteState>()
            .having((s) => s.isLoading, 'loading', false)
            .having((s) => s.favoriteMeals.length, 'meals', 1)
            .having((s) => s.favoriteRestaurants.length, 'rests', 1),
      ],
    );

    blocTest<FavoriteCubit, FavoriteState>(
      'fetchFavorites handles empty response gracefully',
      setUp: () {
        when(() => mockService.getMyFavorites()).thenAnswer((_) async =>
          Response(requestOptions: RequestOptions(path: ''), data: {}, statusCode: 200),
        );
      },
      build: () => FavoriteCubit(favoriteService: mockService),
      act: (cubit) => cubit.fetchFavorites(),
      expect: () => [
        isA<FavoriteState>().having((s) => s.isLoading, 'loading', true),
        isA<FavoriteState>()
            .having((s) => s.isLoading, 'loading', false)
            .having((s) => s.favoriteMeals.length, 'meals', 0)
            .having((s) => s.favoriteRestaurants.length, 'rests', 0),
      ],
    );
  });
}
