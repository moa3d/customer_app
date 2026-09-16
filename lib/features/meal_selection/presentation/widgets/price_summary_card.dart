import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class PriceSummaryCard extends StatelessWidget {
  final double basePrice;
  final double extrasTotal;
  final int quantity;
  final String currency;
  // السعر الأصلي قبل الحسم — إن وُجد يعرضه بجانب المخفّض (المفترض أن
  // basePrice هو السعر بعد الحسم).
  final double? originalPrice;

  const PriceSummaryCard({
    super.key,
    required this.basePrice,
    required this.extrasTotal,
    required this.quantity,
    required this.currency,
    this.originalPrice,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // حساب المبالغ
    double subtotal = basePrice * quantity;
    double totalExtras = extrasTotal * quantity;
    double finalTotal = subtotal + totalExtras;

    final bool hasDiscount =
        originalPrice != null && originalPrice! * quantity > subtotal;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F28) : theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          // 1. السعر الأساسي
          _buildPriceRow(
            label: "offers.price".tr(),
            valueWidget: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                if (hasDiscount)
                  Text(
                    "${(originalPrice! * quantity).toInt()} $currency",
                    style: TextStyle(
                      color: theme.hintColor,
                      fontSize: 14,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: theme.hintColor,
                    ),
                  ),
                Text(
                  "${subtotal.toInt()} $currency",
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            theme: theme,
          ),
          const SizedBox(height: 12),

          // 2. سعر الإضافات
          _buildPriceRow(
            label: "offers.additions".tr(),
            value: "${totalExtras.toInt()} $currency",
            theme: theme,
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),

          // 3. الإجمالي النهائي (باللون البرتقالي)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${finalTotal.toInt()} $currency",
                style: const TextStyle(
                  color: Color(0xFFFF5722),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "offers.final_total".tr(),
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
      {required String label,
      String? value,
      Widget? valueWidget,
      required ThemeData theme}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        valueWidget ??
            Text(
              value ?? "",
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
        Text(
          label,
          style: TextStyle(
            color: theme.hintColor.withValues(alpha: 0.7),
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}