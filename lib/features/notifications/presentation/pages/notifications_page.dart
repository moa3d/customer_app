import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/services/order_notifications_service.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/utils/app_sizes.dart';
import '../../data/models/notification_model.dart';
import '../widgets/empty_notifications.dart';
import '../widgets/notification_card.dart';
import '../widgets/notifications_filter_tabs.dart';

class NotificationsPage extends StatefulWidget {
  final Function(int) movePage;

  const NotificationsPage({super.key, required this.movePage});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _showOnlyUnread = false;

  final _service = OrderNotificationsService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isRtl = context.locale.languageCode == 'ar';

    return ValueListenableBuilder<List<OrderNotificationRecord>>(
      valueListenable: _service.notifications,
      builder: (context, records, _) {
        final all = records.map(_toViewModel).toList();
        final filtered =
            _showOnlyUnread ? all.where((n) => n.isUnread).toList() : all;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: _buildAppBar(theme, all),
          body: Column(
            children: [
              const SizedBox(height: AppSizes.p10),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: filtered.isEmpty
                      ? EmptyNotifications(isAllRead: all.isNotEmpty)
                      : _buildNotificationsList(filtered, isRtl),
                ),
              ),
              if (all.isNotEmpty) _buildClearAllBtn(theme),
              const SizedBox(height: 85),
            ],
          ),
        );
      },
    );
  }

  AppNotificationModel _toViewModel(OrderNotificationRecord r) {
    final style = _styleFor(r.status);
    final shortId =
        r.orderId.length > 6 ? r.orderId.substring(r.orderId.length - 6) : r.orderId;

    return AppNotificationModel(
      id: r.id,
      orderId: r.orderId,
      title: 'notifications.status.${r.status}'.tr(),
      body: 'notifications.order_ref'.tr(args: [shortId]),
      time: _relativeTime(r.createdAt),
      icon: style.$1,
      iconBgColor: style.$2,
      isUnread: r.isUnread,
      hasAction: style.$3,
      actionLabel: style.$3 ? 'track' : null,
    );
  }

  (IconData, Color, bool) _styleFor(String status) {
    switch (status) {
      case 'pending':
        return (Icons.receipt_long, const Color(0xFF2196F3), false);
      case 'accepted':
        return (Icons.check_circle, const Color(0xFF00D254), false);
      case 'preparing':
        return (Icons.restaurant, const Color(0xFFFF9800), false);
      case 'ready':
        return (Icons.inventory_2, const Color(0xFF009688), false);
      case 'picked_up':
        return (Icons.delivery_dining, const Color(0xFF3F51B5), true);
      case 'on_the_way':
        return (Icons.directions_bike, const Color(0xFF00D254), true);
      case 'delivered':
        return (Icons.done_all, const Color(0xFF00D254), false);
      case 'cancelled':
        return (Icons.cancel, const Color(0xFFE53935), false);
      default:
        return (Icons.notifications, const Color(0xFF757575), false);
    }
  }

  String _relativeTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'notifications.time.now'.tr();
    if (diff.inHours < 1) {
      return 'notifications.time.minutes'.tr(args: ['${diff.inMinutes}']);
    }
    if (diff.inDays < 1) {
      return 'notifications.time.hours'.tr(args: ['${diff.inHours}']);
    }
    return 'notifications.time.days'.tr(args: ['${diff.inDays}']);
  }

  PreferredSizeWidget _buildAppBar(
      ThemeData theme, List<AppNotificationModel> all) {
    final unread = all.where((n) => n.isUnread).length;

    return AppBar(
      backgroundColor: theme.cardColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildBackAndTitle(theme, unread),
          _buildReadAllBtn(theme),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size(double.infinity, 80),
        child: NotificationsFilterTabs(
          totalCount: all.length,
          unreadCount: unread,
          showOnlyUnread: _showOnlyUnread,
          onChanged: (val) => setState(() => _showOnlyUnread = val),
        ),
      ),
    );
  }

  Widget _buildBackAndTitle(ThemeData theme, int unread) {
    return Row(
      children: [
        IconButton(
          onPressed: () => widget.movePage(0),
          icon: const Icon(Icons.arrow_back),
          style: IconButton.styleFrom(
            backgroundColor: theme.scaffoldBackgroundColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(width: AppSizes.p12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('notifications.title'.tr(),
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text('notifications.new_count'.tr(args: ['$unread']),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.hintColor)),
          ],
        ),
      ],
    );
  }

  Widget _buildReadAllBtn(ThemeData theme) {
    return TextButton(
      onPressed: _service.markAllRead,
      child: Text('notifications.read_all'.tr(),
          style: TextStyle(
              color: theme.primaryColor, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildNotificationsList(List<AppNotificationModel> list, bool isRtl) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
      itemCount: list.length,
      itemBuilder: (context, index) => NotificationCard(
        item: list[index],
        isRtl: isRtl,
        onDelete: () => _service.remove(list[index].id),
        onMarkAsRead: () => _service.markRead(list[index].id),
        // نفس المسار الذي يسلكه الضغط على إشعار Push: الإشعار يحمل المعرّف
        // وحده، فتُجلب بيانات الطلب ثم تُفتح شاشة التتبّع.
        onAction: () => _openTracking(list[index]),
      ),
    );
  }

  /// فتح تتبّع الطلب من زر «تتبع». يُعلَّم الإشعار مقروءاً لأن المستخدم تفاعل
  /// معه فعلاً.
  void _openTracking(AppNotificationModel item) {
    _service.markRead(item.id);
    PushNotificationService.openOrderTracking(item.orderId);
  }

  Widget _buildClearAllBtn(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
      child: OutlinedButton.icon(
        onPressed: _service.clear,
        icon: Icon(Icons.delete_outline, color: theme.hintColor),
        label: Text('notifications.clear_all'.tr(),
            style: TextStyle(color: theme.hintColor)),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
