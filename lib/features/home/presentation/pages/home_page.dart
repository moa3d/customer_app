import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';


//  تحديث الاستيرادات للمجلد المنظم
import '../../../../core/routing/routes.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/utils/app_sizes.dart';
import '../../../favorite/cubit/favorite_cubit.dart';
import '../../../restaurant/data/models/meal.dart';
import '../../../restaurant/data/models/restaurant.dart';
import '../../data/models/catalog_args.dart';
import '../../data/models/catalog_sort.dart';
import '../cubit/home_catalog_cubit.dart';
import '../cubit/home_catalog_state.dart';
import '../widgets/catalog_sort_bar.dart';
import '../widgets/location_notice.dart';
import '../widgets/main_category_bar.dart';
import '../widgets/meal_card.dart';
import '../widgets/restaurant_card.dart';


import '../../../auth/presentation/pages/banned_account_screen.dart';

class HomBody extends StatefulWidget {
  final Function(int index, {dynamic data}) triggerPageChange;
  final String userAuthToken;

  const HomBody({
    super.key,
    required this.userAuthToken,
    required this.triggerPageChange,
  });

  @override
  State<HomBody> createState() => _HomBodyState();
}

class _HomBodyState extends State<HomBody> {
  String _personName = "";
  String? _personImgUrl;

  final AuthService _authManager = AuthService();

  final ScrollController _restaurantScrollController = ScrollController();

  HomeCatalogCubit get _catalog => context.read<HomeCatalogCubit>();

  @override
  void initState() {
    super.initState();
    _loadProfile();
    // العناوين لم تُقرأ هنا بعد الآن — UserLocationService داخل الـ cubit
    // يقرأها ويحلّ الإحداثيات، فسقط نداء user-addresses المكرَّر.
    _catalog.loadInitial();
    context.read<FavoriteCubit>().fetchFavorites();
  }

  Future<void> _loadProfile() async {
    try {
      final user = await _authManager.getUserProfile();
      if (user.isBanned) {
        if (mounted) _redirectToBanned();
        return;
      }
      if (!mounted) return;
      setState(() {
        _personName = user.name;
        _personImgUrl = user.imgUrl;
      });
    } catch (_) {
      // فشل الملف الشخصي لا يمنع الكتالوج من العمل
    }
  }

  void _redirectToBanned() {
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (c) => const BannedAccountScreen()));
  }

  @override
  void dispose() {
    _restaurantScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<HomeCatalogCubit, HomeCatalogState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: _buildTopHeaderArea(theme, isDark, state),
          body: state.isLoading
              ? const ShimmerHomePage()
              : state.error != null
                  ? _buildErrorView(state)
                  : Stack(
                      children: [
                        _buildMainScrollableContent(theme, state),
                        if (state.isFiltering)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 200),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                      ],
                    ),
        );
      },
    );
  }

  PreferredSizeWidget _buildTopHeaderArea(
      ThemeData theme, bool isDark, HomeCatalogState state) {
    return AppBar(
      backgroundColor: theme.cardColor,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leading: _buildProfileAvatar(theme),
      title: _buildLocationTitle(theme, state),
      actions: [
        IconButton(
          icon: Icon(Icons.notifications_none_outlined,
              color: isDark ? Colors.white : Colors.black),
          onPressed: () => widget.triggerPageChange(6),
        ),
      ],
    );
  }

  Widget _buildProfileAvatar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: CircleAvatar(
        radius: 15,
        backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
        backgroundImage: (_personImgUrl != null && _personImgUrl!.isNotEmpty)
            ? CachedNetworkImageProvider(_personImgUrl!)
            : const AssetImage("assets/images/profile.png") as ImageProvider,
      ),
    );
  }

  Widget _buildLocationTitle(ThemeData theme, HomeCatalogState state) {
    final label = state.addressLabel?.trim();
    final hasLabel = label != null && label.isNotEmpty && label != '-';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.triggerPageChange(9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _personName.isEmpty ? "home_welcome_back".tr() : _personName,
            style: TextStyle(
                color: theme.textTheme.bodyLarge?.color, fontSize: 16),
          ),
          AppSizes.h4,
          Row(
            children: [
              Icon(Icons.location_on_outlined, color: theme.primaryColor,
                  size: 14),
              Expanded(
                child: Text(
                  hasLabel ? label : "loading_location".tr(),
                  style: TextStyle(color: theme.hintColor, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainScrollableContent(ThemeData theme, HomeCatalogState state) {
    return RefreshIndicator(
      onRefresh: () => _catalog.refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBoxSection(theme),
            _buildPromoBannerArea(),
            // بلا موقع يسقط عامل القرب من ترتيب الباك، فيتطابق «الأقرب» مع
            // «الأعلى تقييماً» وتعود المسافة null. نقولها للمستخدم صريحةً.
            // قاعدة الأولوية بين التنبيهين في HomeCatalogState لا هنا.
            if (state.showLocationNotice)
              LocationNotice(onTap: () => widget.triggerPageChange(9)),
            CatalogSortBar(
              selected: state.sort,
              onChanged: _catalog.changeSort,
            ),
            if (state.showSortNotice)
              HomeNotice(
                icon: Icons.info_outline,
                message: state.sort == CatalogSort.popular
                    ? "sort_no_orders_hint".tr()
                    : "sort_no_ratings_hint".tr(),
              ),
            _buildCategoryRow(state),
            _buildResturantsVerticalList(theme, state),
            AppSizes.h24,
            _buildMealsGridView(theme, state),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  /// شريحة «العروض» مثبَّتة قبل الأقسام حتى تبقى في المتناول مهما طال الشريط.
  /// هي فلترة محلية على `promotions` الواصلة مع كل صنف، لا ترتيباً في الباك.
  Widget _buildCategoryRow(HomeCatalogState state) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 15),
            child: CategoryChip(
              label: "filter_offers".tr(),
              icon: Icons.local_offer_outlined,
              isSelected: state.offersOnly,
              onTap: _catalog.toggleOffersOnly,
            ),
          ),
          Expanded(
            child: MainCategoryBar(
              categories: state.mainCategories,
              selectedId: state.mainCategoryId,
              onSelected: _catalog.selectMainCategory,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBoxSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            title: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text("home_welcome_back".tr(),
                  style: TextStyle(color: theme.hintColor, fontSize: 14)),
            ),
            subtitle: _buildGreetingText(theme),
          ),
          _buildSearchField(theme),
        ],
      ),
    );
  }

  Widget _buildGreetingText(ThemeData theme) {
    return Row(
      children: [
        Text("home_order_favorite_part1".tr(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(width: 5),
        Text("home_order_favorite_part2".tr(), style: TextStyle(
            color: theme.primaryColor,
            fontSize: 18,
            fontWeight: FontWeight.bold)),
      ],
    );
  }

  /// حقل البحث للعرض فقط — النقر يفتح صفحة البحث المستقلة.
  /// الرئيسية لا تفلتر إطلاقاً وتعرض الكتالوج فقط.
  Widget _buildSearchField(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: TextFormField(
        readOnly: true,
        onTap: () => context.push(Routes.search),
        decoration: InputDecoration(
          fillColor: theme.scaffoldBackgroundColor,
          filled: true,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: const Icon(Icons.tune_rounded),
          hintText: "home_search_hint".tr(),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildPromoBannerArea() {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: GestureDetector(
        onTap: () => widget.triggerPageChange(5),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset("assets/images/offers.png", height: 208,
              width: double.infinity,
              fit: BoxFit.cover,
              // حدّ من حجم فك الترميز — شاشات المحاكي تضيق بذاكرة GPU
              // عند فك صور كبيرة الحجم.
              cacheWidth: 1000),
        ),
      ),
    );
  }

  Widget _buildMealsGridView(ThemeData theme, HomeCatalogState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("home_all_meals".tr(), () => _openAllMeals(state)),
        SizedBox(
          height: 200,
          child: state.meals.isEmpty
              ? _buildEmptyStrip(theme, _emptyMealsLabel(state))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.meals.length,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemBuilder: (context, index) {
                    final meal = state.meals[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () => widget.triggerPageChange(8, data: meal),
                        child: MealCard(meal: meal, width: 160),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// القسم المختار قد يكون فارغاً تماماً في بلد المستخدم: موديل `MainCategory`
  /// في الباك بلا حقل country بينما الأكل مفلتر بالبلد. نميّز هذه الحالة عن
  /// «لا نتائج» العامة حتى يعرف المستخدم أن الحل هو إزالة الفلتر.
  String _emptyMealsLabel(HomeCatalogState state) {
    if (state.mainCategoryId != null) return "no_meals_in_category".tr();
    if (state.offersOnly) return "no_meals_with_offers".tr();
    return "no_meals_found".tr();
  }

  Widget _buildEmptyStrip(ThemeData theme, String label) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_outlined,
                size: 28, color: theme.hintColor.withValues(alpha: 0.6)),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.hintColor, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildResturantsVerticalList(
      ThemeData theme, HomeCatalogState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
            "home_all_restaurants".tr(), () => _openAllRestaurants(state)),
        SizedBox(
          height: 210,
          child: state.restaurants.isEmpty
              ? _buildEmptyStrip(theme, "no_restaurants_found".tr())
              : ListView.builder(
                  controller: _restaurantScrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: state.restaurants.length,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemBuilder: (context, index) {
                    final Restaurant res = state.restaurants[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () => widget.triggerPageChange(7, data: res),
                        child: SizedBox(
                          width: 240,
                          height: 210,
                          child: RestaurantCard(
                            name: res.name,
                            description: res.description,
                            rate: res.rating.toString(),
                            // "--" لا "0" — المسافة غير معروفة، لا صفر
                            distance: res.distance?.toStringAsFixed(1) ?? "--",
                            imageUrl: res.imageUrl,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // كل قسم يمرّر وجهته الخاصة — سابقاً كان الزر يثبّت العروض للقسمين معاً
  Widget _buildSectionHeader(String title, VoidCallback onViewMore) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold)),
          TextButton(
            onPressed: onViewMore,
            child: Text("home_view_more".tr())),
        ],
      ),
    );
  }

  void _openAllRestaurants(HomeCatalogState state) {
    context.push(
      Routes.allRestaurants,
      extra: CatalogArgs<Restaurant>(
        initialItems: state.restaurants,
        allItems: state.allRestaurants,
        activeFilterLabel: _activeFilterLabel(state),
        sort: state.sort,
        mainCategoryId: state.mainCategoryId,
        lat: _catalog.coords?.lat,
        lng: _catalog.coords?.lng,
        locationUsed: state.locationUsed,
      ),
    );
  }

  void _openAllMeals(HomeCatalogState state) {
    context.push(
      Routes.allMeals,
      extra: CatalogArgs<Meal>(
        initialItems: state.meals,
        allItems: state.allMeals,
        activeFilterLabel: _activeFilterLabel(state),
        sort: state.sort,
        mainCategoryId: state.mainCategoryId,
        lat: _catalog.coords?.lat,
        lng: _catalog.coords?.lng,
        locationUsed: state.locationUsed,
      ),
    );
  }

  /// عنوان الفلتر المفعّل حالياً، أو null إن لم يكن هناك فلتر
  String? _activeFilterLabel(HomeCatalogState state) {
    return state.selectedMainCategoryName ??
        (state.offersOnly ? "filter_offers".tr() : null);
  }

  Widget _buildErrorView(HomeCatalogState state) {
    return AppErrorView.fromError(
      state.error,
      onRetry: _catalog.refresh,
    );
  }
}
