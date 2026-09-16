import 'package:flutter/material.dart';

class CartToggleButton extends StatelessWidget {
  final String title;
  final bool isActive;
  final VoidCallback onTap;

  const CartToggleButton({
    super.key,
    required this.title,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // هدول الألوان هنن نفسن اللي بالتبيطق مشان التناسق
    const Color primaryOrange = Color(0xFFFF5630);
    const Color secondaryText = Color(0xFFAAB2BD);
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        // هون مارجن خفيف مشان الزر ما يلزق بالحوافف
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isActive ? primaryOrange : theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : secondaryText,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
