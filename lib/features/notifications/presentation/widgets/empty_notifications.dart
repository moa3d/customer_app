import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/utils/app_sizes.dart';

class EmptyNotifications extends StatelessWidget {
  /// When true there are notifications but none left unread in the current
  /// filter. Otherwise there are no notifications at all.
  final bool isAllRead;

  const EmptyNotifications({super.key, this.isAllRead = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.p16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.p30),
              decoration: BoxDecoration(
                  color: theme.cardColor.withValues(alpha: 0.5),
                  shape: BoxShape.circle),
              child: Icon(
                isAllRead
                    ? Icons.mark_email_read_outlined
                    : Icons.notifications_none_outlined,
                size: 80,
                color: theme.hintColor.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: AppSizes.p24),
            Text(
              isAllRead
                  ? 'notifications.no_unread'.tr()
                  : 'notifications.no_notifications'.tr(),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.p8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
              child: Text('notifications.read_all_message'.tr(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.hintColor)),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}