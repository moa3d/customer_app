import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nomnow_app/features/cart/presentation/widgets/cart_summary_row.dart';

Widget wrapWidget(Widget child) {
  return EasyLocalization(
    supportedLocales: const [Locale('en')],
    path: 'assets/translations',
    fallbackLocale: const Locale('en'),
    startLocale: const Locale('en'),
    child: MaterialApp(
      theme: ThemeData(primaryColor: Colors.orange),
      home: Scaffold(body: Padding(
        padding: const EdgeInsets.all(8),
        child: child,
      )),
    ),
  );
}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  group('CartSummaryRow', () {
    testWidgets('displays label and value', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const CartSummaryRow(label: 'Subtotal', value: '10000 ل.س'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Subtotal'), findsOneWidget);
      expect(find.text('10000 ل.س'), findsOneWidget);
    });

    testWidgets('displays secondary color when not total', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const CartSummaryRow(label: 'Delivery Fee', value: '500 ل.س'),
      ));
      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.text('Delivery Fee'));
      final color = textWidget.style?.color;
      expect(color, isNotNull);
      // SecondaryText = Color(0xFFAAB2BD) — not primary
      expect(color, isNot(Colors.orange));
    });

    testWidgets('displays primary color when isTotal is true', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const CartSummaryRow(label: 'Total', value: '15000 ل.س', isTotal: true),
      ));
      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.text('Total'));
      final color = textWidget.style?.color;
      // primaryOrange = Color(0xFFFF5630)
      expect((color!.r * 255.0).round().clamp(0, 255), 255);
      expect((color.g * 255.0).round().clamp(0, 255), 86);
      expect((color.b * 255.0).round().clamp(0, 255), 48);
    });

    testWidgets('renders without overflow', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const CartSummaryRow(label: 'Test', value: 'Value'),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('bold font when isTotal', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const CartSummaryRow(label: 'Total', value: '10000', isTotal: true),
      ));
      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.text('Total'));
      expect(textWidget.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('normal font when not isTotal', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const CartSummaryRow(label: 'Subtotal', value: '5000'),
      ));
      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.text('Subtotal'));
      expect(textWidget.style?.fontWeight, FontWeight.normal);
    });

    testWidgets('strikes through the original price and shows the badge',
        (tester) async {
      await tester.pumpWidget(wrapWidget(
        const CartSummaryRow(
          label: 'Delivery Fee',
          value: '',
          strikethroughValue: '1000 ل.س',
          badge: 'Free delivery',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Delivery Fee'), findsOneWidget);
      expect(find.text('1000 ل.س'), findsOneWidget);
      expect(find.text('Free delivery'), findsOneWidget);

      final original = tester.widget<Text>(find.text('1000 ل.س'));
      expect(original.style?.decoration, TextDecoration.lineThrough);

      // freeGreen = Color(0xFF2E7D32)
      final badge = tester.widget<Text>(find.text('Free delivery'));
      final color = badge.style!.color!;
      expect((color.r * 255.0).round().clamp(0, 255), 46);
      expect((color.g * 255.0).round().clamp(0, 255), 125);
      expect((color.b * 255.0).round().clamp(0, 255), 50);
      expect(badge.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('falls back to plain value when no promotion', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const CartSummaryRow(label: 'Delivery Fee', value: '1000 ل.س'),
      ));
      await tester.pumpAndSettle();

      final value = tester.widget<Text>(find.text('1000 ل.س'));
      expect(value.style?.decoration, isNot(TextDecoration.lineThrough));
    });
  });
}
