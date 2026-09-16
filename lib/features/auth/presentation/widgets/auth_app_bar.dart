import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';


import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_sizes.dart';

/// ويدجت الـ AppBar المستخدم في شاشات تسجيل الدخول والإنشاء
PreferredSizeWidget authAppBar({required BuildContext context}) {
  final theme = Theme.of(context);
  final bool isDark = theme.brightness == Brightness.dark;

  return AppBar(
    backgroundColor: isDark ? AppTheme.myAppBar : Colors.white,
    elevation: 0,
    scrolledUnderElevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        bottomRight: Radius.circular(24),
        bottomLeft: Radius.circular(24),
      ),
    ),
    leading: Padding(
      padding: const EdgeInsets.all(AppSizes.p8),
      child: Material(
        color: isDark ? const Color(0xff151A23) : Colors.grey[200],
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        child: InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          child: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : const Color(0xff4A5565),
          ),
        ),
      ),
    ),
    title: Text(
      "create_account_action".tr(),
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    bottom: const PreferredSize(
      preferredSize: Size.fromHeight(10),
      child: SizedBox(),
    ),
  );
}