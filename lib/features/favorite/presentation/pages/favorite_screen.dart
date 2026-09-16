import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/shimmer_loading.dart';
import '../../../restaurant/data/models/meal.dart';
import '../../../restaurant/data/models/restaurant.dart';
import '../../cubit/favorite_cubit.dart';
import '../../cubit/favorite_state.dart';
import '../widgets/empty_favorites_view.dart';
import '../widgets/favorite_header.dart';
import '../widgets/favorite_list_item.dart';

class FavoritesScreen extends StatefulWidget {
  final String token;
  final Function(int, {dynamic data})? movePage; // ✅ إضافة حقل التنقل

  const FavoritesScreen(
      {super.key, required this.token, this.movePage}); // ✅ تحديث الـ constructor

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _showRestaurants = true;

  @override
  void initState() {
    super.initState();
    context.read<FavoriteCubit>().fetchFavorites();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<FavoriteCubit, FavoriteState>(
      builder: (context, state) {
        final bool hasAnyData =
            state.favoriteRestaurants.isNotEmpty ||
                state.favoriteMeals.isNotEmpty;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                FavoriteHeader(
                  hasFavorites: hasAnyData,
                  restaurantsCount: state.favoriteRestaurants.length,
                  foodsCount: state.favoriteMeals.length,
                  showRestaurants: _showRestaurants,
                  onTapRestaurants: () =>
                      setState(() => _showRestaurants = true),
                  onTapFoods: () => setState(() => _showRestaurants = false),
                ),
                if (hasAnyData && !state.isLoading) _buildSubHeader(
                    state, theme),
                Expanded(
                  child: state.isLoading
                      ? const ShimmerFavoriteList()
                      : _buildBody(state),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubHeader(FavoriteState state, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            _showRestaurants
                ? "${state.favoriteRestaurants.length} ${'favorites.restaurants_tab'.tr()}"
                : "${state.favoriteMeals.length} ${'favorites.meals_tab'.tr()}",
            style: theme.textTheme.bodySmall,
          ),
          const Spacer(),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    _showRestaurants
                        ? "favorites.restaurants_tab".tr()
                        : "favorites.meals_tab".tr(),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.favorite,
                    color: theme.primaryColor, size: 18)
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(FavoriteState state) {
    if (_showRestaurants) {
      if (state.favoriteRestaurants.isEmpty) return const EmptyFavoritesView();
      return _buildList(state.favoriteRestaurants, isMeal: false);
    } else {
      if (state.favoriteMeals.isEmpty) return const EmptyFavoritesView();
      return _buildList(state.favoriteMeals, isMeal: true);
    }
  }

  Widget _buildList(List<dynamic> items, {required bool isMeal}) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return FavoriteListItem(
          item: item,
          isMeal: isMeal,
          imageUrl: isMeal ? (item as Meal).image : (item as Restaurant)
              .imageUrl,
          title: item.name,
          subtitle: item.description,
          time: isMeal ? (item as Meal).time.toInt().toString() : "--",
          distance: isMeal ? null : "${(item as Restaurant).distance?.toStringAsFixed(1) ?? '--'} km",
          rating: item.rating.toString(),
          onToggleFavorite: () {
            if (isMeal) {
              context.read<FavoriteCubit>().toggleFavorite(item as Meal);
            } else {
              context.read<FavoriteCubit>().toggleRestaurantFavorite(
                  item as Restaurant);
            }
          },
          onTap: () { // ✅ إضافة منطق النقر للتنقل
            if (isMeal && widget.movePage != null) {
              widget.movePage!(8, data: item as Meal);
            } else if (!isMeal && widget.movePage != null) {
              // اختياري: الانتقال لصفحة المطعم (رقم 7) عند النقر على مطعم مفضل
              widget.movePage!(7, data: item as Restaurant);
            }
          },
        );
      },
    );
  }
}