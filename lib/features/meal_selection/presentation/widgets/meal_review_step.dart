import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class MealReviewStep extends StatelessWidget {
  final double unitPrice;
  final double? originalPrice;
  final int quantity;
  final List<Map<String, dynamic>> extras;
  final double extrasTotal;
  final Function(int) onQuantityChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String? selectedSizeName;
  final double? sizePrice;

  /// إضافة هذه الوجبة للسلة ثم الرجوع لقائمة المطعم لاختيار وجبة أخرى.
  final VoidCallback onAddAnother;

  const MealReviewStep({
    super.key,
    required this.unitPrice,
    this.originalPrice,
    required this.quantity,
    required this.extras,
    required this.extrasTotal,
    required this.onQuantityChanged,
    required this.onEdit,
    required this.onDelete,
    this.selectedSizeName,
    this.sizePrice,
    required this.onAddAnother,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final double totalPrice = (unitPrice + extrasTotal) * quantity;
    final double originalTotalPrice =
        ((originalPrice ?? unitPrice) + extrasTotal) * quantity;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // 1. كارت ملخص الطلب (مطابق للصورة تماماً)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1F28) : theme.cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                // الصف العلوي: السعر، الكمية، والوصف
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // جهة اليسار: الإجمالي
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Text("offers.total".tr(), style: TextStyle(
                            color: theme.hintColor, fontSize: 12)),
                        if (originalTotalPrice > totalPrice)
                          Padding(
                            padding: const EdgeInsets.only(top: 2, bottom: 2),
                            child: Text(
                              "${originalTotalPrice.toInt()} ${"units.currency".tr()}",
                              style: const TextStyle(
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: Colors.grey,
                                  fontSize: 13),
                            ),
                          ),
                        Text("${totalPrice.toInt()} ${"units.currency".tr()}",
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                    // المنتصف: عداد الكمية
                    _buildQuantityCounter(theme),
                    // جهة اليمين: الحجم
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                        if (selectedSizeName != null)
                          Text(selectedSizeName!,
                              style: TextStyle(color: theme.hintColor, fontSize: 13)),
                        if (sizePrice != null && sizePrice! > 0)
                          Text("+${sizePrice!.toInt()} ${"units.currency".tr()}",
                              style: const TextStyle(color: Color(0xFFFF5722),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1),
                ),

                // قسم الإضافات المخططة (Tags/Chips)
                if (extras.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: extras.map((extra) =>
                        _buildExtraTag(extra['name'] ?? "")).toList(),
                  ),

                const SizedBox(height: 16),
                const Divider(height: 1),

                // أزرار التحكم السفلية داخل الكارت
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: onDelete,
                      child: Text("offers.delete".tr(), style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold)),
                    ),
                    TextButton(
                      onPressed: onEdit,
                      child: Text("offers.edit".tr(), style: const TextStyle(
                          color: Color(0xff717182),
                          fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 2. زر "انقر لإضافة طلب آخر" — كان `onTap` فارغاً إلا من تعليق،
          // فالزر يستجيب بصرياً ولا يفعل شيئاً.
          InkWell(
            onTap: onAddAnother,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFF5722), width: 1.5),
              ),
              child: Center(
                child: Text(
                  "offers.click_to_add_another".tr(),
                  style: const TextStyle(color: Color(0xFFFF5722),
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // بناء عداد الكمية
  Widget _buildQuantityCounter(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFF151A23),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _counterBtn("+", () => onQuantityChanged(quantity + 1), theme),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text("$quantity", style: const TextStyle(color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
          ),
          _counterBtn("-", () {
            if (quantity > 1) onQuantityChanged(quantity - 1);
          }, theme),
        ],
      ),
    );
  }

  Widget _counterBtn(String label, VoidCallback onTap, ThemeData theme) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(color: const Color(0xFFFF5722),
            borderRadius: BorderRadius.circular(8)),
        child: Center(child: Text(label, style: const TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
      ),
    );
  }

  // بناء تاغ الإضافة (Chip)
  Widget _buildExtraTag(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: const Color(0xFFFF5722).withValues(alpha: 0.6)),
      ),
      child: Text(
        name,
        style: TextStyle(color: const Color(0xFFFF5722), fontSize: 11),
      ),
    );
  }
}