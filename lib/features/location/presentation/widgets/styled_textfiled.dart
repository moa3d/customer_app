import 'package:flutter/material.dart';

class StyledTextField extends StatelessWidget {
   final String hint;
   final ValueChanged<String> onChanged;
   final TextEditingController controller;

  const StyledTextField({super.key, required this.hint, required this.onChanged, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: (val) => onChanged(val),
        textAlign: TextAlign.right,
        style: TextStyle(color: theme.textTheme.bodyMedium?.color),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: theme.inputDecorationTheme.hintStyle,
          filled: true,
          fillColor: isDark ? const Color(0xFF1E232E) : theme.cardColor,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}