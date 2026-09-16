import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class FavoriteHeader extends StatelessWidget {
  final bool hasFavorites;
  final int restaurantsCount;
  final int foodsCount;
  final bool showRestaurants;
  final VoidCallback onTapRestaurants;
  final VoidCallback onTapFoods;

  const FavoriteHeader({
    super.key,
    required this.hasFavorites,
    required this.restaurantsCount,
    required this.foodsCount,
    required this.showRestaurants,
    required this.onTapRestaurants,
    required this.onTapFoods,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalFavorites = (restaurantsCount + foodsCount).toString();
    double scale = MediaQuery
        .of(context)
        .size
        .width / 375;
    scale = scale.clamp(0.85, 1.2);

    return Container(
      padding: EdgeInsets.fromLTRB(
          16 * scale, 10 * scale, 16 * scale, 10 * scale),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: scale),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12 * scale),
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                    Icons.favorite, color: Colors.white, size: 20 * scale),
              ),
              SizedBox(width: 16 * scale),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'header_title'.tr(),
                    style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 20 * scale),
                  ),
                  SizedBox(height: 4 * scale),
                  Text(
                    hasFavorites
                        ? 'header_has_fav'.tr(args: [totalFavorites])
                        : 'header_no_fav'.tr(),
                    style: TextStyle(
                        fontSize: 14 * scale, color: theme.hintColor),
                  ),
                ],
              ),
            ],
          ),
          if (hasFavorites) ...[
            SizedBox(height: 20 * scale),
            Container(
              height: 50 * scale,
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _FilterButton(
                    text: '${'header_restaurants'.tr()} ($restaurantsCount)',
                    isSelected: showRestaurants,
                    onTap: onTapRestaurants,
                    scale: scale,
                  ),
                  const SizedBox(width: 12),
                  _FilterButton(
                    text: '${'header_meals'.tr()} ($foodsCount)',
                    isSelected: !showRestaurants,
                    onTap: onTapFoods,
                    scale: scale,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;
  final double scale;

  const _FilterButton({
    required this.text,
    required this.isSelected,
    required this.onTap,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? theme.primaryColor : theme
                .scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : theme.textTheme.bodyLarge
                    ?.color,
                fontSize: 14 * scale,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}