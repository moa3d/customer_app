import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nomnow_app/core/theme/theme_bloc.dart' as theme;

void main() {
  group('ThemeState', () {
    test('stores themeMode', () {
      final state = theme.ThemeState(themeMode: ThemeMode.dark);
      expect(state.themeMode, ThemeMode.dark);
    });

    test('Equatable props', () {
      final state = theme.ThemeState(themeMode: ThemeMode.system);
      expect(state.props, [ThemeMode.system]);
    });

    test('Equatable equality', () {
      final a = theme.ThemeState(themeMode: ThemeMode.light);
      final b = theme.ThemeState(themeMode: ThemeMode.light);
      final c = theme.ThemeState(themeMode: ThemeMode.dark);
      expect(a, b);
      expect(a == c, false);
    });
  });
}
