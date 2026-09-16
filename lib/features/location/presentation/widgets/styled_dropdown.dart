import 'package:flutter/material.dart';

class StyledDropdown extends StatelessWidget {
  final String hint;
  final List<String> options;
  final String? value;
  final ValueChanged<String?> onChanged;

  const StyledDropdown({
    super.key,
    required this.hint,
    required this.options,
    this.value,
    required this.onChanged,
  });

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
      child: DropdownButtonFormField<String>(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        initialValue: value,
        hint: Align(alignment: Alignment.centerRight, child: Text(hint, style: theme.inputDecorationTheme.hintStyle)),
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
        onChanged: onChanged,
        items: options.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
        value: value,
            child: Align(alignment: Alignment.centerRight, child: Text(value)),
          );
        }).toList(),
        decoration: InputDecoration(
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
