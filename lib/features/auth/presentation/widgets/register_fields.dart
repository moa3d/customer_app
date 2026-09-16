import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class RegisterFields extends StatefulWidget {
  final IconData icon;
  final String title;
  final String hint;
  final TextEditingController controller;
  final bool isPassword;
  final ui.TextDirection? textDirection;

  const RegisterFields({
    super.key,
    required this.icon,
    required this.title,
    required this.hint,
    required this.controller,
    this.isPassword = false,
    this.textDirection,
  });

  @override
  State<RegisterFields> createState() => _RegisterFieldsState();
}

class _RegisterFieldsState extends State<RegisterFields> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final bool isRtl = context.locale.languageCode == 'ar';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff1A1F28) : Colors.grey[100],
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        boxShadow: isDark ? [] : [
          const BoxShadow(color: Colors.black12, blurRadius: 4)
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: isRtl
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.end,
              children: [
                if (isRtl) ..._buildLabelItems(widget.icon, widget.title, isDark)
                else
                  ..._buildLabelItems(widget.icon, widget.title, isDark).reversed,
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
                left: 12.0, right: 12.0, top: 2, bottom: 12),
            child: SizedBox(
              height: 45,
              child: TextField(
                controller: widget.controller,
                obscureText: _obscure,
                textDirection: widget.textDirection,
                style: TextStyle(
                    color: isDark ? const Color(0xff99A1AF) : Colors.black87),
                cursorColor: const Color(0xffF44F27),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: TextStyle(
                    color: isDark ? const Color(0xff606978) : Colors.grey[500],
                    fontSize: 14,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  fillColor: isDark ? const Color(0xff151A23) : Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xff364153)),
                  ),
                  suffixIcon: widget.isPassword
                      ? IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 20,
                            color: isDark
                                ? const Color(0xff606978)
                                : Colors.grey[500],
                          ),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildLabelItems(IconData icon, String title, bool isDark) {
    return [
      Container(
        decoration: const BoxDecoration(
          color: Color(0xffF44F27),
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        height: 35,
        width: 35,
        child: Icon(icon, size: 20, color: Colors.white),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          title,
          style: TextStyle(
            color: isDark ? const Color(0xff99A1AF) : Colors.black54,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ];
  }
}