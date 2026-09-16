import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// حوار تمهيدي يسبق حوار صلاحية النظام.
///
/// على أندرويد 13+ حوار النظام يُعرض مرة واحدة عملياً — الرفض يُغلق الصلاحية
/// ولا يعود الحوار للظهور. الشرح قبله يمنع حرق هذه الفرصة الوحيدة.
///
/// يُعيد `true` إن اختار المستخدم التفعيل، و`false`/`null` غير ذلك.
Future<bool?> showNotificationPermissionDialog(BuildContext context) {
  final theme = Theme.of(context);

  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "notif_permission_prompt_title".tr(),
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        "notif_permission_prompt_body".tr(),
        style: TextStyle(color: theme.hintColor, fontSize: 14, height: 1.5),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(
            "notif_permission_later".tr(),
            style: TextStyle(color: theme.hintColor),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text("notif_permission_enable".tr()),
        ),
      ],
    ),
  );
}
