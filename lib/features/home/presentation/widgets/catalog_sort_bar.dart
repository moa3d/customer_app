import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../data/models/catalog_sort.dart';
import 'home_filter.dart';

/// شريط الترتيب المشترك بين الرئيسية وشاشتَي «جميع المطاعم» و«جميع الوجبات».
///
/// الشارة أسفله تخصّ شاشتَي «عرض المزيد» وحدهما: هناك لا وجود لـ
/// `MainCategoryBar`، فالفلتر يصل موروثاً عبر `CatalogArgs` والشارة هي الوسيلة
/// الوحيدة لرؤيته وإزالته. أما الرئيسية فلا تمرّرها عمداً — القسم مضيء أصلاً في
/// `MainCategoryBar` وإلغاؤه بشريحة «الكل»، فإظهارها هناك تكرارٌ يقفز بالتخطيط
/// عند كل نقرة على قسم.
class CatalogSortBar extends StatelessWidget {
  final CatalogSort selected;
  final ValueChanged<CatalogSort> onChanged;

  /// عنوان الفلتر الموروث، أو null إن لم يكن هناك فلتر — ومعه
  /// [onClearFilter] شرطٌ لظهور الشارة.
  final String? activeFilterLabel;
  final VoidCallback? onClearFilter;

  /// يُعطَّل الشريط أثناء البحث: `GET /api/user/search` يتجاهل `sort` تماماً،
  /// فإبقاء الشرائح قابلة للنقر يوهم المستخدم بأثر لا يحدث.
  final bool enabled;

  const CatalogSortBar({
    super.key,
    required this.selected,
    required this.onChanged,
    this.onClearFilter,
    this.activeFilterLabel,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
          child: Text("home_sort_by".tr(),
              style: TextStyle(color: theme.hintColor, fontSize: 14)),
        ),
        SizedBox(
          height: 100,
          child: Opacity(
            opacity: enabled ? 1 : 0.4,
            child: IgnorePointer(
              ignoring: !enabled,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final sort in CatalogSort.values)
                      HomeFilter(
                        title: sort.labelKey.tr(),
                        icon: sort.icon,
                        isSelected: selected == sort,
                        onTap: () => onChanged(sort),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (activeFilterLabel != null && onClearFilter != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Chip(
                label: Text("filter_active_label"
                    .tr()
                    .replaceFirst('{}', activeFilterLabel!)),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: onClearFilter,
                deleteButtonTooltipMessage: "clear_filter".tr(),
                backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                side: BorderSide(
                    color: theme.primaryColor.withValues(alpha: 0.4)),
              ),
            ),
          ),
      ],
    );
  }
}
