import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../restaurant/data/models/meal.dart';
import '../../../restaurant/data/services/restaurant_service.dart';
import '../../data/models/catalog_args.dart';
import '../../data/models/catalog_sort.dart';
import '../widgets/catalog_sort_bar.dart';
import '../widgets/meal_card.dart';

/// شاشة «جميع الوجبات» — الوجهة الصحيحة لزر «عرض المزيد» بجانب القسم.
/// تعرض القائمة كاملة في شبكة بعمودين بدل الشريط الأفقي القصير في الرئيسية.
class AllMealsPage extends StatefulWidget {
  final CatalogArgs<Meal> args;

  const AllMealsPage({super.key, required this.args});

  @override
  State<AllMealsPage> createState() => _AllMealsPageState();
}

class _AllMealsPageState extends State<AllMealsPage> {
  final RestaurantService _service = RestaurantService();

  late List<Meal> _items;
  late String? _filterLabel;
  late CatalogSort _sort;

  /// القسم العام الموروث من الرئيسية — يُرسل كـ `mainCategory` في كل جلب.
  late String? _mainCategoryId;

  bool _isLoading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    // عرض فوري لما كان معروضاً في الرئيسية — بلا انتظار شبكة
    _items = widget.args.initialItems;
    _filterLabel = widget.args.activeFilterLabel;
    // نرث ترتيب الرئيسية وقسمها بدل العودة للافتراضي، وإلا رأى المستخدم
    // قائمة مختلفة عمّا ضغط عليه للتوّ
    _sort = widget.args.sort;
    _mainCategoryId = widget.args.mainCategoryId;
  }

  Future<void> _fetch({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _service.getAllFood(
        lat: widget.args.lat,
        lng: widget.args.lng,
        sort: _sort.queryValue,
        mainCategory: _mainCategoryId,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;

      final data = response.data?['foods'];
      final List<Meal> fetched =
          data is List ? data.map((j) => Meal.fromJson(j)).toList() : <Meal>[];

      setState(() {
        _items = fetched;
        // القسم يبقى مطبَّقاً في الباك عبر mainCategory، فلا نُسقط شارته.
        // أما فلتر العروض المحلي فالجلب الجديد يتجاوزه.
        if (_mainCategoryId == null) _filterLabel = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e;
      });
    }
  }

  void _onSortChanged(CatalogSort sort) {
    if (_sort == sort) return;
    setState(() => _sort = sort);
    _fetch();
  }

  void _clearFilter() {
    // إزالة القسم تستلزم إعادة جلب: الفلترة تحدث في الباك لا محلياً.
    if (_mainCategoryId != null) {
      setState(() {
        _mainCategoryId = null;
        _filterLabel = null;
      });
      _fetch();
      return;
    }
    setState(() {
      _items = widget.args.allItems;
      _filterLabel = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text("home_all_meals".tr(),
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          CatalogSortBar(
            selected: _sort,
            onChanged: _onSortChanged,
            activeFilterLabel: _filterLabel,
            onClearFilter: _clearFilter,
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  static const _gridDelegate =
      SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    childAspectRatio: 0.78,
  );

  Widget _buildBody() {
    if (_isLoading) {
      return GridView.builder(
        itemCount: 6,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        gridDelegate: _gridDelegate,
        itemBuilder: (_, _) => const ShimmerMealCard(),
      );
    }

    if (_error != null) {
      return AppErrorView.fromError(_error, onRetry: _fetch);
    }

    if (_items.isEmpty) {
      return AppErrorView.empty(
        icon: Icons.fastfood_outlined,
        // القسم قد يكون فارغاً في بلد المستخدم: MainCategory بلا حقل country
        // بينما الأكل مفلتر بالبلد.
        title: _mainCategoryId != null
            ? "no_meals_in_category".tr()
            : "no_meals_found".tr(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetch(forceRefresh: true),
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _items.length,
        padding: const EdgeInsets.fromLTRB(15, 8, 15, 100),
        gridDelegate: _gridDelegate,
        itemBuilder: (context, index) {
          final meal = _items[index];
          return GestureDetector(
            onTap: () => context.push('/home/meal-details', extra: meal),
            child: MealCard(meal: meal),
          );
        },
      ),
    );
  }

}
