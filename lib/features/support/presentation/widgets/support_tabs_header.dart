import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class SupportTabsHeader extends StatelessWidget implements PreferredSizeWidget {
  final TabController tabController;
  final int selectedIndex;
  final VoidCallback onBack;
  final Function(int) onTabChanged;

  const SupportTabsHeader({
    super.key,
    required this.tabController,
    required this.selectedIndex,
    required this.onBack,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.cardColor,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildBackButton(theme),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        "support_title".tr(),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 45),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  _TabItem(
                    index: 0,
                    icon: Icons.airplane_ticket_outlined,
                    label: "tickets_tab".tr(),
                    isSelected: selectedIndex == 0,
                    onTap: () => onTabChanged(0),
                  ),
                  const SizedBox(width: 8),
                  _TabItem(
                    index: 1,
                    icon: Icons.help_outline,
                    label: "faq_tab".tr(),
                    isSelected: selectedIndex == 1,
                    onTap: () => onTabChanged(1),
                  ),
                  const SizedBox(width: 8),
                  _TabItem(
                    index: 2,
                    icon: Icons.chat_bubble_outline,
                    label: "chat_tab".tr(),
                    isSelected: selectedIndex == 2,
                    onTap: () => onTabChanged(2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(ThemeData theme) {
    return InkWell(
      onTap: onBack,
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: theme.highlightColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: const Icon(Icons.arrow_back, color: Colors.white),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(140);
}

class _TabItem extends StatelessWidget {
  final int index;
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabItem({
    required this.index,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.deepOrange : theme
                .scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Colors.deepOrange : Colors.white10,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : theme.textTheme.bodyLarge
                    ?.color,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : theme.textTheme.bodyLarge
                      ?.color,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}