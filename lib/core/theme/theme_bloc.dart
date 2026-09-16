import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_event.dart';
part 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  // الحالة المبدئية (نبدأ بافتراضي النظام)
  ThemeBloc() : super(const ThemeState(themeMode: ThemeMode.system)) {

    // عند تشغيل البلوك، نحمل الثيم المحفوظ
    on<ThemeChanged>((event, emit) async {
      await _saveTheme(event.themeMode);
      emit(ThemeState(themeMode: event.themeMode));
    });

    _loadTheme();
  }

  // دالة مساعدة لتحميل الثيم عند فتح التطبيق
  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDark');

    if (isDark != null) {
      add(ThemeChanged(isDark ? ThemeMode.dark : ThemeMode.light));
    }
  }

  // دالة مساعدة لحفظ الثيم
  Future<void> _saveTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    if (mode == ThemeMode.dark) {
      await prefs.setBool('isDark', true);
    } else {
      await prefs.setBool('isDark', false);
    }
  }
}