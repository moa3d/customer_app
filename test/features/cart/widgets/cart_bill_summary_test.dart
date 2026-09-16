import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nomnow_app/features/cart/presentation/widgets/cart_bill_summary.dart';
import 'package:nomnow_app/features/cart/presentation/bloc/mail_bloc.dart';
import 'package:nomnow_app/features/cart/presentation/bloc/mail_state.dart';
import 'package:nomnow_app/features/cart/data/repositories/cart_repository.dart';
import 'package:nomnow_app/features/orders/data/repositories/order_repository.dart';
import 'package:nomnow_app/features/cart/domain/models/mail_item.dart';
import 'package:nomnow_app/features/location/presentation/bloc/location_bloc.dart';
import 'package:nomnow_app/core/services/auth_service.dart';

class MockCartRepository extends Mock implements CartRepository {}

class MockOrderRepository extends Mock implements OrderRepository {}

void main() {
  late MockCartRepository mockCartRepo;
  late MockOrderRepository mockOrderRepo;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    mockCartRepo = MockCartRepository();
    mockOrderRepo = MockOrderRepository();
  });

  MailItem makeItem({
    String id = 'item_1',
    String title = 'Pizza',
    double price = 5000,
    int quantity = 2,
  }) =>
      MailItem(
        id: id,
        foodId: 'food_1',
        restaurantId: 'rest_1',
        title: title,
        price: price,
        quantity: quantity,
        imagePath: '',
      );

  Widget buildWidget({
    required MailState state,
    bool isDelivery = true,
    String notes = '',
  }) {
    final controller = TextEditingController(text: notes);
    return EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      child: MaterialApp(
        theme: ThemeData(primaryColor: const Color(0xFFFF5630)),
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider<MailBloc>(
                create: (_) => MailBloc(
                  cartRepository: mockCartRepo,
                  orderRepository: mockOrderRepo,
                )..emit(state),
              ),
              BlocProvider<LocationBloc>(
                create: (_) => _MockLocationBloc(),
              ),
            ],
            child: CartBillSummary(
              state: state,
              isDelivery: isDelivery,
              notesController: controller,
            ),
          ),
        ),
      ),
    );
  }

  group('CartBillSummary', () {
    testWidgets('displays subtotal with correct value', (tester) async {
      final state = MailState(
        items: [makeItem(price: 5000, quantity: 2)],
        status: CartStatus.success,
        currency: 'SYP',
      );

      await tester.pumpWidget(buildWidget(state: state));
      await tester.pumpAndSettle();

      expect(find.text('subtotal'.tr()), findsOneWidget);
      // subtotal=10000, no delivery → total is also 10000, so appears twice
      expect(find.text('10000 SYP'), findsWidgets);
    });

    testWidgets('displays delivery fee when isDelivery is true', (tester) async {
      final state = MailState(
        items: [makeItem()],
        status: CartStatus.success,
        deliveryFee: 1000,
        currency: 'SYP',
      );

      await tester.pumpWidget(buildWidget(state: state, isDelivery: true));
      await tester.pumpAndSettle();

      expect(find.text('delivery_fee'.tr()), findsOneWidget);
      expect(find.text('1000 SYP'), findsOneWidget);
    });

    testWidgets('hides delivery fee when isDelivery is false', (tester) async {
      final state = MailState(
        items: [makeItem()],
        status: CartStatus.success,
        deliveryFee: 1000,
        currency: 'SYP',
      );

      await tester.pumpWidget(buildWidget(state: state, isDelivery: false));
      await tester.pumpAndSettle();

      expect(find.text('delivery_fee'.tr()), findsNothing);
    });

    testWidgets('shows correct total (subtotal + delivery)', (tester) async {
      final state = MailState(
        items: [makeItem(price: 5000, quantity: 2)],
        status: CartStatus.success,
        deliveryFee: 1000,
        currency: 'SYP',
      );

      await tester.pumpWidget(buildWidget(state: state, isDelivery: true));
      await tester.pumpAndSettle();

      expect(find.text('11000 SYP'), findsOneWidget);
    });

    testWidgets(
        'does not count the delivery fee twice when the backend sends itemsPrice',
        (tester) async {
      // انحدار: الباك يعيد itemsPrice = الأصناف فقط. قبل الإصلاح كانت الواجهة
      // تقرأ totalCartPrice (الشامل) فتضيف رسوم التوصيل مرة ثانية.
      final state = MailState(
        items: [makeItem(price: 5000, quantity: 4)],
        status: CartStatus.success,
        itemsPrice: 20000,
        deliveryFee: 1000,
        originalDeliveryFee: 1000,
        currency: 'SYP',
      );

      await tester.pumpWidget(buildWidget(state: state, isDelivery: true));
      await tester.pumpAndSettle();

      expect(find.text('20000 SYP'), findsOneWidget); // المجموع الفرعي
      expect(find.text('1000 SYP'), findsOneWidget); // رسوم التوصيل
      expect(find.text('21000 SYP'), findsOneWidget); // الإجمالي
      expect(find.text('22000 SYP'), findsNothing); // الخطأ القديم
    });

    testWidgets('shows struck-through fee and badge on free delivery',
        (tester) async {
      final state = MailState(
        items: [makeItem(price: 5000, quantity: 4)],
        status: CartStatus.success,
        itemsPrice: 20000,
        deliveryFee: 0,
        originalDeliveryFee: 1000,
        currency: 'SYP',
      );

      await tester.pumpWidget(buildWidget(state: state, isDelivery: true));
      await tester.pumpAndSettle();

      expect(find.text('delivery_fee'.tr()), findsOneWidget);
      expect(find.text('free_delivery'.tr()), findsOneWidget);

      final original = tester.widget<Text>(find.text('1000 SYP'));
      expect(original.style?.decoration, TextDecoration.lineThrough);

      // الإجمالي = الأصناف فقط بلا رسوم توصيل، فيتطابق مع المجموع الفرعي:
      // سطر الفرعي + سطر الإجمالي = نصّان بنفس القيمة.
      expect(find.text('20000 SYP'), findsNWidgets(2));
      expect(find.text('21000 SYP'), findsNothing);
    });

    testWidgets('displays complete order button', (tester) async {
      final state = MailState(
        items: [makeItem()],
        status: CartStatus.success,
        currency: 'SYP',
      );

      await tester.pumpWidget(buildWidget(state: state));
      await tester.pumpAndSettle();

      expect(find.text('complete_order'.tr()), findsOneWidget);
    });

    testWidgets('button is disabled when status is loading', (tester) async {
      final state = MailState(
        items: [makeItem()],
        status: CartStatus.loading,
        currency: 'SYP',
      );

      await tester.pumpWidget(buildWidget(state: state));
      await tester.pump(); // don't pumpAndSettle — CircularProgressIndicator is infinite

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('shows currency as ل.س when currency is empty', (tester) async {
      final state = MailState(
        items: [makeItem(price: 3000, quantity: 1)],
        status: CartStatus.success,
        currency: '',
      );

      await tester.pumpWidget(buildWidget(state: state));
      await tester.pumpAndSettle();

      // subtotal=3000, no delivery → total=3000, appears in both rows
      expect(find.text('3000 ل.س'), findsWidgets);
    });

    testWidgets('renders without overflow', (tester) async {
      final state = MailState(
        items: [
          makeItem(title: 'Pizza', price: 5000, quantity: 3),
          makeItem(id: 'item_2', title: 'Burger', price: 3000, quantity: 2),
        ],
        status: CartStatus.success,
        deliveryFee: 1500,
        currency: 'SYP',
      );

      await tester.pumpWidget(buildWidget(state: state));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('includes tax in total when taxBreakdown has totalTax',
        (tester) async {
      final state = MailState(
        items: [makeItem(price: 10000, quantity: 1)],
        status: CartStatus.success,
        taxBreakdown: {'totalTax': 1900.0},
        currency: 'EUR',
      );

      await tester.pumpWidget(buildWidget(state: state));
      await tester.pumpAndSettle();

      // 10000 + 0 (no delivery) + 1900 = 11900.
      // التوقّع كان "11900 EUR" وهو سابق لفرع اليورو في _formatPrice، الذي
      // يُنتج "11900.00 €" لأي عملة EUR/€.
      expect(find.text('11900.00 €'), findsOneWidget);
    });
  });
}

class MockAuthService extends Mock implements AuthService {}

class _MockLocationBloc extends LocationBloc {
  _MockLocationBloc() : super(MockAuthService());
}
