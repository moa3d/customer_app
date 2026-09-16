import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/utils/app_sizes.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../data/models/meal.dart';
import '../../data/models/restaurant.dart';
import '../../data/models/category.dart';
import '../../data/services/restaurant_service.dart';
import '../widgets/featured_dish_widget.dart';
import '../widgets/menu_item_widget.dart';
import '../widgets/filter_bottom_sheet.dart';

class ResturantPage extends StatefulWidget {
  final Restaurant restaurant;
  final String token;
  final Function(int, {dynamic data}) movePage;

  const ResturantPage({
    super.key,
    required this.restaurant,
    required this.token,
    required this.movePage,
  });

  @override
  State<ResturantPage> createState() => _ResturantPageState();
}

class _ResturantPageState extends State<ResturantPage> {
  // التصنيف المحدَّد حالياً لفلترة القائمة — null تعني "الكل"
  String? _selectedCategoryId;
  List<FoodCategory> _categories = [];
  final RestaurantService _restaurantService = RestaurantService();

  List<Meal> _foodzListData = [];
  List<Meal> _featuredFoods = [];
  List<Meal> _filteredFoods = [];
  bool _isDataLoading = true;
  Object? _error;

  // فلاتر
  String _searchQuery = '';
  String _sortBy = 'default';
  double? _minPrice;
  double? _maxPrice;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadRestaurantMenu();
  }

  // جلب تصنيفات المطعم (GET /api/user/categories/:id) لعرضها كفلاتر فوق القائمة
  Future<void> _loadCategories() async {
    try {
      final response = await _restaurantService.getCategories(
          widget.restaurant.id);
      if (!mounted) return;
      final rawCategories = response.data['categories'] as List? ?? [];
      setState(() {
        _categories =
            rawCategories.map((j) => FoodCategory.fromJson(j)).toList();
      });
    } catch (e) {
      // فشل جلب التصنيفات ليس خطأً حرجاً — تبقى القائمة معروضة كاملة بدون فلترة
    }
  }

  // جلب بيانات المنيو والوجبات المميزة من السيرفر، مع فلترة اختيارية بتصنيف محدَّد
  Future<void> _loadRestaurantMenu() async {
    if (!mounted) return;
    setState(() {
      _isDataLoading = true;
      _error = null;
    });

    try {
      final response = await _restaurantService.getFoodByRestaurant(
          widget.restaurant.id,
          category: _selectedCategoryId);
      if (mounted) {
        setState(() {
          if (response.data['foods'] != null) {
            _foodzListData = (response.data['foods'] as List)
                .map((j) => Meal.fromJson(j))
                .toList();
          }
          if (response.data['featuredFoods'] != null) {
            _featuredFoods = (response.data['featuredFoods'] as List).map((j) =>
                Meal.fromJson(j)).toList();
          }
          _isDataLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDataLoading = false;
          _error = e;
        });
      }
    }
  }

  // عند اختيار تصنيف من الشريط العلوي: نحدّث الحالة ونعيد جلب القائمة مفلترة
  void _onCategorySelected(String? categoryId) {
    if (categoryId == _selectedCategoryId) return;
    setState(() => _selectedCategoryId = categoryId);
    _loadRestaurantMenu();
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _applyFilters();
  }

  void _applyFilters() {
    List<Meal> result = List.from(_foodzListData);

    if (_searchQuery.isNotEmpty) {
      result = result.where((m) =>
          m.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    if (_minPrice != null) {
      result = result.where((m) => m.price >= _minPrice!).toList();
    }
    if (_maxPrice != null) {
      result = result.where((m) => m.price <= _maxPrice!).toList();
    }

    switch (_sortBy) {
      case 'price_low':
        result.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        result.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'rating':
        result.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }

    setState(() => _filteredFoods = result);
  }

  Widget _buildCategoriesRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildCategoryChip("all".tr(), _selectedCategoryId == null, () => _onCategorySelected(null)),
          for (final category in _categories) ...[
            SizedBox(width: AppSizes.p8),
            _buildCategoryChip(category.name, _selectedCategoryId == category.id, () => _onCategorySelected(category.id)),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected, VoidCallback onTap) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: AppSizes.p20, vertical: AppSizes.p10),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor : theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(AppSizes.radius14),
        ),
        child: Text(label, style: TextStyle(
            color: isSelected ? Colors.white : theme.hintColor,
            fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return TextField(
      onChanged: _onSearchChanged,
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

  Future<void> _showFilterSheet() async {
    final allPrices = _foodzListData.map((m) => m.price).toList();
    final minAvail = allPrices.isNotEmpty ? allPrices.reduce((a, b) => a < b ? a : b) : 0.0;
    final maxAvail = allPrices.isNotEmpty ? allPrices.reduce((a, b) => a > b ? a : b) : 100000.0;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FilterBottomSheet(
        currentSort: _sortBy,
        currentMinPrice: _minPrice,
        currentMaxPrice: _maxPrice,
        minAvailablePrice: minAvail,
        maxAvailablePrice: maxAvail,
      ),
    );

    if (result != null) {
      setState(() {
        _sortBy = result['sortBy'] ?? 'default';
        _minPrice = result['minPrice'];
        _maxPrice = result['maxPrice'];
      });
      _applyFilters();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isRtl = context.locale.languageCode == 'ar';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _isDataLoading
          ? const ShimmerRestaurantMenu()
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  backgroundColor: theme.cardColor,
                  leading: const SizedBox.shrink(),
                  flexibleSpace: FlexibleSpaceBar(
                    background: _buildCollapsibleHeader(theme, isRtl),
                    collapseMode: CollapseMode.parallax,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildInfoBar(theme, isRtl),
                ),
                SliverToBoxAdapter(
                  child: _buildBelowHeader(theme),
                ),
                if (_error != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppErrorView.fromError(
                      _error,
                      onRetry: _loadRestaurantMenu,
                      compact: true,
                    ),
                  ),
                if (_filteredFoods.isEmpty && _featuredFoods.isEmpty && _error == null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppErrorView.empty(
                      icon: Icons.restaurant_menu_outlined,
                      title: "filter.no_items_found".tr(),
                      compact: true,
                    ),
                  ),
                if (_filteredFoods.isNotEmpty)
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: AppSizes.p16),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: AppSizes.p12,
                        mainAxisSpacing: AppSizes.p12,
                        childAspectRatio: 0.73,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => MenuItemWidget(
                          food: _filteredFoods[index],
                          movePage: widget.movePage,
                        ),
                        childCount: _filteredFoods.length,
                      ),
                    ),
                  ),
                if (_featuredFoods.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                          AppSizes.p16, AppSizes.p24, AppSizes.p16, AppSizes.p8),
                      child: Text(
                        "restaurant.featured".tr(),
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => FeaturedDishWidget(
                        meal: _featuredFoods[index],
                        onTap: () => widget.movePage(8, data: _featuredFoods[index]),
                      ),
                      childCount: _featuredFoods.length,
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
    );
  }

  Widget _buildCollapsibleHeader(ThemeData theme, bool isRtl) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: widget.restaurant.imageUrl,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => Container(
            color: theme.dividerColor.withValues(alpha: 0.1),
            child: Icon(Icons.storefront, size: 64,
                color: theme.hintColor.withValues(alpha: 0.3)),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.5),
              ],
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: isRtl ? null : AppSizes.p16,
          right: isRtl ? AppSizes.p16 : null,
          child: _buildBackButton(theme),
        ),
        Positioned(
          bottom: 16,
          left: AppSizes.p16,
          right: AppSizes.p16,
          child: Text(
            widget.restaurant.name,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton(ThemeData theme) {
    return InkWell(
      onTap: () => context.pop(),
      child: Container(
        padding: EdgeInsets.all(AppSizes.p12),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(AppSizes.radius12),
        ),
        child: Icon(Icons.arrow_back, size: 20, color: theme.iconTheme.color),
      ),
    );
  }

  Widget _buildInfoBar(ThemeData theme, bool isRtl) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          AppSizes.p16, AppSizes.p12, AppSizes.p16, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: isRtl
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text(widget.restaurant.rating.toString(),
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
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _showFilterSheet,
            child: Container(
              padding: EdgeInsets.all(AppSizes.p10),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(AppSizes.radius12),
              ),
              child: Icon(Icons.filter_alt_outlined, color: theme.iconTheme.color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBelowHeader(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(AppSizes.radius30)),
      ),
      padding: EdgeInsets.fromLTRB(
          AppSizes.p16, AppSizes.p12, AppSizes.p16, AppSizes.p16),
      child: Column(
        children: [
          _buildCategoriesRow(),
          const SizedBox(height: 16),
          _buildSearchField(theme),
        ],
      ),
    );
  }
}