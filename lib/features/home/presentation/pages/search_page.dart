import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_error_view.dart';
import '../../../restaurant/data/models/meal.dart';
import '../../../restaurant/data/models/restaurant.dart';
import '../../../restaurant/data/services/restaurant_service.dart';
import '../widgets/meal_card.dart';
import '../widgets/restaurant_card.dart';

/// صفحة البحث المستقلة — تُفتح بالنقر على حقل البحث في الرئيسية.
/// الرئيسية نفسها لا تفلتر إطلاقاً وتعرض الكتالوج فقط.
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final RestaurantService _service = RestaurantService();
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  static const Duration _debounceDuration = Duration(milliseconds: 600);

  List<Restaurant> _restaurants = const [];
  List<Meal> _meals = const [];
  bool _isLoading = false;
  bool _hasSearched = false;
  Object? _error;

  /// رقم تسلسلي لتجاهل الردود المتأخرة — الأحدث فقط هو من يُعرض.
  int _requestId = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _restaurants = const [];
        _meals = const [];
        _hasSearched = false;
        _isLoading = false;
        _error = null;
      });
      return;
    }
    _debounce = Timer(_debounceDuration, () => _search(query));
  }

  Future<void> _search(String query) async {
    _debounce?.cancel();
    if (query.trim().isEmpty) return;
    final int id = ++_requestId;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _service.search(query.trim());
      if (!mounted || id != _requestId) return;
      final data = response.data;
      final rawRestaurants = data?['restaurants'];
      final rawFoods = data?['foods'];
      setState(() {
        _restaurants = rawRestaurants is List
            ? rawRestaurants
                .whereType<Map>()
                .map((j) => Restaurant.fromJson(Map<String, dynamic>.from(j)))
                .toList()
            : const [];
        _meals = rawFoods is List
            ? rawFoods
                .whereType<Map>()
                .map((j) => Meal.fromJson(Map<String, dynamic>.from(j)))
                .toList()
            : const [];
        _hasSearched = true;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _isLoading = false;
        _error = e;
      });
    }
  }

  void _clear() {
    _debounce?.cancel();
    _requestId++;
    _controller.clear();
    setState(() {
      _restaurants = const [];
      _meals = const [];
      _hasSearched = false;
      _isLoading = false;
      _error = null;
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
          onSubmitted: _search,
          decoration: InputDecoration(
            hintText: "home_search_hint".tr(),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (context, value, _) {
                if (value.text.isEmpty) return const SizedBox.shrink();
                return IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _clear,
                );
              },
            ),
            filled: true,
            fillColor: theme.cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading && !_hasSearched) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && !_hasSearched) {
      return AppErrorView.fromError(
        _error,
        onRetry: () => _search(_controller.text),
      );
    }
    if (!_hasSearched) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search, size: 48, color: theme.hintColor),
              const SizedBox(height: 12),
              Text(
                "home_search_hint".tr(),
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.hintColor, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }
    if (_restaurants.isEmpty && _meals.isEmpty) {
      return Center(
        child: Text(
          "no_meals_found".tr(),
          style: TextStyle(color: theme.hintColor, fontSize: 14),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _search(_controller.text),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading) const LinearProgressIndicator(minHeight: 2),
            if (_restaurants.isNotEmpty) ...[
              _sectionTitle("home_all_restaurants".tr()),
              SizedBox(
                height: 210,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _restaurants.length,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemBuilder: (context, index) {
                    final res = _restaurants[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () => context.push(
                          '/home/restaurant-details',
                          extra: res,
                        ),
                        child: SizedBox(
                          width: 240,
                          height: 210,
                          child: RestaurantCard(
                            name: res.name,
                            description: res.description,
                            rate: res.rating.toString(),
                            distance:
                                res.distance?.toStringAsFixed(1) ?? "--",
                            imageUrl: res.imageUrl,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            if (_meals.isNotEmpty) ...[
              _sectionTitle("home_all_meals".tr()),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _meals.length,
                padding: const EdgeInsets.fromLTRB(15, 8, 15, 100),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                itemBuilder: (context, index) {
                  final meal = _meals[index];
                  return GestureDetector(
                    onTap: () => context.push(
                      '/home/meal-details',
                      extra: meal,
                    ),
                    child: MealCard(meal: meal),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
