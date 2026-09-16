import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/user_location_service.dart';
import '../../../restaurant/data/models/meal.dart';
import '../../../restaurant/data/models/restaurant.dart';
import '../../../restaurant/data/services/restaurant_service.dart';
import '../../data/models/catalog_sort.dart';
import '../../data/models/main_category.dart';
import 'home_catalog_state.dart';

/// كتالوج الشاشة الرئيسية: الترتيب والأقسام والقوائم.
/// البحث يعيش في صفحة مستقلة `SearchPage` — الرئيسية تعرض الكتالوج فقط.
class HomeCatalogCubit extends Cubit<HomeCatalogState> {
  HomeCatalogCubit({
    RestaurantService? service,
    UserLocationService? locationService,
  })  : _service = service ?? RestaurantService(),
        _location = locationService ?? UserLocationService(),
        super(const HomeCatalogState());

  final RestaurantService _service;
  final UserLocationService _location;

  UserCoords? _coords;
  bool _coordsResolved = false;

  /// أول تحميل: الإحداثيات ثم القوائم والأقسام.
  ///
  /// الـ cubit عام (مسجَّل في `main.dart`) بينما `HomBody` يُعاد إنشاؤه عند
  /// الخروج من الـ shell والعودة إليه — أي عند تسجيل خروج ثم دخول بحساب آخر.
  /// لذلك نُصفّر الحالة والإحداثيات المحلولة هنا، وإلا ورث الحساب الجديد
  /// قوائم الحساب السابق وموقعه.
  Future<void> loadInitial() async {
    _coords = null;
    _coordsResolved = false;
    emit(const HomeCatalogState());
    await Future.wait([_fetchCatalog(), _fetchMainCategories()]);
  }

  Future<void> refresh() => _fetchCatalog(forceRefresh: true);

  Future<void> changeSort(CatalogSort sort) async {
    if (state.sort == sort) return;
    emit(state.copyWith(sort: sort));
    await _fetchCatalog();
  }

  /// اختيار قسم عام — أو null لـ«الكل». يستلزم إعادة جلب لأن الفلترة تحدث
  /// في الباك عبر `mainCategory` لا محلياً.
  /// النقرة الثانية على نفس الشريحة = عودة لـ«الكل» (toggle).
  Future<void> selectMainCategory(String? categoryId) async {
    // Toggle: النقرة الثانية على نفس القسم تلغي الفلتر وتعود للكل.
    if (categoryId != null && state.mainCategoryId == categoryId) {
      emit(state.copyWith(clearMainCategory: true));
      await _fetchCatalog();
      return;
    }
    if (state.mainCategoryId == categoryId) return;
    emit(categoryId == null
        ? state.copyWith(clearMainCategory: true)
        : state.copyWith(mainCategoryId: categoryId));
    await _fetchCatalog();
  }

  /// شريحة «العروض» — محلية بالكامل، بلا نداء شبكة: العروض تصل أصلاً مع كل
  /// صنف في `promotions`.
  void toggleOffersOnly() {
    emit(_withLocalFilters(state.copyWith(offersOnly: !state.offersOnly)));
  }

  /// إزالة القسم وشريحة العروض معاً.
  Future<void> clearFilters() async {
    if (!state.hasActiveFilter) return;
    final needsRefetch = state.mainCategoryId != null;
    emit(state.copyWith(clearMainCategory: true, offersOnly: false));
    if (needsRefetch) {
      await _fetchCatalog();
    } else {
      emit(_withLocalFilters(state));
    }
  }

  // ── الجلب ────────────────────────────────────────────────────────────────

  Future<void> _fetchCatalog({bool forceRefresh = false}) async {
    final bool hasData =
        state.allMeals.isNotEmpty || state.allRestaurants.isNotEmpty;
    emit(state.copyWith(
      isLoading: !hasData,
      isFiltering: hasData,
      clearError: true,
    ));

    try {
      final coords = await _resolveCoords();
      final sort = state.sort.queryValue;

      final responses = await Future.wait([
        _service.getAllRestaurants(
          lat: coords?.lat,
          lng: coords?.lng,
          sort: sort,
          forceRefresh: forceRefresh,
        ),
        _service.getAllFood(
          lat: coords?.lat,
          lng: coords?.lng,
          sort: sort,
          mainCategory: state.mainCategoryId,
          forceRefresh: forceRefresh,
        ),
      ]);
      if (isClosed) return;

      final restaurantData = responses[0].data;
      final foodData = responses[1].data;

      emit(_withLocalFilters(state.copyWith(
        allRestaurants: _parseRestaurants(restaurantData?['restaurant']),
        allMeals: _parseMeals(foodData?['foods']),
        // المفتاح يصل من النداءين بالقيمة نفسها لأن الباك يحلّ الموقع بالطريقة
        // ذاتها فيهما؛ نقرأه من نداء المطاعم لأنه صاحب حقل distance.
        locationUsed: restaurantData?['locationUsed'] == true,
        sortHasNoSignal: _readSortSignal(restaurantData, foodData),
        addressLabel: _location.lastAddressLabel,
        isLoading: false,
        isFiltering: false,
      )));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(isLoading: false, isFiltering: false, error: e));
    }
  }

  /// الأقسام تُجلب مرة واحدة وفشلها لا يُسقط الشاشة — الرئيسية تعمل بلا شريط
  /// أقسام، لكنها لا تعمل بلا قوائم.
  Future<void> _fetchMainCategories() async {
    try {
      final response = await _service.getMainCategories();
      if (isClosed) return;
      final data = response.data?['mainCategories'];
      if (data is! List) return;
      emit(state.copyWith(
        mainCategories: data
            .whereType<Map>()
            .map((j) => MainCategory.fromJson(Map<String, dynamic>.from(j)))
            .where((c) => c.id.isNotEmpty)
            .toList(),
      ));
    } catch (_) {
      // نتجاهل — شريط الأقسام يبقى مخفياً.
    }
  }

  /// هل المحور المطلوب بلا أي بيانات في الردَّين معاً؟
  ///
  /// نشترط اتفاق الردَّين لأن المحورين مستقلان: قد يكون تقييم المطعم صفراً
  /// بينما لأصنافه تقييمات. فإن كان لأحدهما إشارة فالفلتر فعل شيئاً ولا داعي
  /// لتنبيه المستخدم.
  ///
  /// غياب `sortSignal` يعني «توجد إشارة» — الحقل لم يُشحن في الباك بعد،
  /// فتبقى الواجهة صامتة بدل إظهار تنبيه كاذب.
  bool _readSortSignal(dynamic restaurantData, dynamic foodData) {
    if (state.sort == CatalogSort.nearest) return false;
    return restaurantData?['sortSignal'] == 'none' &&
        foodData?['sortSignal'] == 'none';
  }

  Future<UserCoords?> _resolveCoords() async {
    if (_coordsResolved) return _coords;
    _coords = await _location.resolve();
    _coordsResolved = true;
    return _coords;
  }

  /// إحداثيات آخر حلّ — تُمرَّر إلى شاشتَي «عرض المزيد» لتُعيد الجلب بها.
  UserCoords? get coords => _coords;

  // ── الفلاتر المحلية ──────────────────────────────────────────────────────

  /// يبني `meals`/`restaurants` من القائمتين الخام.
  ///
  /// تضييق المطاعم: الباك لا يدعم `mainCategory` على `/restaurant`، فنُبقي
  /// المطاعم التي ظهرت فعلاً في الوجبات الناتجة. هذا تقريب — لا حل كامل —
  /// ومقبول فقط لأن الباك يعيد كل الأصناف دفعة واحدة بلا ترقيم صفحات.
  HomeCatalogState _withLocalFilters(HomeCatalogState base) {
    List<Meal> meals = base.allMeals;
    if (base.offersOnly) {
      meals = meals.where((m) => m.activeDiscountPercent != null).toList();
    }

    List<Restaurant> restaurants = base.allRestaurants;
    if (base.mainCategoryId != null || base.offersOnly) {
      final ids = meals.map((m) => m.restaurantId).toSet();
      restaurants = restaurants.where((r) => ids.contains(r.id)).toList();
    }

    return base.copyWith(meals: meals, restaurants: restaurants);
  }

  // ── التحويل ──────────────────────────────────────────────────────────────

  List<Restaurant> _parseRestaurants(dynamic data) {
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((j) => Restaurant.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }

  List<Meal> _parseMeals(dynamic data) {
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((j) => Meal.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }
}
