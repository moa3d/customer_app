import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/utils/app_sizes.dart';


class SizeSelectorCards extends StatelessWidget {
  final double basePrice;
  final int selectedIndex;
  final Function(int) onSizeSelected;

  const SizeSelectorCards({
    super.key,
    required this.basePrice,
    required this.selectedIndex,
    required this.onSizeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
          child: Text("order.select_size".tr(),
              style: TextStyle(color: theme.textTheme.titleMedium?.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ),
        AppSizes.h16,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p12),
          child: Row(
            children: [
              _buildCard(context, 0, "order.small".tr(), "0", basePrice),
              AppSizes.w8,
              _buildCard(
                  context, 1, "order.medium".tr(), "5000", basePrice + 5000),
              AppSizes.w8,
              _buildCard(
                  context, 2, "order.large".tr(), "10000", basePrice + 10000),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context, int index, String label,
      String increment, double price) {
    final theme = Theme.of(context);
    bool isSelect = selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSizeSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: AppSizes.p16),
          decoration: BoxDecoration(
            color: isSelect ? theme.primaryColor.withValues(alpha: 0.1) : theme
                .cardColor,
            borderRadius: BorderRadius.circular(AppSizes.radius15),
            border: Border.all(
                color: isSelect ? theme.primaryColor : theme.dividerColor
                    .withValues(alpha: 0.2), width: isSelect ? 2 : 1),
          ),
          child: Column(
            children: [
              Text(label, style: TextStyle(
                  fontWeight: isSelect ? FontWeight.bold : FontWeight.normal)),
              AppSizes.h8,
              Text(index == 0 ? "order.basic".tr() : "+$increment",
                  style: TextStyle(color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
              Text("${price.toInt()} ${"order.currency".tr()}",
                  style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}