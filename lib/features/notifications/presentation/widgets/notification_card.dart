import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/utils/app_sizes.dart';
import '../../data/models/notification_model.dart';

class NotificationCard extends StatelessWidget {
  final AppNotificationModel item;
  final bool isRtl;
  final VoidCallback onDelete;
  final VoidCallback? onMarkAsRead;

  /// إجراء زر «تتبع». كان الزر `Container` عارياً بلا أي معالج ضغط — يبدو
  /// قابلاً للضغط ولا يستجيب — لأن البطاقة لم تكن تقبل إجراءً أصلاً.
  final VoidCallback? onAction;

  const NotificationCard({
    super.key,
    required this.item,
    required this.isRtl,
    required this.onDelete,
    this.onMarkAsRead,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: Key(item.id),
      direction: isRtl ? DismissDirection.startToEnd : DismissDirection
          .endToStart,
      onDismissed: (_) => onDelete(),
      background: _buildDeleteBg(),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.p12),
        padding: const EdgeInsets.all(AppSizes.p12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          border: item.isUnread ? Border.all(
              color: Colors.deepOrange.withValues(alpha: 0.5), width: 1.5) : null,
        ),
        child: Column(
          children: [
            _buildMainRow(theme),
            _buildFooterRow(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteBg() {
    return Container(
      alignment: isRtl ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: Colors.redAccent, borderRadius: BorderRadius.circular(16)),
      child: const Icon(Icons.delete, color: Colors.white),
    );
  }

  Widget _buildMainRow(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSizes.p12),
          decoration: BoxDecoration(
              color: item.iconBgColor, borderRadius: BorderRadius.circular(16)),
          child: Icon(item.icon, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: isRtl
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            children: [
              Text(item.title, style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(item.body, style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor, height: 1.4)),
              const SizedBox(height: 12),
            ],
          ),
        ),
        if (item.isUnread) _buildDot(),
      ],
    );
  }

  Widget _buildDot() {
    return Container(width: 10,
        height: 10,
        decoration: const BoxDecoration(
            color: Colors.deepOrange, shape: BoxShape.circle));
  }

  Widget _buildFooterRow(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(item.time, style: theme.textTheme.labelSmall?.copyWith(
            color: theme.hintColor.withValues(alpha: 0.7))),
        Row(
          children: [
            if (item.hasAction && onAction != null) _buildActionBtn(theme),
            IconButton(icon: Icon(
                Icons.delete_outline, color: theme.hintColor.withValues(alpha: 0.5),
                size: 22), onPressed: onDelete),
            if (item.isUnread) IconButton(icon: Icon(
                Icons.check, color: theme.hintColor.withValues(alpha: 0.5), size: 22),
                onPressed: onMarkAsRead),
          ],
        ),
      ],
    );
  }

  Widget _buildActionBtn(ThemeData theme) {
    final radius = BorderRadius.circular(8);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: theme.primaryColor,
        borderRadius: radius,
        child: InkWell(
          onTap: onAction,
          borderRadius: radius,
          child: SizedBox(
            height: 27,
            width: 44,
            child: Center(
              child: Text('notifications.${item.actionLabel}'.tr(),
                  style: const TextStyle(fontSize: 13, color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }
}
// هاد الكرت مشان الإشعارات تطلع بشكل حلو ومنظم.. يا رب ما يمل المستحدم منه وقت التبيطق