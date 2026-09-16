import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nomnow_app/features/cart/presentation/widgets/cart_items_list.dart';
import 'package:nomnow_app/features/cart/presentation/bloc/mail_bloc.dart';
import 'package:nomnow_app/features/cart/presentation/bloc/mail_state.dart';
import 'package:nomnow_app/features/cart/data/repositories/cart_repository.dart';
import 'package:nomnow_app/features/orders/data/repositories/order_repository.dart';
import 'package:nomnow_app/features/cart/domain/models/mail_item.dart';

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
    String imagePath = '',
    List<Map<String, dynamic>> extras = const [],
    String? size,
  }) =>
      MailItem(
        id: id,
        foodId: 'food_1',
        restaurantId: 'rest_1',
        title: title,
        price: price,
        quantity: quantity,
        imagePath: imagePath,
        extras: extras,
        size: size,
      );

  Widget buildWidget({
    required List<MailItem> items,
    String currency = 'SYP',
    CartStatus status = CartStatus.success,
  }) {
    return EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: BlocProvider<MailBloc>(
              create: (_) => MailBloc(
                cartRepository: mockCartRepo,
                orderRepository: mockOrderRepo,
              ),
              child: CartItemsList(
                items: items,
                currency: currency,
                status: status,
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('CartItemsList', () {
    testWidgets('renders all items in the list', (tester) async {
      final items = [
        makeItem(title: 'Pizza', price: 5000, quantity: 2),
        makeItem(id: 'item_2', title: 'Burger', price: 3000, quantity: 1),
      ];

      await tester.pumpWidget(buildWidget(items: items));
      await tester.pumpAndSettle();

      expect(find.text('Pizza'), findsOneWidget);
      expect(find.text('Burger'), findsOneWidget);
    });

    testWidgets('displays item title with bold font', (tester) async {
      final items = [makeItem(title: 'Shawarma')];

      await tester.pumpWidget(buildWidget(items: items));
      await tester.pumpAndSettle();

      final titleWidget = tester.widget<Text>(find.text('Shawarma'));
      expect(titleWidget.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('shows quantity number', (tester) async {
      final items = [makeItem(quantity: 3)];

      await tester.pumpWidget(buildWidget(items: items));
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows delete icon', (tester) async {
      final items = [makeItem()];

      await tester.pumpWidget(buildWidget(items: items));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('shows add icon', (tester) async {
      final items = [makeItem()];

      await tester.pumpWidget(buildWidget(items: items));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows minus icon when quantity > 1', (tester) async {
      final items = [makeItem(quantity: 3)];

      await tester.pumpWidget(buildWidget(items: items));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.remove), findsOneWidget);
    });

    testWidgets('shows delete icon as minus when quantity == 1', (tester) async {
      final items = [makeItem(quantity: 1)];

      await tester.pumpWidget(buildWidget(items: items));
      await tester.pumpAndSettle();

      // quantity 1 → shows delete_outline instead of remove
      final deleteIcons = tester.widgetList<Icon>(find.byIcon(Icons.delete_outline));
      expect(deleteIcons.length, greaterThanOrEqualTo(1));
    });

    testWidgets('displays size text when item has size', (tester) async {
      final items = [makeItem(size: 'Large')];

      await tester.pumpWidget(buildWidget(items: items));
      await tester.pumpAndSettle();

      expect(find.text('units.size_Large'.tr()), findsOneWidget);
    });

    testWidgets('hides size text when item has no size', (tester) async {
      final items = [makeItem(size: null)];

      await tester.pumpWidget(buildWidget(items: items));
      await tester.pumpAndSettle();

      expect(find.textContaining('units.size_'), findsNothing);
    });

    testWidgets('displays price with SYP currency', (tester) async {
      final items = [makeItem(price: 5000, quantity: 2)];

      await tester.pumpWidget(buildWidget(items: items, currency: 'SYP'));
      await tester.pumpAndSettle();

      expect(find.text('5000 SYP'), findsOneWidget);
    });

    testWidgets('displays price with EUR currency', (tester) async {
      final items = [makeItem(price: 12.50, quantity: 1)];

      await tester.pumpWidget(buildWidget(items: items, currency: 'EUR'));
      await tester.pumpAndSettle();

      expect(find.text('12.50 €'), findsOneWidget);
    });

    testWidgets('renders empty list without errors', (tester) async {
      await tester.pumpWidget(buildWidget(items: []));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders multiple items without overflow', (tester) async {
      final items = List.generate(
        5,
        (i) => makeItem(
          id: 'item_$i',
          title: 'Meal $i',
          price: 1000 * (i + 1),
          quantity: i + 1,
        ),
      );

      await tester.pumpWidget(buildWidget(items: items));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('disables delete when status is loading', (tester) async {
      final items = [makeItem()];

      await tester.pumpWidget(
        buildWidget(items: items, status: CartStatus.loading),
      );
      await tester.pumpAndSettle();

      final iconButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.delete_outline),
          matching: find.byType(IconButton),
        ),
      );
      expect(iconButton.onPressed, isNull);
    });
  });
}
