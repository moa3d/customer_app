import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/utils/app_sizes.dart';
import '../pages/order_tracking_screen.dart';

class OrderCardItem extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final VoidCallback? onRefresh;
  final VoidCallback? onCancel;
  final bool isLoading;

  const OrderCardItem({
    super.key,
    required this.orderData,
    this.onRefresh,
    this.onCancel,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final restaurantName = orderData['restaurantId']?['name'] ?? 'Restaurant';
    final totalPrice = orderData['totalPrice']?.toString() ?? '0';

    final String orderStatus = (orderData['orderStatus'] ?? 'pending')
        .toString();

    final driverData = orderData['driverId'];

    final bool canCancel = orderStatus == 'pending' ||
        orderStatus == 'not_confirmed';
    final List<dynamic> items = orderData['items'] ?? [];

    final DateTime orderedAt = DateTime.parse(
        orderData['createdAt'] ?? DateTime.now().toString());
    final String formattedTime = DateFormat('hh:mm a').format(orderedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.p16),
      padding: const EdgeInsets.all(AppSizes.p20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radius24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  restaurantName,
                  style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '$totalPrice ${'currency'.tr()}',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          AppSizes.h8,
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: theme.hintColor),
              AppSizes.w4,
              Text(formattedTime, style: TextStyle(color: theme.hintColor)),
              const Spacer(),
              _buildStatusBadge(orderStatus, theme),
            ],
          ),

          if (driverData != null) _buildDriverSection(theme, driverData),

          const Divider(height: 30),

          ...items.map((item) =>
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${item['quantity']}x ${item['name']}",
                      style: theme.textTheme.bodyMedium,
                    ),
                    _buildItemSubLine(theme, item),
                  ],
                ),
              )),
          AppSizes.h20,

          // v3.0 — أُزيل فرع زر "تأكيد التسليم" (كان محكوماً بحالة
          // delivered_by_driver التي لم تعد تصل، ويستدعي order:confirmDelivery
          // المحذوف). يبقى زر عرض الحالة الحالية فقط.
          _buildActionBtn(
            context,
            orderStatus.tr(),
            Icons.delivery_dining,
            theme.primaryColor,
            true,
                () {},
          ),

          if (canCancel) ...[
            AppSizes.h12,
            _buildActionBtn(
              context,
              isLoading ? 'cancelling'.tr() : 'cancel_order_btn'.tr(),
              isLoading ? null : Icons.close,
              Colors.redAccent,
              false,
              isLoading ? null : () => _showCancelDialog(context),
            ),
          ],

          AppSizes.h12,
          _buildActionBtn(
            context,
            'track_order'.tr(),
            Icons.map_outlined,
            theme.primaryColor,
            false,
                () =>
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => OrderTrackingScreen(orderData: orderData),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, ThemeData theme) {
    return Text(
      status.tr(),
      style: const TextStyle(
        color: Colors.blueGrey,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildItemSubLine(ThemeData theme, dynamic item) {
    final data = item is Map ? item : const <String, dynamic>{};
    final dynamic sizeRaw = data['size'];
    final String? sizeName =
        sizeRaw is Map ? sizeRaw['name']?.toString() : null;
    final List extras = data['extras'] is List ? data['extras'] : [];

    final String? sizeLabel = sizeName != null && sizeName.isNotEmpty
        ? 'units.size_$sizeName'.tr()
        : null;

    final String extrasLabel = extras.isNotEmpty
        ? extras
            .map((e) => e is Map ? e['name']?.toString() : '')
            .where((s) => s != null && s.isNotEmpty)
            .join(', ')
        : '';

    final List<String> parts = [
      ?sizeLabel,
      if (extrasLabel.isNotEmpty) extrasLabel,
    ];
    if (parts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        parts.join(' • '),
        style: TextStyle(color: theme.hintColor, fontSize: 11),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildDriverSection(ThemeData theme, dynamic driver) {
    return Column(
      children: [
        const Divider(height: 30),
        Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
              child: const Icon(Icons.person),
            ),
            AppSizes.w12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driver['name'] ?? 'Driver',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "${driver['vehicletype'] ?? ''}",
                    style: TextStyle(fontSize: 12, color: theme.hintColor),
                  ),
                ],
              ),
            ),
            const Icon(Icons.phone_in_talk, color: Colors.green),
          ],
        ),
      ],
    );
  }

  Widget _buildActionBtn(BuildContext context,
      String title,
      IconData? icon,
      Color color,
      bool isFilled,
      VoidCallback? onTap,) {
    final isLoadingBtn = onTap == null && icon == null;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.6 : 1.0,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isFilled ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.radius12),
            border: isFilled ? null : Border.all(color: color, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoadingBtn) ...[
                SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isFilled ? Colors.white : color,
                  ),
                ),
                AppSizes.w8,
              ] else if (icon != null) ...[
                Icon(icon, color: isFilled ? Colors.white : color, size: 20),
                AppSizes.w8,
              ],
              Text(
                title,
                style: TextStyle(
                  color: isFilled ? Colors.white : color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (c) =>
          AlertDialog(
            title: Text('cancel_order_confirm_title'.tr()),
            content: Text('cancel_order_confirm_msg'.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: Text('no'.tr()),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(c);
                  onCancel?.call();
                },
                child: Text(
                  'yes'.tr(),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }
}
