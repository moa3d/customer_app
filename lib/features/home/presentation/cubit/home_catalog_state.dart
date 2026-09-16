import 'package:equatable/equatable.dart';

import '../../../restaurant/data/models/meal.dart';
import '../../../restaurant/data/models/restaurant.dart';
import '../../data/models/catalog_sort.dart';
import '../../data/models/main_category.dart';

/// حالة كتالوج الشاشة الرئيسية — الفلاتر والقوائم معاً.
///
/// القائمتان مفصولتان عمداً: `allMeals`/`allRestaurants` هي ما أعاده الباك،
/// و`meals`/`restaurants` هي المعروضة بعد الفلاتر المحلية (العروض، تضييق
/// المطاعم على القسم). الفصل يسمح بإلغاء البحث أو شريحة العروض بلا نداء شبكة.
class HomeCatalogState extends Equatable {
  final CatalogSort sort;

  /// معرّف القسم العام المختار — null يعني «الكل».
  final String? mainCategoryId;

  /// شريحة «العروض» — فلترة محلية على العروض الواصلة مع كل صنف.
  final bool offersOnly;

  final List<MainCategory> mainCategories;

  final List<Meal> allMeals;
  final List<Restaurant> allRestaurants;

  final List<Meal> meals;
  final List<Restaurant> restaurants;

  /// هل استعمل الباك موقعاً فعلياً في الترتيب؟ عند false تسقط المسافة من
  /// النتائج ويتطابق ترتيب «الأقرب» مع «الأعلى تقييماً».
  final bool locationUsed;

  /// نص العنوان المعروض في الترويسة («دمشق - المزة»).
  final String? addressLabel;

  /// هل أعلن الباك أن محور الترتيب المطلوب بلا بيانات إطلاقاً؟
  ///
  /// `Restaurant.rating` لا يُكتب إلا حين يقيّم مستخدمٌ وجبةً، فعلى قاعدة
  /// بيانات جديدة تكون كل التقييمات صفراً و«الأعلى تقييماً» بلا معنى — تُرجع
  /// القائمة نفسها التي يُرجعها «الأقرب». نقولها للمستخدم بدل قائمة تبدو
  /// معطّلة. المصدر حقل `sortSignal` في الرد؛ غيابه يعني «توجد إشارة».
  final bool sortHasNoSignal;

  /// أول تحميل — تعرض الواجهة shimmer كاملاً.
  final bool isLoading;

  /// إعادة جلب فوق بيانات معروضة أصلاً — مؤشّر فوق المحتوى لا بدلاً منه.
  final bool isFiltering;

  final Object? error;

  const HomeCatalogState({
    this.sort = CatalogSort.nearest,
    this.mainCategoryId,
    this.offersOnly = false,
    this.mainCategories = const [],
    this.allMeals = const [],
    this.allRestaurants = const [],
    this.meals = const [],
    this.restaurants = const [],
    this.locationUsed = false,
    this.addressLabel,
    this.sortHasNoSignal = false,
    this.isLoading = true,
    this.isFiltering = false,
    this.error,
  });

  /// هل هناك فلتر محلي أو قسم مفعّل؟ حارس داخلي لـ `clearFilters` يمنع إعادة
  /// جلب بلا موجب. الرئيسية لا تعرض زر «إزالة الفلتر»: الإلغاء بشريحة «الكل»
  /// أو بإعادة الضغط على شريحة «العروض».
  bool get hasActiveFilter => mainCategoryId != null || offersOnly;

  /// تنبيه «فعّل الموقع».
  ///
  /// لا يُعرض مع تنبيه الترتيب معاً، وتنبيه الموقع له الأولوية لأنه قابل
  /// للإصلاح من المستخدم بينما غياب التقييمات ليس بيده شيء. القاعدة هنا
  /// لا في الويدجت حتى تكون قابلة للاختبار بلا widget test مكلف.
  bool get showLocationNotice => !locationUsed;

  /// تنبيه «لا توجد تقييمات/طلبات بعد — الترتيب حسب الأقرب».
  ///
  /// يشترط [locationUsed] لأن الأولوية لتنبيه الموقع.
  bool get showSortNotice => sortHasNoSignal && locationUsed;

  /// اسم القسم المختار، أو null إن كان «الكل» أو لم يصل بعد.
  String? get selectedMainCategoryName {
    if (mainCategoryId == null) return null;
    for (final category in mainCategories) {
      if (category.id == mainCategoryId) return category.name;
    }
    return null;
  }

  HomeCatalogState copyWith({
    CatalogSort? sort,
    String? mainCategoryId,
    bool clearMainCategory = false,
    bool? offersOnly,
    List<MainCategory>? mainCategories,
    List<Meal>? allMeals,
    List<Restaurant>? allRestaurants,
    List<Meal>? meals,
    List<Restaurant>? restaurants,
    bool? locationUsed,
    String? addressLabel,
    bool? sortHasNoSignal,
    bool? isLoading,
    bool? isFiltering,
    Object? error,
    bool clearError = false,
  }) {
    return HomeCatalogState(
      sort: sort ?? this.sort,
      mainCategoryId:
          clearMainCategory ? null : (mainCategoryId ?? this.mainCategoryId),
      offersOnly: offersOnly ?? this.offersOnly,
      mainCategories: mainCategories ?? this.mainCategories,
      allMeals: allMeals ?? this.allMeals,
      allRestaurants: allRestaurants ?? this.allRestaurants,
      meals: meals ?? this.meals,
      restaurants: restaurants ?? this.restaurants,
      locationUsed: locationUsed ?? this.locationUsed,
      addressLabel: addressLabel ?? this.addressLabel,
      sortHasNoSignal: sortHasNoSignal ?? this.sortHasNoSignal,
      isLoading: isLoading ?? this.isLoading,
      isFiltering: isFiltering ?? this.isFiltering,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
        sort,
        mainCategoryId,
        offersOnly,
        mainCategories,
        allMeals,
        allRestaurants,
        meals,
        restaurants,
        locationUsed,
        addressLabel,
        sortHasNoSignal,
        isLoading,
        isFiltering,
        error,
      ];
}
