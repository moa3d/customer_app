import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'fried_onion_widget.dart';
import 'rice_component_widget.dart';
import 'optional_additions_header_widget.dart';

class MealCustomizationStep extends StatefulWidget {
  final double unitPrice;
  final double? originalPrice;
  final int currentQuantity;
  final List<Map<String, dynamic>> availableExtras;
  final List<String> ingredients;
  final Function(int) onQuantityChanged;
  final Function(List<
      Map<String, dynamic>>, double) onChanged; // تحديث فوري للتغييرات

  const MealCustomizationStep({
    super.key,
    required this.unitPrice,
    this.originalPrice,
    required this.currentQuantity,
    required this.availableExtras,
    required this.ingredients,
    required this.onQuantityChanged,
    required this.onChanged,
  });

  @override
  State<MealCustomizationStep> createState() => _MealCustomizationStepState();
}

class _MealCustomizationStepState extends State<MealCustomizationStep> {
  final List<Map<String, dynamic>> _selectedExtras = [];
  double _extrasTotal = 0.0;

  double get totalPrice =>
      (widget.unitPrice + _extrasTotal) * widget.currentQuantity;

  double get originalTotalPrice =>
      ((widget.originalPrice ?? widget.unitPrice) + _extrasTotal) *
      widget.currentQuantity;

  void _toggleExtra(Map<String, dynamic> extra, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedExtras.add(extra);
        _extrasTotal += (extra['price'] as num).toDouble();
      } else {
        _selectedExtras.removeWhere((e) => e['name'] == extra['name']);
        _extrasTotal -= (extra['price'] as num).toDouble();
      }
      // إبلاغ الصفحة الأم بالتغييرات فوراً لتحديث ملخص السعر
      widget.onChanged(_selectedExtras, _extrasTotal);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double itemWidth = (MediaQuery
        .of(context)
        .size
        .width - 40) / 2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopSummaryCard(theme),
          const SizedBox(height: 24),

          if (widget.ingredients.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "offers.main_components".tr(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                    Icons.check_circle, color: Color(0xFF00D254), size: 22),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.ingredients.map((name) =>
                  SizedBox(
                      width: itemWidth, child: RiceComponentWidget(name: name))
              ).toList(),
            ),
            const SizedBox(height: 32),
          ],

          if (widget.availableExtras.isNotEmpty) ...[
            const OptionalAdditionsHeaderWidget(),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.availableExtras.map((extra) =>
                  SizedBox(
                    width: itemWidth,
                    child: FriedOnionWidget(
                      name: extra['name'] ?? "",
                      price: (extra['price'] as num?)?.toDouble() ?? 0.0,
                      onSelectionChanged: (selected) =>
                          _toggleExtra(extra, selected),
                    ),
                  )).toList(),
            ),
          ],
          // تم نقل الزر للصفحة الأم ليكون دائماً بعد ملخص السعر
        ],
      ),
    );
  }

  Widget _buildTopSummaryCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF1A1F28)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text("offers.quantity".tr(),
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("offers.total".tr(),
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 4),
                  if (originalTotalPrice > totalPrice)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        "${originalTotalPrice.toInt()} ${"units.currency".tr()}",
                        style: const TextStyle(
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Colors.grey,
                            fontSize: 14),
                      ),
                    ),
                  Text("${totalPrice.toInt()} ${"units.currency".tr()}",
                      style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              _buildQuantitySelector(theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFF151A23),
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          _counterBtn(
              "+", () => widget.onQuantityChanged(widget.currentQuantity + 1),
              theme),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text("${widget.currentQuantity}", style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
          ),
          _counterBtn("-", () {
            if (widget.currentQuantity > 1) {
              widget.onQuantityChanged(
                  widget.currentQuantity - 1);
            }
          }, theme),
        ],
      ),
    );
  }

  Widget _counterBtn(String label, VoidCallback onTap, ThemeData theme) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(color: const Color(0xFFFF5722),
            borderRadius: BorderRadius.circular(8)),
        child: Center(child: Text(label, style: const TextStyle(
            color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))),
      ),
    );
  }
}