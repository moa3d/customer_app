import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/utils/app_sizes.dart';
import '../../data/models/restaurant.dart';
import '../../data/models/category.dart';


//  هون عم نفصل الهيدر مشان نحسن سرعة الـتبيطق ونخفف الضغط على الكود الرئيسي.
class RestaurantHeader extends StatelessWidget {
  final Restaurant restaurant;
  final List<FoodCategory> categories;
  final String? selectedCategoryId; // null = "الكل"
  final VoidCallback onBackTap, onFilterTap;
  final ValueChanged<String?> onCategorySelected;
  final ValueChanged<String> onSearchChanged;

  const RestaurantHeader({
    super.key,
    required this.restaurant,
    required this.categories,
    required this.selectedCategoryId,
    required this.onBackTap,
    required this.onFilterTap,
    required this.onCategorySelected,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isRtl = context.locale.languageCode == 'ar';

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(AppSizes.radius30)),
      ),
      child: Column(
        children: [
          _buildRestaurantImage(theme, isRtl),
          Padding(
            padding: EdgeInsets.fromLTRB(
                AppSizes.p16, AppSizes.p12, AppSizes.p16, AppSizes.p16),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildRestaurantInfo(theme, isRtl),
                    const SizedBox(width: 8),
                    _buildFilterButton(theme),
                  ],
                ),
                const SizedBox(height: 20),
                _buildCategoriesRow(),
                const SizedBox(height: 16),
                _buildSearchField(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantImage(ThemeData theme, bool isRtl) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(AppSizes.radius30)),
          child: CachedNetworkImage(
            imageUrl: restaurant.imageUrl,
            height: 190,
            width: double.infinity,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) => Container(
              height: 190,
              color: theme.dividerColor.withValues(alpha: 0.1),
              child: Icon(Icons.storefront, size: 64,
                  color: theme.hintColor.withValues(alpha: 0.3)),
            ),
          ),
        ),
        Positioned(
          top: AppSizes.p50,
          left: isRtl ? null : AppSizes.p16,
          right: isRtl ? AppSizes.p16 : null,
          child: _buildBackButton(theme),
        ),
      ],
    );
  }

  Widget _buildBackButton(ThemeData theme) {
    return InkWell(
      onTap: onBackTap,
      child: Container(
        padding: EdgeInsets.all(AppSizes.p12),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(AppSizes.radius12),
        ),
        child: Icon(Icons.arrow_back, size: 20, color: theme.iconTheme.color),
      ),
    );
  }

  Widget _buildRestaurantInfo(ThemeData theme, bool isRtl) {
    return Expanded(
      child: Column(
        crossAxisAlignment: isRtl
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          Text(restaurant.name, style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, color: Colors.orange, size: 16),
              const SizedBox(width: 4),
              Text(restaurant.rating.toString(),
                  style: theme.textTheme.bodySmall),
              SizedBox(width: AppSizes.p12),
              Icon(Icons.access_time, color: theme.hintColor, size: 16),
              const SizedBox(width: 4),
              Text("restaurant.delivery_time".tr(args: ["25", "35"]),
                  style: theme.textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(ThemeData theme) {
    return GestureDetector(
      onTap: onFilterTap,
      child: Container(
        padding: EdgeInsets.all(AppSizes.p10),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(AppSizes.radius12),
        ),
        child: Icon(Icons.filter_alt_outlined, color: theme.iconTheme.color),
      ),
    );
  }

  // صف التصنيفات — يُبنى ديناميكياً من تصنيفات المطعم الفعلية القادمة من الباك
  // (GET /api/user/categories/:id)، مع تصنيف "الكل" ثابت في البداية.
  Widget _buildCategoriesRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _CategoryChip(
            label: "all".tr(),
            isSelected: selectedCategoryId == null,
            onTap: () => onCategorySelected(null),
          ),
          for (final category in categories) ...[
            SizedBox(width: AppSizes.p8),
            _CategoryChip(
              label: category.name,
              isSelected: selectedCategoryId == category.id,
              onTap: () => onCategorySelected(category.id),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return TextField(
      onChanged: onSearchChanged,
      decoration: InputDecoration(
        hintText: "filter.search_menu".tr(),
        prefixIcon: Icon(Icons.search, color: theme.hintColor),
        filled: true,
        fillColor: theme.scaffoldBackgroundColor,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip(
      {required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: AppSizes.p20, vertical: AppSizes.p10),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor : theme
              .scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(AppSizes.radius14),
        ),
        child: Text(label, style: TextStyle(
            color: isSelected ? Colors.white : theme.hintColor,
            fontWeight: FontWeight.bold)),
      ),
    );
  }
}