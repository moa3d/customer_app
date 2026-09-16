import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomnow_app/features/home/presentation/widgets/meal_card.dart';
import 'package:nomnow_app/features/restaurant/data/models/meal.dart';

import '../helpers/test_app.dart';
import '../helpers/test_helpers.dart';

Meal _meal({
  int? discountPercent,
  num price = 5000,
  List<Map<String, dynamic>> sizes = const [],
  String? currency,
}) {
  // بلا أحجام افتراضياً: وجود sizes يُلغي price في displayPrice، وهذه
  // المجموعة تختبر شارة الخصم لا قاعدة الأحجام (لها اختباراتها في meal_test).
  final json = createTestMealJson()
    ..['price'] = price
    ..['sizes'] = sizes
    ..['restaurantId'] = {'_id': 'rest_1', 'name': 'R', 'currency': ?currency};
  if (discountPercent != null) {
    json['promotions'] = [
      {'type': 'discount', 'discountValue': discountPercent},
    ];
  }
  return Meal.fromJson(json);
}

/// يعرض البطاقة داخل صندوق بأبعاد محددة — نحاكي القيدين الحقيقيين:
/// الشريط الأفقي في الرئيسية (160×200) وخلية شبكة «جميع الوجبات».
Future<void> _pumpCard(
  WidgetTester tester,
  Meal meal, {
  required double width,
  required double height,
}) async {
  await tester.pumpWidget(
    wrapWithApp(
      Center(
        child: SizedBox(
          width: width,
          height: height,
          child: MealCard(meal: meal, width: width),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() async {
    await initTestBindings();
  });

  group('MealCard — بلا خصم', () {
    testWidgets('يعرض سعراً واحداً بلا شارة خصم', (tester) async {
      await _pumpCard(tester, _meal(), width: 160, height: 200);

      expect(find.textContaining('5000'), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
    });
  });

  group('MealCard — العملة', () {
    // انحدار: كانت البطاقة تقرأ العملة من مفتاح الترجمة `restaurant.currency`،
    // فيظهر مطعم ألماني بـ«ل.س» لمستخدم يقرأ بالعربية. العملة خاصية بيانات.
    testWidgets('يعرض عملة المطعم لا عملة اللغة', (tester) async {
      await _pumpCard(tester, _meal(currency: 'EUR'),
          width: 160, height: 200);

      expect(find.textContaining('€'), findsOneWidget);
    });

    testWidgets('يعود إلى ل.س حين لا تصل عملة', (tester) async {
      await _pumpCard(tester, _meal(), width: 160, height: 200);

      expect(find.textContaining('ل.س'), findsOneWidget);
    });
  });

  group('MealCard — مع خصم', () {
    testWidgets('يعرض شارة النسبة والسعرين', (tester) async {
      await _pumpCard(
        tester,
        _meal(discountPercent: 20),
        width: 160,
        height: 200,
      );

      // الشارة
      expect(find.text('-20%'), findsOneWidget);
      // السعر بعد الخصم: 5000 × 0.8 = 4000
      expect(find.textContaining('4000'), findsOneWidget);
      // السعر الأصلي مشطوباً — نصّ منفصل بلا وحدة عملة
      expect(find.text('5000'), findsOneWidget);
    });

    testWidgets('السعر الأصلي مشطوب فعلاً', (tester) async {
      await _pumpCard(
        tester,
        _meal(discountPercent: 20),
        width: 160,
        height: 200,
      );

      final original = tester.widget<Text>(find.text('5000'));
      expect(original.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('يحسب النسبة الكبيرة بشكل صحيح', (tester) async {
      await _pumpCard(
        tester,
        _meal(discountPercent: 75),
        width: 160,
        height: 200,
      );

      expect(find.text('-75%'), findsOneWidget);
      // 5000 × 0.25 = 1250
      expect(find.textContaining('1250'), findsOneWidget);
    });
  });

  // أكثر نقطة مرشّحة للانكسار: نفس البطاقة تُستخدم في شبكة بعمودين
  // (childAspectRatio 0.78) وهي أضيق من الشريط الأفقي، والسعران في Row واحد.
  group('MealCard — لا يوجد overflow', () {
    final sizes = <String, List<double>>{
      'الشريط الأفقي في الرئيسية': [160, 200],
      'خلية الشبكة على شاشة 360': [159, 204],
      'خلية ضيقة جداً (حالة قصوى)': [120, 170],
    };

    for (final entry in sizes.entries) {
      testWidgets('${entry.key} — مع خصم وسعر طويل', (tester) async {
        await _pumpCard(
          tester,
          _meal(discountPercent: 15, price: 1250000),
          width: entry.value[0],
          height: entry.value[1],
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('${entry.key} — بلا خصم', (tester) async {
        await _pumpCard(
          tester,
          _meal(),
          width: entry.value[0],
          height: entry.value[1],
        );

        expect(tester.takeException(), isNull);
      });
    }
  });
}
