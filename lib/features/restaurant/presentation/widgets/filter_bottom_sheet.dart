import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/utils/app_sizes.dart';

class FilterBottomSheet extends StatefulWidget {
  final String currentSort;
  final double? currentMinPrice;
  final double? currentMaxPrice;
  final double minAvailablePrice;
  final double maxAvailablePrice;

  const FilterBottomSheet({
    super.key,
    this.currentSort = 'default',
    this.currentMinPrice,
    this.currentMaxPrice,
    this.minAvailablePrice = 0,
    this.maxAvailablePrice = 100000,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String _selectedSort;
  late RangeValues _priceRange;
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;

  @override
  void initState() {
    super.initState();
    _selectedSort = widget.currentSort;
    final min = widget.currentMinPrice ?? widget.minAvailablePrice;
    final max = widget.currentMaxPrice ?? widget.maxAvailablePrice;
    _priceRange = RangeValues(min, max);
    _minPriceController = TextEditingController(text: min.toInt().toString());
    _maxPriceController = TextEditingController(text: max.toInt().toString());
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSizes.p16, AppSizes.p24, AppSizes.p16, AppSizes.p8,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppSizes.radius24),
          topRight: Radius.circular(AppSizes.radius24),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(theme),
            SizedBox(height: AppSizes.p24),
            _buildSortSection(theme),
            SizedBox(height: AppSizes.p24),
            _buildPriceRangeSection(theme),
            SizedBox(height: AppSizes.p24),
            _buildActionButtons(theme),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppSizes.p14),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSizes.radius12),
              ),
              child: Icon(
                Icons.filter_alt_outlined,
                color: theme.primaryColor,
                size: 24,
              ),
            ),
            SizedBox(width: AppSizes.p16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "filter.title".tr(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "filter.subtitle".tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        IconButton(
          style: IconButton.styleFrom(
            backgroundColor: theme.scaffoldBackgroundColor,
            minimumSize: Size(45, 45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
          ),
          icon: Icon(Icons.close, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildSortSection(ThemeData theme) {
    final sortOptions = [
      {'value': 'default', 'label': 'filter.sort_default'.tr(), 'icon': Icons.sort},
      {'value': 'price_low', 'label': 'filter.sort_price_low'.tr(), 'icon': Icons.arrow_upward},
      {'value': 'price_high', 'label': 'filter.sort_price_high'.tr(), 'icon': Icons.arrow_downward},
      {'value': 'rating', 'label': 'filter.sort_rating'.tr(), 'icon': Icons.star_outline},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "filter.sort_by".tr(),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppSizes.p12),
        ...sortOptions.map((option) {
          final isSelected = _selectedSort == option['value'];
          return GestureDetector(
            onTap: () => setState(() => _selectedSort = option['value'] as String),
            child: Container(
              margin: EdgeInsets.only(bottom: AppSizes.p8),
              padding: EdgeInsets.all(AppSizes.p12),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.primaryColor
                    : theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(AppSizes.radius12),
              ),
              child: Row(
                children: [
                  Icon(
                    option['icon'] as IconData,
                    color: isSelected ? Colors.white : theme.hintColor,
                    size: 20,
                  ),
                  SizedBox(width: AppSizes.p12),
                  Expanded(
                    child: Text(
                      option['label'] as String,
                      style: TextStyle(
                        color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPriceRangeSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "filter.price_range".tr(),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppSizes.p12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minPriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "Min",
                  prefixText: "",
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (val) {
                  final parsed = double.tryParse(val);
                  if (parsed != null && parsed <= _priceRange.end) {
                    setState(() {
                      _priceRange = RangeValues(parsed, _priceRange.end);
                    });
                  }
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text("-", style: theme.textTheme.titleMedium),
            ),
            Expanded(
              child: TextField(
                controller: _maxPriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "Max",
                  prefixText: "",
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (val) {
                  final parsed = double.tryParse(val);
                  if (parsed != null && parsed >= _priceRange.start) {
                    setState(() {
                      _priceRange = RangeValues(_priceRange.start, parsed);
                    });
                  }
                },
              ),
            ),
          ],
        ),
        SizedBox(height: AppSizes.p8),
        RangeSlider(
          values: _priceRange,
          min: widget.minAvailablePrice,
          max: widget.maxAvailablePrice > widget.minAvailablePrice
              ? widget.maxAvailablePrice
              : widget.minAvailablePrice + 1,
          divisions: 50,
          activeColor: theme.primaryColor,
          labels: RangeLabels(
            _priceRange.start.toInt().toString(),
            _priceRange.end.toInt().toString(),
          ),
          onChanged: (values) {
            setState(() {
              _priceRange = values;
              _minPriceController.text = values.start.toInt().toString();
              _maxPriceController.text = values.end.toInt().toString();
            });
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor: theme.scaffoldBackgroundColor,
              minimumSize: Size(double.infinity, 50),
            ),
            onPressed: () {
              setState(() {
                _selectedSort = 'default';
                _priceRange = RangeValues(widget.minAvailablePrice, widget.maxAvailablePrice);
                _minPriceController.text = widget.minAvailablePrice.toInt().toString();
                _maxPriceController.text = widget.maxAvailablePrice.toInt().toString();
              });
            },
            child: Text("filter.reset_filters".tr()),
          ),
        ),
        SizedBox(width: AppSizes.p12),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              minimumSize: Size(double.infinity, 50),
            ),
            onPressed: () {
              Navigator.pop(context, {
                'sortBy': _selectedSort,
                'minPrice': _priceRange.start,
                'maxPrice': _priceRange.end,
              });
            },
            child: Text(
              "filter.apply_filters".tr(),
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
