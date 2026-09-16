import 'package:flutter/material.dart';

class CartSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  /// السعر الأصلي المشطوب — يُمرَّر عند وجود عرض (مثل التوصيل المجاني).
  /// عند تمريره يحلّ محل [value] في الجهة اليمنى.
  final String? strikethroughValue;

  /// نص الشارة المرافقة للسعر المشطوب، مثل "توصيل مجاني".
  final String? badge;

  const CartSummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.isTotal = false,
    this.strikethroughValue,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    // الألوان والستايلات هون ثابتة متل ما كانت مشان ما يتغير التصميم
    const Color primaryOrange = Color(0xFFFF5630);
    const Color secondaryText = Color(0xFFAAB2BD);
    const Color freeGreen = Color(0xFF2E7D32);

    final TextStyle baseStyle = TextStyle(
      color: isTotal ? primaryOrange : secondaryText,
      fontSize: isTotal ? 18 : 15,
      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: baseStyle),
          if (strikethroughValue != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  strikethroughValue!,
                  style: baseStyle.copyWith(
                    decoration: TextDecoration.lineThrough,
                    decorationColor: secondaryText,
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    badge!,
                    style: baseStyle.copyWith(
                      color: freeGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            )
          else
            Text(value, style: baseStyle),
        ],
      ),
    );
  }
}
