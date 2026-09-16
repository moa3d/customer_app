import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/utils/app_sizes.dart';

// 1. هاد الكارت منفصل مشان "تبيطق" الـ "سرعهه" يكون ممتاز وما يعلق "المووبيل". (1, 2, 3)
class OfferrMealCard extends StatelessWidget {
  final String title, details, oldPrice, newPrice,
      saveingAmount;
  final String? discountTag;
  final String? imagePath;
  final VoidCallback onTap;

  const OfferrMealCard({
    super.key,
    required this.title,
    required this.details,
    required this.oldPrice,
    required this.newPrice,
    required this.saveingAmount,
    this.discountTag,
    this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 2. هون الـ "كودد" بيتعامل مع الـ "صورر" بطريقة بتوفر مساحة في الـ "زاكره". (4, 5, 6)
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.p16),
      padding: const EdgeInsets.all(AppSizes.p12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radius15),
      ),
      child: Row(
        children: [
          _buildImage(theme),
          const SizedBox(width: 12),
          _buildInfo(theme),
          _buildArrowButton(theme),
        ],
      ),
    );
  }

  Widget _buildImage(ThemeData theme) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radius12),
          child: Container(
            width: 90, height: 90,
            color: theme.brightness == Brightness.dark
                ? Colors.grey[800]
                : Colors.grey[300],
            child: imagePath != null && imagePath!.isNotEmpty
                ? Image.network(imagePath!, fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => const Image(
                        image: AssetImage("assets/images/meals/burger.png"),
                        fit: BoxFit.cover))
                : const Image(
                    image: AssetImage("assets/images/meals/burger.png"),
                    fit: BoxFit.cover),
          ),
        ),
        if (discountTag != null && discountTag!.isNotEmpty)
          Positioned(
            top: 5, right: 5,
            child: Container(
              padding: const EdgeInsets.all(AppSizes.p4),
              decoration: BoxDecoration(color: theme.primaryColor,
                  borderRadius: BorderRadius.circular(AppSizes.radius8)),
              child: Text(discountTag!,
                  style: const TextStyle(color: Colors.white, fontSize: 10)),
            ),
          ),
      ],
    );
  }

  Widget _buildInfo(ThemeData theme) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              maxLines: 1),
          AppSizes.h4,
          Text(details, style: TextStyle(
              color: theme.textTheme.bodyMedium?.color, fontSize: 11)),
          AppSizes.h12,
          _buildPrices(theme),
        ],
      ),
    );
  }

  Widget _buildPrices(ThemeData theme) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        Text(newPrice, style: TextStyle(color: theme.primaryColor,
            fontSize: 17,
            fontWeight: FontWeight.bold)),
        Text(oldPrice, style: TextStyle(color: theme.hintColor,
            fontSize: 12,
            decoration: TextDecoration.lineThrough)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: const Color(0xFF139634),
              borderRadius: BorderRadius.circular(AppSizes.radius8)),
          child: Text("${"offers.save".tr()} $saveingAmount",
              style: const TextStyle(color: Colors.white, fontSize: 10)),
        ),
      ],
    );
  }

  Widget _buildArrowButton(ThemeData theme) {
    return Material(
      color: theme.primaryColor.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(height: 35,
            width: 35,
            child: Icon(
                Icons.arrow_forward, color: theme.primaryColor, size: 18)),
      ),
    );
  }
}