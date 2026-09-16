import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class RiceComponentWidget extends StatelessWidget {
  final String name;

  const RiceComponentWidget({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const Color greenAccent = Color(0xFF00D254);

    return Container(
      constraints: const BoxConstraints(minHeight: 70),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F28) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: greenAccent.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: greenAccent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  "offers.included".tr(),
                  style: TextStyle(
                    color: theme.hintColor.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // تم حذف قسم الصورة نهائياً كما طلبت
        ],
      ),
    );
  }
}