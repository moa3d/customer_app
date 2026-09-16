import 'package:flutter/material.dart';

class AppTheme {
  // ألوانك الخاصة (كما في تصميمك الأصلي)
  static const LinearGradient myBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xff11141B), Color(0xff151A23)],
  );
  // static const Color myBackgroundDark = Color(0xff151A23);
  // static const Color myCardDark = Color(0xff1A1F28);
  static const Color myGreyText = Color(0xff717182);
  static const Color myOrange = Color(0xffF44F27);
  static const Color myGreen = Color(0xff22C55E);
  static const Color myBackgroundDark = Color(0xff11141B);
  static const Color myCardDark = Color(0xff1A1F28);
  static const Color myGreyTextDark = Color(0xff94A3B8);

  // الألوان للوضع الفاتح (Light)
  static const Color myBackgroundLight = Color(0xffF8FAFC);
  static const Color myCardLight = Colors.white;
  static const Color myGreyTextLight = Color(0xff64748B);

  static const Color myDisplayDark = Color(0xff151A23);
  static const Color myAppBar = Color(0xff1A1F28);
  static const Color myTextButton = Colors.black;
  static const Color myActionButton = Color(0xff717182);


  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,

    scaffoldBackgroundColor: myBackgroundDark,
    cardColor: myCardDark,

    primaryColor: myOrange,
    hintColor: myActionButton,
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        textStyle: WidgetStatePropertyAll(TextStyle(color: myTextButton)),
      ),
    ),

    iconTheme: const IconThemeData(color: Colors.white),
    textTheme: const TextTheme(
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      bodyMedium: TextStyle(color: myGreyTextDark),
      bodySmall: TextStyle(color: myGreyTextDark),
    ),

    inputDecorationTheme: InputDecorationTheme(
      fillColor: myCardDark,
      filled: true,

      hintStyle: const TextStyle(color: Color(0xff475569), fontSize: 14),

      prefixIconColor: const Color(0xff94A3B8),
      suffixIconColor: const Color(0xff94A3B8),

      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),

      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: Color(0xff717182),
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xff717182), width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    colorScheme:
        ColorScheme.fromSeed(
          seedColor: myOrange,
          brightness: Brightness.dark,
        ).copyWith(
          surface: myBackgroundDark,
        ),
  );


  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xffF3F3F3),
    cardColor: myCardLight,
    primaryColor: myOrange,
    hintColor: myGreyText,

    iconTheme: const IconThemeData(color: Colors.black87),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: Color(0xff1E293B),
        fontWeight: FontWeight.bold,
      ),
      bodyMedium: TextStyle(color: myGreyTextLight),
      bodySmall: TextStyle(color: myGreyTextLight),
    ),

    inputDecorationTheme: InputDecorationTheme(
      hintStyle: const TextStyle(color: Color(0xff94A3B8), fontSize: 14),
      fillColor: const Color(0xffF5F4F4),
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xffE2E8F0),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          16,
        ),
        borderSide: const BorderSide(
          color: Color(0xffB0B8C1),
          width: 1.0,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xffB0B8C1),
          width: 1.5,
        ),
      ),

      // أيقونات البحث والفلترة
      prefixIconColor: const Color(0xff99A1AF),
      suffixIconColor: const Color(0xff99A1AF),

      // contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: myOrange,
      brightness: Brightness.light,
    ),
  );
}
