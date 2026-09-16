import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class TipCard extends StatelessWidget {
  final String? text;

  const TipCard({
    super.key,
    this.text,
  });

  @override
  Widget build(BuildContext context) {
    // التحقق مما إذا كان الوضع داكناً لتحسين رؤية الألوان
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        // لون الخلفية مع مراعاة الشفافية
        color: const Color(0xFF2B7FFF).withValues(alpha: isDark ? 0.2 : 0.4),
        // حدود منحنية كبيرة
        borderRadius: BorderRadius.circular(20),
        // إطار خفيف بلون سماوي أغمق قليلاً
        border: Border.all(
          color: const Color(0xFF2B7FFF),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              // إذا لم يتم تمرير نص، نستخدم النص المترجم الافتراضي
              text ?? "tips.customize_meal".tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                // تفتيح لون النص قليلاً في الوضع الداكن لضمان المقروئية
                color: isDark ? const Color(0xFF8EBBFF) : const Color(0xFF2B7FFF),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}