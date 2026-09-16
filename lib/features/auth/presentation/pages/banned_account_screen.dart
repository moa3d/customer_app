import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:nomnow_app/features/auth/presentation/pages/login_phone_screen.dart';

import '../../../../core/services/auth_service.dart';

/// شاشة إشعار المستخدم بحالة حسابه (محظور أو مرفوض).
class BannedAccountScreen extends StatelessWidget {
  /// تحدد ما إذا كان الحساب مرفوضاً (خاص بالمستخدمين) أو محظوراً بشكل عام.
  final bool isRejected;

  const BannedAccountScreen({super.key, this.isRejected = false});

  @override
  Widget build(BuildContext context) {
    // استخدام الـ Theme الخاص بالتطبيق لضمان تناسق الألوان مع الوضع الليلي والعادي.
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // قسم الأيقونة التعبيرية: تم فصلها لتحسين أداء إعادة البناء (Rebuild).
              _StatusIcon(isRejected: isRejected),
              const SizedBox(height: 30),

              // نصوص الحالة (العنوان والوصف) مع الترجمة.
              _StatusTexts(isRejected: isRejected),
              const SizedBox(height: 40),

              // أزرار التحكم (الدعم وتسجيل الخروج).
              _ActionButtons(isRejected: isRejected),
            ],
          ),
        ),
      ),
    );
  }
}

/// ويدجت عرض الأيقونة بناءً على حالة الحساب.
class _StatusIcon extends StatelessWidget {
  final bool isRejected;

  const _StatusIcon({required this.isRejected});

  @override
  Widget build(BuildContext context) {
    final color = isRejected ? Colors.orange : Colors.red;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isRejected ? Icons.assignment_late : Icons.block_flipped,
        color: color,
        size: 80,
      ),
    );
  }
}

/// ويدجت عرض النصوص المترجمة.
class _StatusTexts extends StatelessWidget {
  final bool isRejected;

  const _StatusTexts({required this.isRejected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isRejected ? Colors.orange : Colors.red;

    return Column(
      children: [
        Text(
          isRejected ? "rejected_title".tr() : "banned_title".tr(),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          isRejected ? "rejected_message".tr() : "banned_message".tr(),
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// ويدجت أزرار الأكشن (التواصل مع الدعم وتسجيل الخروج).
class _ActionButtons extends StatelessWidget {
  final bool isRejected;

  const _ActionButtons({required this.isRejected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // زر الدعم الفني: تم استخدامه كزر أساسي
        ElevatedButton.icon(
          onPressed: () {
            // هنا يتم الربط مستقبلاً مع خدمة الدعم.
          },
          icon: const Icon(Icons.support_agent, color: Colors.white),
          label: Text(
            "contact_support".tr(),
            style: const TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
        const SizedBox(height: 15),

        // زر تسجيل الخروج: يعيد المستخدم لشاشة اختيار الدخول ويطهر بيانات الجلسة.
        TextButton(
          onPressed: () async {
            // تنفيذ عملية تسجيل الخروج من الخدمة وتصفير التوكن.
            await AuthService().logout();
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const LoginPhoneScreen(),
                ),
                    (route) => false,
              );
            }
          },
          child: Text(
            "logout_banned".tr(),
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}