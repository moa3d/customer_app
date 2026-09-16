import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../../core/utils/app_sizes.dart';

class OrderStatusCard extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final String status;
  final int minutes;

  const OrderStatusCard(
      {super.key, required this.orderData, required this.status, required this.minutes});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final restaurant = orderData['restaurantId']?['name'] ?? 'Restaurant';
    final price = orderData['totalPrice'] ?? '0';

    return Container(
      padding: const EdgeInsets.all(AppSizes.p20),
      decoration: BoxDecoration(color: theme.cardColor,
          borderRadius: BorderRadius.circular(AppSizes.radius24)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(restaurant, style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold)),
              Text('$price ${'currency'.tr()}', style: TextStyle(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
            ],
          ),
          AppSizes.h16,
          // v3.0 — بطاقة التتبّع تُعرض دائماً؛ حالة delivered_by_driver
          // التي كانت تُبدّل لواجهة تأكيد الاستلام لم تعد تصل من الباك.
          _buildTrackingUI(theme),
        ],
      ),
    );
  }

  Widget _buildTrackingUI(ThemeData theme) {
    return Row(
      children: [
        CircleAvatar(radius: 20,
            backgroundColor: theme.primaryColor,
            child: const Icon(Icons.delivery_dining, color: Colors.white)),
        AppSizes.w8,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(status.tr(), style: const TextStyle(fontSize: 13)),
              Text('${'estimated_time'.tr()}: $minutes ${'minutes'.tr()}',
                  style: TextStyle(color: theme.hintColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  // v3.0 — حُذفت _buildConfirmUI: كانت تعرض زر "تأكيد الاستلام" وتستدعي
  // confirmDeliveryWithFeedback (حدث order:confirmDelivery المحذوف). لم يعد
  // للزبون أي إجراء تأكيد بعد إلغاء حالة delivered_by_driver.
}
