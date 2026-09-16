import '../../restaurant/data/models/meal.dart';
import '../../restaurant/data/models/restaurant.dart';


class FavoriteState {
  final List<Meal> favoriteMeals;
  final List<Restaurant> favoriteRestaurants;
  final bool isLoading;

  const FavoriteState({
    this.favoriteMeals = const [],
    this.favoriteRestaurants = const [],
    this.isLoading = false, // القيمة الافتراضية
  });

  FavoriteState copyWith({
    List<Meal>? favoriteMeals,
    List<Restaurant>? favoriteRestaurants,
    bool? isLoading,
  }) {
    return FavoriteState(
      favoriteMeals: favoriteMeals ?? this.favoriteMeals,
      favoriteRestaurants: favoriteRestaurants ?? this.favoriteRestaurants,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}