import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class OrdersHeader extends StatelessWidget implements PreferredSizeWidget {
  final bool isCurrentActive;
  final Function(bool) onTabChanged;
  final VoidCallback onBack;

  const OrdersHeader({
    super.key,
    required this.isCurrentActive,
    required this.onTabChanged,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTopBar(theme),
            _buildTabs(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: theme.scaffoldBackgroundColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(width: 12),
          Text('orders_title'.tr(), style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTabs(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
      child: Row(
        children: [
          _TabItem(
            title: 'orders_history'.tr(),
            isActive: !isCurrentActive,
            onTap: () => onTabChanged(false),
          ),
          const SizedBox(width: 10),
          _TabItem(
            title: 'current_orders'.tr(),
            isActive: isCurrentActive,
            onTap: () => onTabChanged(true),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(160);
}

class _TabItem extends StatelessWidget {
  final String title;
  final bool isActive;
  final VoidCallback onTap;

  const _TabItem(
      {required this.title, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? theme.primaryColor : theme.hintColor.withValues(alpha: 
                0.05),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(color: isActive ? Colors.white : theme.hintColor,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}