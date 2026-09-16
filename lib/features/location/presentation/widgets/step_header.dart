import 'package:flutter/material.dart';

class StepHeader extends StatelessWidget {
  final String title;
  final String description;
  final String numberStep;
  final bool isCompleted;

  const StepHeader({
    super.key, // إضافة مفتاح السوبر كأفضل ممارسة في Flutter
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.numberStep,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      // محاذاة العناصر للأعلى لضمان بقاء الدائرة في الأعلى إذا نزل النص لعدة أسطر
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // الجزء الخاص بالأيقونة أو الرقم
        isCompleted
            ? Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: isCompleted
                    ? theme.primaryColor.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            color: theme.primaryColor,
            borderRadius: const BorderRadius.all(Radius.circular(14)),
          ),
          child: const Center(
            child: Icon(Icons.check, color: Colors.white),
          ),
        )
            : Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.all(Radius.circular(14)),
          ),
          child: Center(
            child: Text(
              numberStep,
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // تغليف العمود بـ Expanded هو الحل لمنع الـ Overflow وجعل النص ينزل للأسفل

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // لجعل العمود يأخذ مساحة محتواه فقط
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                // السماح للنص بالنزول لسطر جديد إذا لم تكفِ المساحة
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor, // استخدام لون التلميح للوصف لتعزيز التباين
                ),
                // السماح للوصف بالنزول لسطر جديد أيضاً
                softWrap: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}