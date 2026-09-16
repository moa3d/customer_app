import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class OfferTermsCard extends StatelessWidget {
  const OfferTermsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // قائمة الشروط باستخدام مفاتيح الترجمة
    final List<String> terms = [
      "terms.stock_limit".tr(),
      "terms.no_combine".tr(),
      "terms.min_order".tr(),
      "terms.available_for".tr(),
      "terms.max_discount".tr(),
    ];

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                "terms.title".tr(), // الشروط والأحكام
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: terms.map((term) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // استخدمنا Expanded لضمان عدم حدوث Overflow عند ترجمة النصوص للغات طويلة
                  Expanded(
                    child: Text(
                      term,
                      style: const TextStyle(color: Color(0xff94A3B8), fontSize: 14),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}