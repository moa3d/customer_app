import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class MealQuantityStep extends StatefulWidget {
  final double basePrice;
  final double? originalPrice;
  final String selectedSize;
  final double sizeIncrement;
  final Function(int) onQuantityChanged;
  final VoidCallback onCustomizeTap;
  final VoidCallback? onChangeSize;

  const MealQuantityStep({
    super.key,
    required this.basePrice,
    this.originalPrice,
    required this.selectedSize,
    required this.sizeIncrement,
    required this.onQuantityChanged,
    required this.onCustomizeTap,
    this.onChangeSize,
  });

  @override
  State<MealQuantityStep> createState() => _MealQuantityStepState();
}

class _MealQuantityStepState extends State<MealQuantityStep> {
  int quantity = 1;

  double get unitPrice => widget.basePrice + widget.sizeIncrement;

  double get totalPrice => unitPrice * quantity;

  void _updateQuantity(int newQuantity) {
    if (newQuantity >= 1) {
      setState(() => quantity = newQuantity);
      widget.onQuantityChanged(quantity);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F28) : theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          // الصف العلوي: الإجمالي، العداد، وتفاصيل الحجم
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. جهة اليسار: الإجمالي
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("offers.total".tr(),
                        style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 2),
                    if (widget.originalPrice != null &&
                        widget.originalPrice! * quantity > totalPrice)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          "${(widget.originalPrice! * quantity).toInt()} ${"units.currency".tr()}",
                          style: const TextStyle(
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: Colors.grey,
                              fontSize: 13),
                        ),
                      ),
                    Text("${totalPrice.toInt()} ${"units.currency".tr()}",
                        style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

              // 2. المنتصف: عداد الكمية البرتقالي
              _buildCounterWidget(),

              // 3. جهة اليمين: تفاصيل الحجم والسعر
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (widget.onChangeSize != null)
                    GestureDetector(
                      onTap: widget.onChangeSize,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(widget.selectedSize,
                              style: TextStyle(color: theme.textTheme.bodyLarge?.color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          const SizedBox(width: 4),
                          const Icon(Icons.edit, color: Color(0xFFFF5722), size: 14),
                        ],
                      ),
                    )
                  else
                    Text(widget.selectedSize,
                        style: TextStyle(color: theme.textTheme.bodyLarge?.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                  Text("+${widget.sizeIncrement.toInt()} ${"units.currency"
                      .tr()}",
                      style: const TextStyle(color: Color(0xFFFF5722),
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                  Text("${widget.basePrice.toInt()} ${"units.currency".tr()}",
                      style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
          ],
          ),

          const SizedBox(height: 24),

          // زر تخصيص الوجبة (Outlined)
          OutlinedButton(
            onPressed: widget.onCustomizeTap,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              side: const BorderSide(color: Color(0xFFFF5722), width: 1.2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100)),
            ),
            child: Text(
              "offers.customize_meal_btn".tr(),
              style: const TextStyle(color: Color(0xFFFF5722),
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
            ),
          ),

          const SizedBox(height: 12),

          // زر حذف باللون الأحمر أسفل اليسار
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => _updateQuantity(1),
              child: Text(
                "offers.delete".tr(),
                style: const TextStyle(color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF151A23), // خلفية داكنة للعداد
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _counterBtn("+", () => _updateQuantity(quantity + 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text("$quantity", style: const TextStyle(color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
          ),
          _counterBtn("-", () => _updateQuantity(quantity - 1)),
        ],
      ),
    );
  }

  Widget _counterBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFFF5722), // اللون البرتقالي للأزرار
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}