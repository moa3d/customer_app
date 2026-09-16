import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class FriedOnionWidget extends StatefulWidget {
  final String name;
  final double price;
  final Function(bool) onSelectionChanged;

  const FriedOnionWidget({
    super.key,
    required this.name,
    required this.price,
    required this.onSelectionChanged,
  });

  @override
  State<FriedOnionWidget> createState() => _FriedOnionWidgetState();
}

class _FriedOnionWidgetState extends State<FriedOnionWidget> {
  bool isSelected = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() => isSelected = !isSelected);
        widget.onSelectionChanged(isSelected);
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 70),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor.withValues(alpha: 0.1)
              : (isDark
              ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
              : Colors.grey[200]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected ? theme.primaryColor : Colors.transparent,
              width: 1.5),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? theme.primaryColor : theme
                  .unselectedWidgetColor.withValues(alpha: 0.5),
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.name,
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (widget.price > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      "+${widget.price.toInt()} ${"order.currency".tr()}",
                      style: TextStyle(color: theme.primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}