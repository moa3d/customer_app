import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class OptionalAdditionsHeaderWidget extends StatelessWidget {
  const OptionalAdditionsHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const Icon(Icons.add, color: Colors.deepOrange, size: 28),
        const SizedBox(width: 8),
        Text(
          "offers.optional_additions".tr(),
          style: TextStyle(
              color: isDark ? Colors.white : theme.textTheme.bodyLarge?.color,
              fontSize: 18),
        ),
      ],
    );
  }
}