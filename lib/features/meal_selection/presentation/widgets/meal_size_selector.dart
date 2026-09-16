import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/utils/app_sizes.dart';

class MealSizeSelector extends StatelessWidget {
  final List<dynamic> sizes;
  final Map<String, dynamic>? selectedSizeData;
  final Function(Map<String, dynamic>) onSizeSelected;

  const MealSizeSelector({
    super.key,
    required this.sizes,
    required this.selectedSizeData,
    required this.onSizeSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (sizes.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.p20),
          child: Text(
            "order.select_size".tr(),
            style: TextStyle(
              color: theme.textTheme.titleMedium?.color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        AppSizes.h16,
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.p12),
          child: Row(
            children: sizes.map((size) {
              // ✅ مطابقة منطق التحديد من الهيكل القديم باستخدام _id
              bool isSelect = selectedSizeData?['_id'] == size['_id'];

              return Expanded(
                child: GestureDetector(
                  onTap: () => onSizeSelected(size),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: EdgeInsets.symmetric(vertical: AppSizes.p16),
                    decoration: BoxDecoration(
                      color: isSelect
                          ? theme.primaryColor.withValues(alpha: 0.1)
                          : theme.cardColor,
                      borderRadius: BorderRadius.circular(AppSizes.radius15),
                      border: Border.all(
                        color: isSelect
                            ? theme.primaryColor
                            : theme.dividerColor.withValues(alpha: 0.2),
                        width: isSelect ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "units.size_${size['name']}".tr(),
                          style: TextStyle(
                            fontWeight: isSelect ? FontWeight.bold : FontWeight
                                .normal,
                          ),
                        ),
                        AppSizes.h8,
                        Text(
                          "${(size['price'] as num).toInt()} ${"order.currency"
                              .tr()}",
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}