import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// شريط تنبيه رفيع فوق قوائم الرئيسية — يشرح للمستخدم لماذا لا يبدو الترتيب
/// كما يتوقّع.
///
/// [onTap] و[actionLabel] اختياريان: بعض التنبيهات لا إجراء لها (غياب
/// التقييمات مثلاً ليس شيئاً يفعله المستخدم)، فلا نعرض له زراً وهمياً.
class HomeNotice extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onTap;

  const HomeNotice({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 4),
      child: Material(
        color: theme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 18, color: theme.primaryColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
                if (actionLabel != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    actionLabel!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// تنبيه يظهر عندما يُرجع الباك `locationUsed: false`.
///
/// بلا موقع يسقط عامل القرب من معادلة الترتيب، فيصبح «الأقرب» و«الأعلى
/// تقييماً» ترتيبين متطابقين وتعود المسافة `null` لكل مطعم. بدون هذا التنبيه
/// يبدو الأمر خللاً في التطبيق: المستخدم يضغط «الأقرب» فلا يتغيّر شيء.
class LocationNotice extends StatelessWidget {
  /// يقود إلى شاشة إضافة عنوان.
  final VoidCallback onTap;

  const LocationNotice({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return HomeNotice(
      icon: Icons.location_off_outlined,
      message: "location_not_used_hint".tr(),
      actionLabel: "enable_location_cta".tr(),
      onTap: onTap,
    );
  }
}
