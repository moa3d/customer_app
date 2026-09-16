import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/utils/app_sizes.dart';

class NotificationsFilterTabs extends StatelessWidget {
  final int totalCount;
  final int unreadCount;
  final bool showOnlyUnread;
  final Function(bool) onChanged;

  const NotificationsFilterTabs({
    super.key,
    required this.totalCount,
    required this.unreadCount,
    required this.showOnlyUnread,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p16, vertical: AppSizes.p12),
      child: Row(
        children: [
          Expanded(child: _buildBtn(
              theme, "${'notifications.all'.tr()} ($totalCount)",
              !showOnlyUnread, () => onChanged(false))),
          const SizedBox(width: AppSizes.p12),
          Expanded(child: _buildBtn(
              theme, "${'notifications.unread'.tr()} ($unreadCount)",
              showOnlyUnread, () => onChanged(true))),
        ].reversed.toList(),
      ),
    );
  }

  Widget _buildBtn(ThemeData theme, String label, bool isActive,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: AppSizes.p12),
        decoration: BoxDecoration(
          color: isActive ? theme.primaryColor : theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(AppSizes.radius12),
        ),
        child: Center(child: Text(label, style: TextStyle(
            color: isActive ? Colors.white : theme.hintColor,
            fontWeight: FontWeight.bold))),
      ),
    );
  }
}