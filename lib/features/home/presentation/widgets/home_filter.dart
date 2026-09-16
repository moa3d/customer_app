import 'package:flutter/material.dart';

// تم تحويل الويدجت إلى StatelessWidget، وهي الممارسة الأفضل في فلاتر.
class HomeFilter extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isSelected;

  const HomeFilter({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    // ---- دعم الأوضاع (Themes) ----
    // جلب الثيم الحالي للتطبيق
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;

    // تحديد الألوان بناءً على الثيم بدلاً من الألوان الثابتة
    final Color selectedColor = theme.primaryColor; // اللون الرئيسي للثيم (مثل البرتقالي)
    final Color unselectedColor = theme.hintColor.withValues(alpha: 
        0.3); // لون البطاقات أو لون داكن/فاتح مناسب
    final Color iconColor = theme.colorScheme
        .onPrimary; // لون مناسب للأيقونات فوق اللون الرئيسي (غالباً أبيض)
    final Color selectedTextColor = Colors.white; // لون النص المختار
    final Color unselectedTextColor = theme.textTheme.bodyMedium?.color ??
        theme.hintColor; // لون النص العادي

    return Padding(
      // استخدام symmetric لتحديد الـ padding الأفقي بشكل متساوٍ، وهو جيد لدعم اللغات
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        // لجعل العمود يأخذ أقل مساحة ممكنة عمودياً
        children: [
          Stack(
            clipBehavior: Clip.none, // للسماح للأيقونة بالظهور خارج الحدود
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTap: onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(14)),
                    // استخدام الألوان المعتمدة على الثيم
                    color: isSelected ? selectedColor : unselectedColor,
                    // --- التعديل 2: إضافة الظل هنا ---
                    boxShadow: [
                      if (isSelected) // تطبيق الظل فقط عند الاختيار
                        BoxShadow(
                          color: selectedColor.withValues(alpha: 0.5), // لون الظل
                          blurRadius: 10.0, // قوة الضبابية
                          spreadRadius: 1.0, // مدى انتشار الظل
                          offset: const Offset(
                              0, 2), // إزاحة الظل للأسفل قليلاً
                        ),
                    ],
                  ),
                  child: Icon(icon, color: isDarkTheme ? Colors.white : iconColor),
                ),
              ),
              // استخدام AnimatedOpacity لإظهار وإخفاء علامة الصح بسلاسة
              if (isSelected)
                Positioned(
                  bottom: -10,
                  // لا حاجة لتحديد right و left، التوسيط يتم عبر Stack
                  // --- التعديل 1: إصلاح شكل أيقونة علامة الصح ---
                  child: Container(
                    height: 20,
                    width: 20,
                    decoration: const BoxDecoration(
                      color: Colors.white, // خلفية الدائرة بيضاء
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.check,
                        color: selectedColor, // لون علامة الصح برتقالي
                        size: 13, // حجم مناسب لعلامة الصح
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // مسافة إضافية لتجنب تداخل النص مع أيقونة الصح
          Text(
            title,
            style: TextStyle(
              // استخدام ألوان النص المعتمدة على الثيم
              color: isSelected ? selectedTextColor : unselectedTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}