import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../restaurant/data/models/restaurant.dart';
import '../../../restaurant/data/services/restaurant_service.dart';
import '../../data/models/catalog_args.dart';
import '../../data/models/catalog_sort.dart';
import '../widgets/catalog_sort_bar.dart';
import '../widgets/location_notice.dart';
import '../widgets/restaurant_card.dart';

/// شاشة «جميع المطاعم» — الوجهة الصحيحة لزر «عرض المزيد» بجانب القسم.
/// تعرض القائمة كاملة عمودياً بدل الشريط الأفقي القصير في الرئيسية.
class AllRestaurantsPage extends StatefulWidget {
  final CatalogArgs<Restaurant> args;

  const AllRestaurantsPage({super.key, required this.args});

  @override
  State<AllRestaurantsPage> createState() => _AllRestaurantsPageState();
}

class _AllRestaurantsPageState extends State<AllRestaurantsPage> {
  final RestaurantService _service = RestaurantService();

  late List<Restaurant> _items;
  late String? _filterLabel;
  late CatalogSort _sort;
  late bool _locationUsed;

  bool _isLoading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    // عرض فوري لما كان معروضاً في الرئيسية — بلا انتظار شبكة
    _items = widget.args.initialItems;
    _filterLabel = widget.args.activeFilterLabel;
    // نرث ترتيب الرئيسية بدل العودة للافتراضي، وإلا رأى المستخدم قائمة
    // مرتّبة بشكل مختلف عمّا ضغط عليه للتوّ
    _sort = widget.args.sort;
    _locationUsed = widget.args.locationUsed;
  }

  Future<void> _fetch({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _service.getAllRestaurants(
        lat: widget.args.lat,
        lng: widget.args.lng,
        sort: _sort.queryValue,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;

      final data = response.data?['restaurant'];
      final List<Restaurant> fetched = data is List
          ? data.map((j) => Restaurant.fromJson(j)).toList()
          : <Restaurant>[];

      setState(() {
        // بلا إعادة ترتيب محلية: الباك يرتّب بـ «0.7 قرب + 0.3 تقييم»، وفرزٌ
        // بالمسافة الصرفة هنا يمحو نصف المعادلة ويخالف ترتيب قائمة الوجبات
        // التي لا تحمل distance أصلاً.
        _items = fetched;
        _locationUsed = response.data?['locationUsed'] == true;
        // الجلب الجديد يتجاوز فلتر الرئيسية الموروث
        _filterLabel = null;
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
        title: Text("home_all_restaurants".tr(),
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
          if (!_locationUsed)
            LocationNotice(onTap: () => context.push('/account/addresses')),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 100),
            sliver: SliverGrid(
              gridDelegate: _gridDelegate,
              delegate: SliverChildBuilderDelegate(
                (_, _) => const Padding(
                  padding: EdgeInsets.all(4),
                  child: ShimmerRestaurantCard(),
                ),
                childCount: 6,
              ),
            ),
          ),
        ],
      );
    }

    if (_error != null) {
      return AppErrorView.fromError(_error, onRetry: _fetch);
    }

    if (_items.isEmpty) {
      return AppErrorView.empty(
        icon: Icons.storefront_outlined,
        title: "no_restaurants_found".tr(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetch(forceRefresh: true),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 100),
            sliver: SliverGrid(
              gridDelegate: _gridDelegate,
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final res = _items[index];
                  return Padding(
                    padding: const EdgeInsets.all(4),
                    child: GestureDetector(
                      onTap: () =>
                          context.push('/home/restaurant-details', extra: res),
                      child: RestaurantCard(
                        name: res.name,
                        description: res.description,
                        rate: res.rating.toString(),
                        distance:
                            res.distance?.toStringAsFixed(1) ?? "--",
                        imageUrl: res.imageUrl,
                      ),
                    ),
                  );
                },
                childCount: _items.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverGridDelegate get _gridDelegate =>
      const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.75,
      );

}
