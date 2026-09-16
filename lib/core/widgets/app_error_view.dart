import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../network/app_error.dart';
import '../utils/app_sizes.dart';

/// شاشة الحالة الموحّدة: أيقونة + عنوان + وصف + زر إجراء.
///
/// تُستخدم لحالتي الخطأ والقائمة الفارغة في كل الصفحات بدل تكرار
/// `Center > Column > Icon/Text/Button` في كل ملف.
///
/// للأخطاء استخدم [AppErrorView.fromError] فهي تمرّر الاستثناء عبر
/// [AppError] فتظهر رسالة مفهومة بدل النص الخام للاستثناء.
class AppErrorView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// نسخة مصغّرة تصلح داخل قسم من الصفحة لا صفحة كاملة.
  final bool compact;

  /// نبرة العرض: الخطأ يأخذ اللون التحذيري، والحالة الفارغة لون محايد.
  final bool isError;

  /// تفاصيل تقنية تُعرض في وضع التطوير فقط.
  final String? details;

  const AppErrorView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
    this.isError = true,
    this.details,
  });

  /// يبني الشاشة من استثناء خام (DioException أو غيره).
  factory AppErrorView.fromError(
    Object? error, {
    Key? key,
    VoidCallback? onRetry,
    bool compact = false,
  }) {
    final e = AppError.from(error);
    return AppErrorView(
      key: key,
      icon: e.icon,
      title: e.title,
      message: e.message,
      // نعرض "إعادة المحاولة" متى وُجدت دالة علىRetry وكان الخطأ قابلاً للإعادة
      // (شبكة/مهلة/خادم) أو 404 مؤقت (مثل مسار كوبونات لم يُنشر بعد على الخادم)،
      // مع بقاء حماية الجلسات المنتهية (unauthorized) بلا زر.
      actionLabel:
          (e.canRetry || e.kind == AppErrorKind.notFound) && onRetry != null
              ? 'retry'.tr()
              : null,
      onAction: (e.canRetry || e.kind == AppErrorKind.notFound)
          ? onRetry
          : null,
      compact: compact,
      details: e.technicalDetails,
    );
  }

  /// حالة "لا توجد بيانات" — نفس التخطيط بنبرة محايدة.
  const AppErrorView.empty({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  })  : isError = false,
        details = null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent =
        isError ? theme.colorScheme.error : theme.colorScheme.primary;
    final iconSize = compact ? AppSizes.iconSize28 : AppSizes.iconSize48;

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: AppSizes.p24,
          vertical: compact ? AppSizes.p16 : AppSizes.p32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(compact ? AppSizes.p12 : AppSizes.p20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.10),
              ),
              child: Icon(icon, size: iconSize, color: accent),
            ),
            SizedBox(height: compact ? AppSizes.space12 : AppSizes.space20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: (compact
                      ? theme.textTheme.titleSmall
                      : theme.textTheme.titleMedium)
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (message != null && message!.isNotEmpty) ...[
              const SizedBox(height: AppSizes.space8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.hintColor),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: compact ? AppSizes.space16 : AppSizes.space24),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded,
                    size: AppSizes.iconSize18),
                label: Text(actionLabel!),
              ),
            ],
            if (kDebugMode && details != null && details!.isNotEmpty) ...[
              const SizedBox(height: AppSizes.space16),
              Text(
                details!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor.withValues(alpha: 0.7),
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
