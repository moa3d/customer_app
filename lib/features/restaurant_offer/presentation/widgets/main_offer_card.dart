import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/utils/app_sizes.dart';


Widget buildMainOfferCard(ThemeData theme) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(vertical: AppSizes.p20),
    padding: const EdgeInsets.all(AppSizes.p20),
    decoration: BoxDecoration(
      // استخدام لون الثيم الأساسي (سيعمل مع الداكن والفاتح تلقائياً)
      color: theme.primaryColor,
      borderRadius: BorderRadius.circular(AppSizes.radius15),
    ),
    child: Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.p10),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(14)),
                color: Colors.white.withValues(alpha: 0.2),
              ),
              child: const Icon(
                Icons.local_offer_outlined,
                color: Colors.white,
                size: AppSizes.iconSize24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "offers.rest_1_title".tr(), // مفتاح الترجمة للعنوان
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSizes.h4,
                  Text(
                    "offers.rest_1_subtitle".tr(), // مفتاح الترجمة للوصف
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        AppSizes.h4,
        const Divider(color: Colors.white24),
        AppSizes.h4,
        Row(
          children: [
            const Icon(Icons.access_time, color: Colors.white70, size: AppSizes.iconSize16),
            AppSizes.w4,
            Text(
              "${"offers.valid_until".tr()} 31-01-2025", // نص التاريخ المترجم
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ],
    ),
  );
}