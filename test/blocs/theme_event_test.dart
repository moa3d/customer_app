import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomnow_app/core/theme/theme_bloc.dart' as theme;

void main() {
  group('ThemeEvent', () {
    test('ThemeChanged stores themeMode', () {
      final event = theme.ThemeChanged(ThemeMode.dark);
      expect(event.themeMode, ThemeMode.dark);
    });

    test('ThemeChanged props', () {
      final event = theme.ThemeChanged(ThemeMode.light);
      expect(event.props, [ThemeMode.light]);
    });

    test('ThemeChanged equality', () {
      final a = theme.ThemeChanged(ThemeMode.dark);
      final b = theme.ThemeChanged(ThemeMode.dark);
      final c = theme.ThemeChanged(ThemeMode.light);
      expect(a, b);
      expect(a == c, false);
    });
  });
}
