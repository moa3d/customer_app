import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/money.dart';
import '../../../restaurant/data/models/meal.dart';

/// بطاقة الوجبة — مشتركة بين الشريط الأفقي في الرئيسية (بعرض ثابت)
/// وشبكة «جميع الوجبات» (بلا عرض، تملأ خلية الشبكة).
class MealCard extends StatelessWidget {
  final Meal meal;

  /// عرض ثابت للاستخدام داخل قائمة أفقية. اتركه null داخل GridView
  /// لتملأ البطاقة عرض الخلية.
  final double? width;

  const MealCard({
    super.key,
    required this.meal,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // نسبة الخصم النشط — تُحسب مرة واحدة لأن الـ getter يمرّ على العروض
    final int? discountPercent = meal.activeDiscountPercent;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: meal.image,
                  fit: BoxFit.cover,
                  // صورة الشبكة تُصغَّر قبل فك الترميز لتفادي استنزاف ذاكرة
                  // الـ GPU في المحاكي — البطاقة بذاتها لا تتجاوز 160px عرضاً
                  // فنفك لغرض ~2x (Retina) ثم نخزّن الناتج في كاش القرص.
                  memCacheWidth: 320,
                  memCacheHeight: 240,
                  maxWidthDiskCache: 320,
                  maxHeightDiskCache: 240,
                  errorWidget: (context, url, error) => Container(
                    color: theme.dividerColor.withValues(alpha: 0.1),
                    child: Icon(Icons.fastfood,
                        color: theme.hintColor.withValues(alpha: 0.3)),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 10),
                        const SizedBox(width: 2),
                        Text(
                          meal.rating.toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // شارة الخصم — الزاوية المقابلة لشارة التقييم. Positioned
                // فيزيائي لا اتجاهي، فتبقى الشارتان متقابلتين في LTR وRTL معاً.
                if (discountPercent != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "-$discountPercent%",
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  meal.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                // السعر داخل FittedBox عمداً بدل ellipsis: السعر المقتطع
                // («1062…») رقم خاطئ يُقرأ غلطاً، لا نصّ ناقص. هكذا يبقى
                // الرقم كاملاً على سطر واحد ويصغر قليلاً في البطاقات الضيقة،
                // بلا overflow ولا التفاف يضغط الصورة.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: discountPercent == null
                      ? Text(
                          formatMoney(meal.displayPrice, meal.currency),
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatMoney(
                                  meal.displayPrice *
                                      (1 - discountPercent / 100),
                                  meal.currency),
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              meal.displayPrice.toInt().toString(),
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.hintColor,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
