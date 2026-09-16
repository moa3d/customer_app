import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../../core/utils/app_sizes.dart';

class DriverInfoCard extends StatelessWidget {
  final Map<String, dynamic>? driverInfo;

  const DriverInfoCard({super.key, this.driverInfo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSizes.p12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppSizes.radius16),
      ),
      child: Row(
        children: [
          _buildAvatar(theme),
          AppSizes.w12,
          _buildInfo(theme),
          _buildIcon(Icons.chat_bubble_outline, Colors.blue),
          AppSizes.w12,
          _buildIcon(Icons.phone_in_talk_outlined, Colors.green),
        ],
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme) {
    return Container(
      width: 50, height: 50,
      decoration: BoxDecoration(
          color: theme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12)
      ),
      child: const Center(
          child: Icon(Icons.delivery_dining, size: 28, color: Colors.orange)),
    );
  }

  Widget _buildInfo(ThemeData theme) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              driverInfo?['name'] ?? 'searching_driver'.tr(),
              style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis
          ),
          Text(driverInfo?['vehicletype'] ?? 'delivery_driver'.tr(),
              style: TextStyle(color: theme.hintColor, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radius14),
          color: color.withValues(alpha: 0.15)),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
// هاد القسم مشان الزبون يعرف مين جاي لعندو.. يا رب يكون السواق سريع ومو مستعجل