import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class OffersCountBanner extends StatelessWidget {
  final int count;

  const OffersCountBanner({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      decoration: BoxDecoration(
        // لون خلفية فاتح جداً مائل للوردي كما في الصورة
        color: theme.primaryColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.primaryColor, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start, // العناصر تبدأ من اليمين
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.6), // لون المربع البرتقالي الفاتح
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.percent,
              color: Color(0xFFFF5722), // لون الأيقونة البرتقالي الغامق
              size: 28,
            ),
          ),
          const SizedBox(width: 15),
          // النصوص (العدد والوصف)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  // التصحيح 1: استخدام plural بدلاً من tr للتعامل مع قواعد الجمع
                  // التصحيح 2: تغيير اللون إلى البرتقالي أو الأسود ليكون مرئياً
                  'offers_available'.plural(count),
                  style: TextStyle(
                    color: theme
                        .primaryColor, // أو Color(0xFFFF5722) ليكون متناسقاً
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'offers_catch_opportunity'.tr(),
                  style: TextStyle(
                    color: Colors.grey[700], // لون أغمق قليلاً للوضوح
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // مربع أيقونة النسبة المئوية (%)
        ],
      ),
    );
  }
}
