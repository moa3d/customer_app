import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomnow_app/features/home/presentation/widgets/location_notice.dart';

import '../../helpers/test_app.dart';

void main() {
  setUp(() async {
    await initTestBindings();
  });

  group('HomeNotice', () {
    // تنبيه غياب التقييمات لا إجراء له — لا شيء بيد المستخدم يفعله. عرض زرّ
    // لا يفعل شيئاً أسوأ من عدم عرض زرّ.
    testWidgets('بلا onTap لا يعرض زر إجراء ولا ينهار', (tester) async {
      await tester.pumpWidget(wrapWithApp(
        const HomeNotice(
          icon: Icons.info_outline,
          message: 'لا توجد تقييمات بعد',
        ),
      ));

      expect(find.text('لا توجد تقييمات بعد'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(tester.takeException(), isNull);

      // النقر على تنبيه بلا إجراء لا يفعل شيئاً ولا يرمي
      await tester.tap(find.byType(HomeNotice));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('مع onTap يعرض النص ويستجيب للنقر', (tester) async {
      var taps = 0;
      await tester.pumpWidget(wrapWithApp(
        HomeNotice(
          icon: Icons.location_off_outlined,
          message: 'فعّل الموقع',
          actionLabel: 'أضف عنواناً',
          onTap: () => taps++,
        ),
      ));

      expect(find.text('أضف عنواناً'), findsOneWidget);

      await tester.tap(find.byType(HomeNotice));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('نص طويل لا يسبب overflow على شاشة ضيقة', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(wrapWithApp(
        const HomeNotice(
          icon: Icons.info_outline,
          message: 'Noch keine Bewertungen — stattdessen nach Entfernung '
              'sortiert, sobald Bewertungen vorliegen',
          actionLabel: 'Adresse hinzufügen',
        ),
      ));

      expect(tester.takeException(), isNull);
    });
  });

  group('LocationNotice', () {
    testWidgets('يعرض رسالة الموقع وزر الإضافة', (tester) async {
      var taps = 0;
      await tester.pumpWidget(wrapWithApp(
        LocationNotice(onTap: () => taps++),
      ));

      expect(find.byType(HomeNotice), findsOneWidget);
      expect(find.byIcon(Icons.location_off_outlined), findsOneWidget);

      await tester.tap(find.byType(LocationNotice));
      await tester.pump();
      expect(taps, 1);
    });
  });
}
