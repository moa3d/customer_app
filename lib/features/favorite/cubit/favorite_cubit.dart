import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nomnow_app/features/favorite/cubit/favorite_state.dart';

import '../../restaurant/data/models/meal.dart';
import '../../restaurant/data/models/restaurant.dart';
import '../data/services/favorite_service.dart';




class FavoriteCubit extends Cubit<FavoriteState> {
  final FavoriteService _favoriteService;

  FavoriteCubit({FavoriteService? favoriteService})
      : _favoriteService = favoriteService ?? FavoriteService(),
        super(const FavoriteState());

  // 2. دالة لجلب المفضلات من السيرفر (استدعيها في initState لصفحة المفضلة)
  // state/cubits/favorite_cubit.dart

  Future<void> fetchFavorites() async {
    if (isClosed) return;
    emit(state.copyWith(isLoading: true));    try {
      final response = await _favoriteService.getMyFavorites();
      if (response.statusCode == 200) {
        // 1. معالجة الوجبات المفضلة بأمان
        final List<dynamic> foodsJson = response.data['favoritesfood'] ?? [];
        List<Meal> fetchedMeals = [];

        for (var item in foodsJson) {
          if (item is Map<String, dynamic>) {
            // إذا كان السيرفر يرسل كائن الوجبة كاملاً
            fetchedMeals.add(Meal.fromJson(item));
          } else if (item is String) {
            // إذا كان السيرفر يرسل ID فقط، نصنع كائن وهمي بالـ ID
            // أو نتجاهله لأننا سنقوم بجلب البيانات كاملة من قائمة الوجبات العامة
            fetchedMeals.add(Meal(
                id: item,
                name: '', description: '', image: '',
                rating: 0, price: 0, restaurantId: '', time: 0
            ));
          }
        }

        // 2. معالجة المطاعم المفضلة بأمان
        final List<dynamic> resJson = response.data['favoritesres'] ?? [];
        List<Restaurant> fetchedRestaurants = [];

        for (var item in resJson) {
          if (item is Map<String, dynamic>) {
            fetchedRestaurants.add(Restaurant.fromJson(item));
          } else if (item is String) {
            fetchedRestaurants.add(Restaurant(
                id: item, name: '', description: '', imageUrl: '', rating: 0
            ));
          }
        }

        emit(state.copyWith(
          favoriteMeals: fetchedMeals,
          favoriteRestaurants: fetchedRestaurants,
          isLoading: false,
        ));
      }
    } catch (e) {
      debugPrint("FavoriteCubit Error: $e");
      if (!isClosed) emit(state.copyWith(isLoading: false));
    }
  }

  // دالة تبديل المطعم المفضل (تستخدم PATCH حسب الـ Route الخاص بك)
  Future<void> toggleRestaurantFavorite(Restaurant restaurant) async {
    try {
      await _favoriteService.toggleRestaurantFavorite(restaurant.id);
      fetchFavorites(); // إعادة الجلب لضمان المزامنة
    } catch (e) { debugPrint(e.toString()); }
  }

  // 3. تعديل دالة الـ toggle لترسل للسيرفر
  Future<void> toggleFavorite(Meal meal) async {
    // تحديث محلي سريع (Optimistic Update) لتشعر الواجهة بالسرعة
    final isExisting = state.favoriteMeals.any((item) => item.id == meal.id);
    List<Meal> updatedList;

    if (isExisting) {
      updatedList = state.favoriteMeals
          .where((item) => item.id != meal.id)
          .toList();
    } else {
      updatedList = List.from(state.favoriteMeals)..add(meal);
    }

    emit(state.copyWith(favoriteMeals: updatedList));

    // إرسال التغيير للسيرفر في الخلفية
    try {
      await _favoriteService.toggleFoodFavorite(meal.id);
    } catch (e) {
      // في حال فشل السيرفر، نعيد القائمة كما كانت لضمان دقة البيانات
      debugPrint("Failed to sync favorite with server: $e");
      fetchFavorites(); // إعادة الجلب من السيرفر للتصحيح
    }
  }

  bool isFavorite(String mealId) {
    return state.favoriteMeals.any((item) => item.id == mealId);
  }
  bool isRestaurantFavorite(String restaurantId) {
    return state.favoriteRestaurants.any((item) => item.id == restaurantId);
  }
}
