import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/utils/app_sizes.dart';
import '../../data/models/meal.dart';


class FeaturedDishWidget extends StatelessWidget {
  final Meal? meal; // ✅ استقبال بيانات الوجبة
  final VoidCallback? onTap; // ✅ تنفيذ الانتقال عند الضغط

  const FeaturedDishWidget({super.key, this.meal, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (meal == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final bool isRtl = context.locale.languageCode == 'ar';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          vertical: AppSizes.p8,
          horizontal: AppSizes.p16,
        ),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // حاوية الصورة
              Container(
                width: 120,
                decoration: BoxDecoration(
                    image: DecorationImage(
                      // ✅ استخدام صورة الوجبة من الباك أند
                      image: meal!.image.startsWith('http')
                          ? CachedNetworkImageProvider(meal!.image)
                          : const AssetImage(
                          "assets/images/meals/burger.png") as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(12))
                ),
              ),
              // محتوى النص
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.p12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              meal!.name, // ✅ الاسم الحقيقي
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.p8,
                              vertical: AppSizes.p4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.primaryColor,
                              borderRadius: BorderRadius.circular(
                                  AppSizes.radius12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                    Icons.star, color: Colors.yellow, size: 14),
                                const SizedBox(width: AppSizes.p4),
                                Text(
                                  meal!.rating.toString(), // ✅ التقييم الحقيقي
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.p8),
                      Text(
                        meal!.description, // ✅ الوصف الحقيقي
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: isRtl ? TextAlign.right : TextAlign.left,
                      ),
                      const SizedBox(height: AppSizes.p16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: FittedBox(
                                    child: Text(
                                      "${meal!.displayPrice
                                          .toInt()} ${'restaurant.currency'
                                          .tr()}", // ✅ السعر الحقيقي
                                      style: TextStyle(
                                        color: theme.primaryColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSizes.p12),
                                Icon(Icons.access_time, color: theme.hintColor,
                                    size: 14),
                                const SizedBox(width: AppSizes.p4),
                                Text(
                                  "${meal!
                                      .time} ${'restaurant.delivery_time_short'
                                      .tr()}", // ✅ الوقت الحقيقي
                                  style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.hintColor),
                                ),
                              ],
                            ),
                          ),
                          _buildAddButton(theme),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.p8),
      decoration: BoxDecoration(
          color: theme.primaryColor,
          borderRadius: const BorderRadius.all(Radius.circular(12))
      ),
      child: const Icon(Icons.add, color: Colors.white, size: 20),
    );
  }
}