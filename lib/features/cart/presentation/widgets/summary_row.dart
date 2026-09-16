import 'package:flutter/material.dart';

Widget buildSummaryRow(BuildContext context, String title, String price,
    {bool isTotal = false}) {
  final theme = Theme.of(context);

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isTotal ? theme.primaryColor : theme.hintColor,
            fontSize: isTotal ? 18 : 15,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          price,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isTotal ? theme.primaryColor : theme.hintColor,
            fontSize: isTotal ? 18 : 15,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    ),
  );
}