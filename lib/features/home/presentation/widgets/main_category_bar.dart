import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../data/models/main_category.dart';

/// شريط الأقسام العامة أعلى قوائم الرئيسية.
///
/// حلّ محلّ شريحتَي «برغر» و«بيتزا» اللتين كانتا تفلتران بمطابقة نصية مكتوبة
/// يدوياً على اسم الوجبة، فتُسقطان كل صنف لا يحمل الكلمة حرفياً. الأقسام هنا
/// تأتي من الباك ويُرسل معرّفها كـ `mainCategory`.
class MainCategoryBar extends StatelessWidget {
  final List<MainCategory> categories;

  /// معرّف القسم المختار — null يعني شريحة «الكل».
  final String? selectedId;

  final ValueChanged<String?> onSelected;

  /// يُعطَّل الشريط أثناء البحث لأن `/search` لا يدعم الفلترة بالقسم.
  final bool enabled;

  const MainCategoryBar({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: IgnorePointer(
        ignoring: !enabled,
        child: SizedBox(
          height: 46,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: categories.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return CategoryChip(
                  label: "main_category_all".tr(),
                  isSelected: selectedId == null,
                  onTap: () => onSelected(null),
                );
              }
              final category = categories[index - 1];
              return CategoryChip(
                label: category.name,
                imageUrl: category.imageUrl,
                isSelected: selectedId == category.id,
                onTap: () => onSelected(category.id),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// شريحة واحدة في صف الأقسام. عامة لأن الرئيسية تستعملها أيضاً لشريحة
/// «العروض» المثبَّتة قبل الأقسام.
class CategoryChip extends StatelessWidget {
  final String label;
  final String? imageUrl;

  /// أيقونة بديلة عن الصورة — تستعملها شريحة «العروض».
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.imageUrl,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsetsDirectional.only(
          start: imageUrl != null ? 4 : 14,
          end: 14,
          top: 4,
          bottom: 4,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor
              : theme.hintColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 16,
                  color: isSelected
                      ? Colors.white
                      : theme.textTheme.bodyMedium?.color),
              const SizedBox(width: 6),
            ],
            // الصورة اختيارية — `image.url` افتراضيه null في الباك
            if (imageUrl != null) ...[
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: imageUrl!,
                  width: 30,
                  height: 30,
                  fit: BoxFit.cover,
                  memCacheWidth: 60,
                  memCacheHeight: 60,
                  maxWidthDiskCache: 60,
                  maxHeightDiskCache: 60,
                  errorWidget: (_, _, _) => Container(
                    width: 30,
                    height: 30,
                    color: theme.cardColor,
                    child: Icon(Icons.restaurant_menu,
                        size: 16, color: theme.hintColor),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : theme.textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
