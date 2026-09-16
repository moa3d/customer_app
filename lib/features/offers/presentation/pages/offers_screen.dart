import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:nomnow_app/features/offers/presentation/widgets/offers_count_banner.dart';

import '../../../../core/network/app_error.dart';
import '../../../../core/utils/app_sizes.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../restaurant_offer/presentation/pages/restaurant_offers_pages.dart';
import '../../data/services/promotions_service.dart';
import '../../domain/models/offer_model.dart';
import '../widgets/offer_card.dart';

class OffersScreen extends StatefulWidget {
  final Function(int, {dynamic data}) movePage;

  const OffersScreen({super.key, required this.movePage});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  List<int> _selectedFilterIndices = [0];
  final List<Offer> _allOffers = [];
  bool _isLoading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _fetchPromotions();
  }

  Future<void> _fetchPromotions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await PromotionsService().getPromotions();
      if (response.statusCode == 200 && response.data['success'] == true) {
        final promotions = response.data['promotions'] as List;
        setState(() {
          _allOffers.clear();
          _allOffers.addAll(
            promotions.map((p) => Offer.fromJson(p)),
          );
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = AppError.ofKind(AppErrorKind.server);
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(theme),
      body: _isLoading
          ? _buildLoading()
          : _error != null
              ? _buildError()
              : _allOffers.isEmpty
                  ? _buildEmpty()
                  : _buildOffersList(),
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildError() {
    return AppErrorView.fromError(_error, onRetry: _fetchPromotions);
  }

  Widget _buildEmpty() {
    return AppErrorView.empty(
      icon: Icons.local_offer_outlined,
      title: 'offers.no_offers'.tr(),
    );
  }

  Widget _buildOffersList() {
    return RefreshIndicator(
      onRefresh: _fetchPromotions,
      child: ListView.builder(
        cacheExtent: 1000,
        itemCount: _allOffers.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) return OffersCountBanner(count: _allOffers.length);

          final offer = _allOffers[index - 1];
          return OfferCard(
            offer: offer,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ResturantOffersPage(movePagge: widget.movePage, offer: offer),
              ),
            ),
            onFavoriteToggle: () {},
          );
        },
      ),
    );
  }

  void _onFilterTapped(int index) {
    setState(() {
      if (_selectedFilterIndices.contains(index)) {
        if (_selectedFilterIndices.length > 1) {
          _selectedFilterIndices.remove(index);
        }
      } else {
        if (index == 0) {
          _selectedFilterIndices = [0];
        } else {
          _selectedFilterIndices.remove(0);
          _selectedFilterIndices.add(index);
        }
      }
      if (_selectedFilterIndices.isEmpty) _selectedFilterIndices.add(0);
    });
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      scrolledUnderElevation: 0,
      backgroundColor: theme.cardColor,
      automaticallyImplyLeading: false,
      toolbarHeight: 170,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
            bottomRight: Radius.circular(16), bottomLeft: Radius.circular(16)),
      ),
      flexibleSpace: SafeArea(
        child: Column(
          children: [
            _buildTopBar(theme),
            const SizedBox(height: 30),
            _buildFilterList(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Material(
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12))),
            color: theme.primaryColor.withValues(alpha: 0.3),
            child: InkWell(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              onTap: () => context.pop(),
              child: const SizedBox(
                  height: 40,
                  width: 40,
                  child: Center(child: Icon(Icons.arrow_back))),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('offers.screen_title'.tr(),
                  style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Text("%", style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                      fontSize: 16)),
                  AppSizes.w4,
                  Text("offers.screen_subtitle".tr(), style: TextStyle(
                      color: theme.textTheme.titleMedium?.color, fontSize: 14)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterList(ThemeData theme) {
    final filterTitles = [
      "filters.all".tr(),
      "filters.meals".tr(),
      "filters.drinks".tr(),
      "filters.random".tr()
    ];
    final filterIcons = [
      Icons.apps,
      Icons.fastfood_outlined,
      Icons.local_bar_outlined,
      Icons.shuffle
    ];

    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: filterTitles.length,
        itemBuilder: (context, index) {
          final bool isSelected = _selectedFilterIndices.contains(index);
          return GestureDetector(
            onTap: () => _onFilterTapped(index),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected ? theme.primaryColor : theme
                    .scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(filterIcons[index],
                      color: isSelected ? Colors.white : theme.hintColor,
                      size: 18),
                  const SizedBox(width: 8),
                  Text(
                    filterTitles[index],
                    style: TextStyle(
                        color: isSelected ? Colors.white : theme.textTheme
                            .bodyLarge?.color, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
