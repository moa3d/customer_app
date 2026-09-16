import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Initializes test bindings, SharedPreferences mock, and EasyLocalization.
/// Must be called in setUp() before any widget test.
Future<void> initTestBindings() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({
    'auth_token': 'test_token_123',
    'userId': 'user_123',
    'language_code': 'en',
  });
  await EasyLocalization.ensureInitialized();
}

/// Wraps a widget with EasyLocalization + MaterialApp for widget tests.
/// Uses English locale by default for deterministic assertions.
Widget wrapWithApp(
  Widget child, {
  List<Locale> supportedLocales = const [Locale('en')],
}) {
  return EasyLocalization(
    supportedLocales: supportedLocales,
    path: 'assets/translations',
    fallbackLocale: const Locale('en'),
    startLocale: const Locale('en'),
    child: MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

/// Wraps a widget with EasyLocalization + MaterialApp + MultiBlocProvider.
/// For testing screens that depend on BLoCs.
Widget wrapWithAppAndProviders(
  Widget child, {
  required List<BlocProvider> providers,
}) {
  return EasyLocalization(
    supportedLocales: const [Locale('en')],
    path: 'assets/translations',
    fallbackLocale: const Locale('en'),
    startLocale: const Locale('en'),
    child: MaterialApp(
      home: MultiBlocProvider(
        providers: providers,
        child: Scaffold(body: child),
      ),
    ),
  );
}
