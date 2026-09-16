import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:nomnow_app/core/network/app_error.dart';
import 'package:nomnow_app/features/cart/presentation/bloc/mail_bloc.dart';
import 'package:nomnow_app/features/cart/presentation/bloc/mail_event.dart';
import 'package:nomnow_app/features/cart/presentation/bloc/mail_state.dart';
import 'package:nomnow_app/features/cart/data/repositories/cart_repository.dart';
import 'package:nomnow_app/features/cart/domain/models/mail_item.dart';
import 'package:nomnow_app/features/orders/data/repositories/order_repository.dart';

class MockCartRepository extends Mock implements CartRepository {}

class MockOrderRepository extends Mock implements OrderRepository {}

void main() {
  late MockCartRepository mockCartRepo;
  late MockOrderRepository mockOrderRepo;

  setUpAll(() {
    registerFallbackValue(
      const MailItem(
        id: '', foodId: '', restaurantId: '',
        title: '', price: 0, quantity: 1, imagePath: '',
      ),
    );
  });

  setUp(() {
    mockCartRepo = MockCartRepository();
    mockOrderRepo = MockOrderRepository();
  });

  MailBloc createBloc() => MailBloc(
        cartRepository: mockCartRepo,
        orderRepository: mockOrderRepo,
      );

  MailItem makeItem({
    String id = 'item_1',
    String foodId = 'food_1',
    String restaurantId = 'rest_1',
    String title = 'Pizza',
    double price = 5000,
    int quantity = 1,
  }) =>
      MailItem(
        id: id,
        foodId: foodId,
        restaurantId: restaurantId,
        title: title,
        price: price,
        quantity: quantity,
        imagePath: '',
      );

  /// يحاكي شكل رد getCart في الباك: itemsPrice = الأصناف فقط،
  /// و totalCartPrice = الأصناف + التوصيل.
  Map<String, dynamic> cartResponse({
    List<Map<String, dynamic>>? items,
    double totalPrice = 0,
    String currency = 'SYP',
    double deliveryFee = 0,
    double? originalDeliveryFee,
  }) {
    return {
      'cart': {
        'restaurantId': 'rest_1',
        'itemsPrice': totalPrice,
        'totalCartPrice': totalPrice + deliveryFee,
        'currency': currency,
        'deliveryFee': deliveryFee,
        'originalDeliveryFee': originalDeliveryFee ?? deliveryFee,
        'items': items ?? [],
      },
    };
  }

  Map<String, dynamic> cartItemJson({
    String id = 'item_1',
    String name = 'Pizza',
    double basePrice = 5000,
    int quantity = 1,
  }) {
    return {
      '_id': id,
      'foodId': 'food_1',
      'name': name,
      'basePrice': basePrice,
      'quantity': quantity,
      'image': 'https://example.com/pizza.jpg',
      'extras': [],
      'notes': '',
    };
  }

  group('MailBloc — UpdateCartItemEvent', () {
    blocTest<MailBloc, MailState>(
      'optimistic update: changes quantity locally before server call',
      build: () {
        when(() => mockCartRepo.updateCartItem(
              itemId: any(named: 'itemId'),
              quantity: any(named: 'quantity'),
            )).thenAnswer((_) async => {'cart': {}});
        return createBloc();
      },
      seed: () => MailState(
        orders: [],
        status: CartStatus.success,
        items: [makeItem(quantity: 2)],
        itemsPrice: 10000,
        currency: 'SYP',
      ),
      act: (bloc) => bloc.add(
        UpdateCartItemEvent(itemId: 'item_1', quantity: 3),
      ),
      expect: () => [
        isA<MailState>()
            .having((s) => s.items.first.quantity, 'quantity', 3)
            .having((s) => s.status, 'status', CartStatus.success),
      ],
    );

    blocTest<MailBloc, MailState>(
      'does not change quantity of different items',
      build: () {
        when(() => mockCartRepo.updateCartItem(
              itemId: any(named: 'itemId'),
              quantity: any(named: 'quantity'),
            )).thenAnswer((_) async => {'cart': {}});
        return createBloc();
      },
      seed: () => MailState(
        orders: [],
        status: CartStatus.success,
        items: [
          makeItem(id: 'item_1', title: 'Pizza', quantity: 2),
          makeItem(id: 'item_2', title: 'Burger', quantity: 1),
        ],
      ),
      act: (bloc) => bloc.add(
        UpdateCartItemEvent(itemId: 'item_1', quantity: 5),
      ),
      expect: () => [
        isA<MailState>()
            .having((s) => s.items[0].quantity, 'item1 qty', 5)
            .having((s) => s.items[1].quantity, 'item2 qty', 1),
      ],
    );

    blocTest<MailBloc, MailState>(
      'FetchCartEvent after debounce call',
      build: () {
        when(() => mockCartRepo.updateCartItem(
              itemId: any(named: 'itemId'),
              quantity: any(named: 'quantity'),
            )).thenAnswer((_) async => {'cart': {}});
        when(() => mockCartRepo.getCart()).thenAnswer(
          (_) async => cartResponse(items: [
            cartItemJson(quantity: 3),
          ], totalPrice: 15000),
        );
        return createBloc();
      },
      seed: () => MailState(
        orders: [],
        status: CartStatus.success,
        items: [makeItem(quantity: 2)],
        itemsPrice: 10000,
        currency: 'SYP',
      ),
      act: (bloc) async {
        bloc.add(UpdateCartItemEvent(itemId: 'item_1', quantity: 3));
        await Future.delayed(const Duration(milliseconds: 600));
      },
      verify: (bloc) {
        verify(() => mockCartRepo.updateCartItem(
              itemId: 'item_1',
              quantity: 3,
            )).called(1);
      },
    );

    blocTest<MailBloc, MailState>(
      'debounce: multiple rapid updates only call server once',
      build: () {
        when(() => mockCartRepo.updateCartItem(
              itemId: any(named: 'itemId'),
              quantity: any(named: 'quantity'),
            )).thenAnswer((_) async => {'cart': {}});
        when(() => mockCartRepo.getCart()).thenAnswer(
          (_) async => cartResponse(items: [cartItemJson(quantity: 5)]),
        );
        return createBloc();
      },
      seed: () => MailState(
        orders: [],
        status: CartStatus.success,
        items: [makeItem(quantity: 1)],
      ),
      act: (bloc) async {
        bloc.add(UpdateCartItemEvent(itemId: 'item_1', quantity: 2));
        await Future.delayed(const Duration(milliseconds: 100));
        bloc.add(UpdateCartItemEvent(itemId: 'item_1', quantity: 3));
        await Future.delayed(const Duration(milliseconds: 100));
        bloc.add(UpdateCartItemEvent(itemId: 'item_1', quantity: 4));
        await Future.delayed(const Duration(milliseconds: 600));
      },
      verify: (bloc) {
        verify(() => mockCartRepo.updateCartItem(
              itemId: any(named: 'itemId'),
              quantity: any(named: 'quantity'),
            )).called(1);
      },
    );

    // كان المؤقّت يستدعي `emit` بعد انتهاء المعالج المتزامن فيرمي bloc 9
    // StateError، فلا يحدث الرجوع وتبقى الكمية المتفائلة مخالفةً للخادم.
    // صار المؤقّت يرسل CartItemUpdateFailedEvent، فالرجوع يتمّ في معالج له
    // emit صالح. ينتظر هذا الاختبار ما بعد التأجيل (400ms) ليقيس النتيجة
    // فعلاً — الاختبار السابق كان يُغلق البلوك قبلها فلا يُنفّذ المسار أصلاً.
    test('يرجع إلى الكمية الأصلية عند فشل الخادم', () async {
      when(() => mockCartRepo.updateCartItem(
            itemId: any(named: 'itemId'),
            quantity: any(named: 'quantity'),
          )).thenThrow(ApiException(
        AppError.ofKind(AppErrorKind.server),
      ));

      final bloc = createBloc();
      bloc.emit(const MailState(
        orders: [],
        status: CartStatus.success,
        items: [MailItem(
          id: 'item_1', foodId: 'food_1', restaurantId: 'rest_1',
          title: 'Pizza', price: 5000, quantity: 2, imagePath: '',
        )],
      ));

      bloc.add(const UpdateCartItemEvent(itemId: 'item_1', quantity: 5));

      // التحديث المتفائل فوري
      await Future.delayed(const Duration(milliseconds: 100));
      expect(bloc.state.items.first.quantity, 5);

      // بعد انقضاء التأجيل وفشل الخادم تعود الكمية إلى 2
      await Future.delayed(const Duration(milliseconds: 500));
      expect(bloc.state.items.first.quantity, 2,
          reason: 'يجب أن يرجع الرجوع الكمية إلى ما كانت عليه');

      await bloc.close();
    });

    // كان تحديث الكمية `DELETE` ثم `POST`، وحذف آخر عنصر يحذف وثيقة السلة
    // ومعها الكوبون — فكان البلوك يُعيد تطبيقه بعد كل تعديل. `PATCH` يعدّل
    // العنصر بمكانه، فأيّ نداء كوبون هنا صار زائداً.
    test('لا يعيد تطبيق الكوبون بعد تحديث الكمية', () async {
      when(() => mockCartRepo.updateCartItem(
            itemId: any(named: 'itemId'),
            quantity: any(named: 'quantity'),
          )).thenAnswer((_) async => {'cart': {}});
      when(() => mockCartRepo.getCart())
          .thenAnswer((_) async => cartResponse(items: [cartItemJson()]));

      final bloc = createBloc();
      bloc.emit(MailState(
        orders: const [],
        status: CartStatus.success,
        items: [makeItem(quantity: 2)],
        couponCode: 'SAVE10',
      ));

      bloc.add(const UpdateCartItemEvent(itemId: 'item_1', quantity: 4));
      await Future.delayed(const Duration(milliseconds: 600));

      verify(() => mockCartRepo.updateCartItem(itemId: 'item_1', quantity: 4))
          .called(1);
      verifyNever(() => mockCartRepo.applyCoupon(code: any(named: 'code')));

      await bloc.close();
    });
  });

  group('MailBloc — ClearCartEvent', () {
    blocTest<MailBloc, MailState>(
      'calls clearCart on repository and resets state',
      build: () {
        when(() => mockCartRepo.clearCart()).thenAnswer((_) async {});
        return createBloc();
      },
      seed: () => MailState(
        orders: [],
        items: [
          makeItem(quantity: 2),
          makeItem(id: 'item_2', title: 'Burger', quantity: 1),
        ],
        status: CartStatus.success,
        itemsPrice: 15000,
        currency: 'SYP',
      ),
      act: (bloc) => bloc.add(ClearCartEvent()),
      expect: () => [
        isA<MailState>()
            .having((s) => s.items.length, 'items length', 0)
            .having((s) => s.status, 'status', CartStatus.initial)
            .having(
                (s) => s.itemsPrice, 'itemsPrice', 0),
      ],
      verify: (bloc) {
        verify(() => mockCartRepo.clearCart()).called(1);
      },
    );

    blocTest<MailBloc, MailState>(
      'still resets state even if clearCart throws',
      build: () {
        when(() => mockCartRepo.clearCart())
            .thenThrow(Exception('Network error'));
        return createBloc();
      },
      seed: () => MailState(
        orders: [],
        items: [makeItem()],
        status: CartStatus.success,
        itemsPrice: 5000,
      ),
      act: (bloc) => bloc.add(ClearCartEvent()),
      expect: () => [
        isA<MailState>()
            .having((s) => s.items.length, 'items', 0)
            .having((s) => s.status, 'status', CartStatus.initial)
            .having((s) => s.itemsPrice, 'itemsPrice', 0),
      ],
    );
  });

  group('MailBloc — RemoveItemEvent', () {
    blocTest<MailBloc, MailState>(
      'calls removeFromCart and triggers FetchCartEvent',
      build: () {
        when(() => mockCartRepo.removeFromCart(itemId: any(named: 'itemId')))
            .thenAnswer((_) async => {});
        when(() => mockCartRepo.getCart()).thenAnswer(
          (_) async => cartResponse(items: []),
        );
        return createBloc();
      },
      seed: () => MailState(
        orders: [],
        status: CartStatus.success,
        items: [makeItem()],
      ),
      act: (bloc) => bloc.add(
        RemoveItemEvent(id: 'item_1', restaurantId: 'rest_1'),
      ),
      expect: () => [
        isA<MailState>().having((s) => s.status, 'status', CartStatus.loading),
        isA<MailState>().having((s) => s.items.length, 'items', 0),
      ],
      verify: (bloc) {
        verify(() => mockCartRepo.removeFromCart(itemId: 'item_1')).called(1);
      },
    );

    blocTest<MailBloc, MailState>(
      'emits error when removeFromCart throws',
      build: () {
        when(() => mockCartRepo.removeFromCart(itemId: any(named: 'itemId')))
            .thenThrow(Exception('Delete failed'));
        return createBloc();
      },
      seed: () => MailState(
        orders: [],
        status: CartStatus.success,
        items: [makeItem()],
      ),
      act: (bloc) => bloc.add(
        RemoveItemEvent(id: 'item_1', restaurantId: 'rest_1'),
      ),
      expect: () => [
        isA<MailState>().having((s) => s.status, 'status', CartStatus.loading),
        isA<MailState>().having((s) => s.status, 'status', CartStatus.error),
      ],
    );
  });

  group('MailBloc — FetchCartEvent', () {
    blocTest<MailBloc, MailState>(
      'parses cart items with size and extras correctly',
      build: () {
        when(() => mockCartRepo.getCart()).thenAnswer(
          (_) async => {
            'cart': {
              'restaurantId': 'rest_1',
              'itemsPrice': 8000,
              'totalCartPrice': 9000,
              'currency': 'SYP',
              'deliveryFee': 1000,
              'originalDeliveryFee': 1000,
              'items': [
                {
                  '_id': 'item_1',
                  'foodId': 'food_1',
                  'name': 'Burger',
                  'basePrice': 3000,
                  'quantity': 2,
                  'image': 'https://example.com/burger.jpg',
                  'extras': [
                    {'name': 'Cheese', 'price': 500},
                  ],
                  'size': {'name': 'Large', 'price': 1000},
                  'notes': 'No onions',
                },
              ],
            },
          },
        );
        return createBloc();
      },
      act: (bloc) => bloc.add(FetchCartEvent()),
      expect: () => [
        isA<MailState>().having((s) => s.status, 'status', CartStatus.loading),
        isA<MailState>()
            .having((s) => s.status, 'status', CartStatus.success)
            .having((s) => s.items.length, 'items count', 1)
            .having((s) => s.items.first.title, 'title', 'Burger')
            .having((s) => s.items.first.quantity, 'quantity', 2)
            .having((s) => s.items.first.size, 'size', 'Large')
            .having((s) => s.items.first.sizePrice, 'sizePrice', 1000)
            .having((s) => s.items.first.extras.length, 'extras count', 1)
            .having((s) => s.items.first.notes, 'notes', 'No onions')
            .having((s) => s.itemsPrice, 'itemsPrice', 8000)
            .having((s) => s.deliveryFee, 'deliveryFee', 1000)
            // الإجمالي المعروض = الأصناف + التوصيل مرة واحدة فقط
            .having((s) => s.totalAmount + s.deliveryFee, 'total', 9000),
      ],
    );

    blocTest<MailBloc, MailState>(
      'handles response without cart key (data.cart format)',
      build: () {
        when(() => mockCartRepo.getCart()).thenAnswer(
          (_) async => {
            'data': {
              'cart': {
                'restaurantId': 'rest_1',
                'itemsPrice': 5000,
                'totalCartPrice': 5000,
                'currency': 'SYP',
                'deliveryFee': 0,
                'items': [
                  {
                    '_id': 'item_1',
                    'foodId': 'food_1',
                    'name': 'Fries',
                    'basePrice': 2000,
                    'quantity': 1,
                    'image': '',
                    'extras': [],
                  },
                ],
              },
            },
          },
        );
        return createBloc();
      },
      act: (bloc) => bloc.add(FetchCartEvent()),
      expect: () => [
        isA<MailState>().having((s) => s.status, 'loading', CartStatus.loading),
        isA<MailState>()
            .having((s) => s.status, 'success', CartStatus.success)
            .having((s) => s.items.first.title, 'title', 'Fries')
            .having((s) => s.itemsPrice, 'itemsPrice', 5000),
      ],
    );

    blocTest<MailBloc, MailState>(
      'handles empty cart response',
      build: () {
        when(() => mockCartRepo.getCart()).thenAnswer(
          (_) async => {
            'cart': {
              'restaurantId': 'rest_1',
              'itemsPrice': 0,
              'totalCartPrice': 0,
              'currency': 'SYP',
              'deliveryFee': 0,
              'items': [],
            },
          },
        );
        return createBloc();
      },
      act: (bloc) => bloc.add(FetchCartEvent()),
      expect: () => [
        isA<MailState>().having((s) => s.status, 'loading', CartStatus.loading),
        isA<MailState>()
            .having((s) => s.status, 'success', CartStatus.success)
            .having((s) => s.items.length, 'items', 0),
      ],
    );

    blocTest<MailBloc, MailState>(
      'emits error on network failure',
      build: () {
        when(() => mockCartRepo.getCart()).thenThrow(Exception('timeout'));
        return createBloc();
      },
      act: (bloc) => bloc.add(FetchCartEvent()),
      expect: () => [
        isA<MailState>().having((s) => s.status, 'loading', CartStatus.loading),
        isA<MailState>()
            .having((s) => s.status, 'status', CartStatus.error)
            .having((s) => s.errorMessage, 'error msg', isNotNull),
      ],
    );
  });

  group('MailBloc — AddToCartEvent', () {
    blocTest<MailBloc, MailState>(
      'calls addToCart and then FetchCartEvent on success',
      build: () {
        when(() => mockCartRepo.addToCart(
              foodId: any(named: 'foodId'),
              quantity: any(named: 'quantity'),
              size: any(named: 'size'),
              extras: any(named: 'extras'),
              notes: any(named: 'notes'),
              restaurantId: any(named: 'restaurantId'),
            )).thenAnswer((_) async {});
        when(() => mockCartRepo.getCart()).thenAnswer(
          (_) async => cartResponse(items: [cartItemJson()]),
        );
        return createBloc();
      },
      act: (bloc) => bloc.add(AddToCartEvent(makeItem())),
      expect: () => [
        isA<MailState>().having((s) => s.status, 'loading', CartStatus.loading),
        isA<MailState>()
            .having((s) => s.status, 'success', CartStatus.success)
            .having((s) => s.items.length, 'items', 1),
      ],
      verify: (bloc) {
        verify(() => mockCartRepo.addToCart(
              foodId: 'food_1',
              quantity: 1,
              size: null,
              extras: [],
              notes: '',
              restaurantId: 'rest_1',
            )).called(1);
      },
    );

    blocTest<MailBloc, MailState>(
      'emits error when addToCart throws',
      build: () {
        when(() => mockCartRepo.addToCart(
              foodId: any(named: 'foodId'),
              quantity: any(named: 'quantity'),
              size: any(named: 'size'),
              extras: any(named: 'extras'),
              notes: any(named: 'notes'),
              restaurantId: any(named: 'restaurantId'),
            )).thenThrow(ApiException(AppError.ofKind(
          AppErrorKind.badRequest,
          serverMessage: 'Conflict: different restaurant',
        )));
        return createBloc();
      },
      act: (bloc) => bloc.add(AddToCartEvent(makeItem())),
      expect: () => [
        isA<MailState>().having((s) => s.status, 'loading', CartStatus.loading),
        isA<MailState>()
            .having((s) => s.status, 'error', CartStatus.error)
            .having((s) => s.errorMessage, 'error msg', contains('Conflict')),
      ],
    );
  });

  group('MailBloc — ClearAndAddToCartEvent', () {
    // تبديل المطعم كان تفريغاً يدوياً (عدّة نداءات حذف) ثم إضافة. صار نداءً
    // واحداً بعلم `replaceCart`، فلا توجد لحظة تكون فيها السلة نصف فارغة.
    blocTest<MailBloc, MailState>(
      'يضيف بعلم replaceCart في نداء واحد بلا تفريغ يدوي',
      build: () {
        when(() => mockCartRepo.addToCart(
              foodId: any(named: 'foodId'),
              quantity: any(named: 'quantity'),
              size: any(named: 'size'),
              extras: any(named: 'extras'),
              notes: any(named: 'notes'),
              restaurantId: any(named: 'restaurantId'),
              replaceCart: any(named: 'replaceCart'),
            )).thenAnswer((_) async {});
        when(() => mockCartRepo.getCart()).thenAnswer(
          (_) async => cartResponse(items: [cartItemJson()]),
        );
        return createBloc();
      },
      act: (bloc) => bloc.add(ClearAndAddToCartEvent(
        makeItem(id: '', foodId: 'food_2', restaurantId: 'rest_2'),
      )),
      expect: () => [
        isA<MailState>().having((s) => s.status, 'loading', CartStatus.loading),
        isA<MailState>().having((s) => s.status, 'success', CartStatus.success),
      ],
      verify: (bloc) {
        verify(() => mockCartRepo.addToCart(
              foodId: 'food_2',
              quantity: 1,
              size: null,
              extras: [],
              notes: '',
              restaurantId: 'rest_2',
              replaceCart: true,
            )).called(1);
        verifyNever(() => mockCartRepo.clearCart());
      },
    );

    blocTest<MailBloc, MailState>(
      'يُظهر رسالة الخادم عند فشل الاستبدال',
      build: () {
        when(() => mockCartRepo.addToCart(
              foodId: any(named: 'foodId'),
              quantity: any(named: 'quantity'),
              size: any(named: 'size'),
              extras: any(named: 'extras'),
              notes: any(named: 'notes'),
              restaurantId: any(named: 'restaurantId'),
              replaceCart: any(named: 'replaceCart'),
            )).thenThrow(ApiException(AppError.ofKind(
          AppErrorKind.badRequest,
          serverMessage: 'الوجبة غير متاحة حالياً',
        )));
        return createBloc();
      },
      act: (bloc) => bloc.add(ClearAndAddToCartEvent(makeItem())),
      expect: () => [
        isA<MailState>().having((s) => s.status, 'loading', CartStatus.loading),
        isA<MailState>()
            .having((s) => s.status, 'error', CartStatus.error)
            .having((s) => s.errorMessage, 'error msg', 'الوجبة غير متاحة حالياً'),
      ],
    );
  });

  group('MailBloc — MailState', () {
    test('totalAmount uses backend items price when available', () {
      const state = MailState(
        itemsPrice: 15000,
        items: [],
      );
      expect(state.totalAmount, 15000);
    });

    test('totalAmount excludes delivery fee — لا يُحتسب التوصيل مرتين', () {
      const state = MailState(
        itemsPrice: 20000,
        deliveryFee: 1000,
        originalDeliveryFee: 1000,
        items: [],
      );
      expect(state.totalAmount, 20000);
      expect(state.totalAmount + state.deliveryFee, 21000);
    });

    test('hasFreeDelivery true when fee zeroed but original kept', () {
      const state = MailState(
        itemsPrice: 20000,
        deliveryFee: 0,
        originalDeliveryFee: 1000,
        items: [],
      );
      expect(state.hasFreeDelivery, isTrue);
      expect(state.totalAmount + state.deliveryFee, 20000);
    });

    test('hasFreeDelivery false without a promotion', () {
      const withFee = MailState(
        itemsPrice: 20000,
        deliveryFee: 1000,
        originalDeliveryFee: 1000,
        items: [],
      );
      const emptyCart = MailState(items: []);
      expect(withFee.hasFreeDelivery, isFalse);
      expect(emptyCart.hasFreeDelivery, isFalse);
    });

    test('totalAmount calculates from items when no backend price', () {
      final state = MailState(
        items: [
          makeItem(price: 5000, quantity: 2),
          makeItem(id: 'item_2', price: 3000, quantity: 1),
        ],
      );
      expect(state.totalAmount, 13000);
    });

    test('copyWith creates correct copy', () {
      const original = MailState(
        items: [],
        orders: [],
        status: CartStatus.initial,
        itemsPrice: 5000,
        currency: 'SYP',
        deliveryFee: 1000,
      );

      final copy = original.copyWith(
        status: CartStatus.success,
        items: [makeItem()],
      );

      expect(copy.status, CartStatus.success);
      expect(copy.items.length, 1);
      expect(copy.itemsPrice, 5000);
      expect(copy.currency, 'SYP');
      expect(copy.deliveryFee, 1000);
    });

    test('equality works correctly', () {
      const a = MailState(
        items: [],
        status: CartStatus.initial,
        itemsPrice: 5000,
      );
      const b = MailState(
        items: [],
        status: CartStatus.initial,
        itemsPrice: 5000,
      );
      expect(a, equals(b));
    });

    test('inequality works correctly', () {
      const a = MailState(status: CartStatus.initial);
      const b = MailState(status: CartStatus.error);
      expect(a, isNot(equals(b)));
    });
  });

  group('MailBloc — ApplyCouponEvent', () {
    blocTest<MailBloc, MailState>(
      'calls applyCoupon with the code then refetches the cart',
      build: () {
        when(() => mockCartRepo.applyCoupon(code: any(named: 'code')))
            .thenAnswer((_) async => {});
        when(() => mockCartRepo.getCart()).thenAnswer(
          (_) async => cartResponse(items: [], totalPrice: 8000),
        );
        return createBloc();
      },
      act: (bloc) => bloc.add(const ApplyCouponEvent(code: 'SAVE10')),
      expect: () => [
        isA<MailState>().having((s) => s.status, 'loading', CartStatus.loading),
        isA<MailState>()
            .having((s) => s.status, 'success', CartStatus.success),
      ],
      verify: (bloc) {
        verify(() => mockCartRepo.applyCoupon(code: 'SAVE10')).called(1);
      },
    );

    blocTest<MailBloc, MailState>(
      'emits error with the server message when applyCoupon throws',
      build: () {
        when(() => mockCartRepo.applyCoupon(code: any(named: 'code')))
            .thenThrow(ApiException(AppError.ofKind(
          AppErrorKind.badRequest,
          serverMessage: 'Insufficient order value',
        )));
        return createBloc();
      },
      act: (bloc) => bloc.add(const ApplyCouponEvent(code: 'SAVE10')),
      expect: () => [
        isA<MailState>().having((s) => s.status, 'loading', CartStatus.loading),
        isA<MailState>()
            .having((s) => s.status, 'status', CartStatus.error)
            .having((s) => s.errorMessage, 'error msg',
                contains('Insufficient order value')),
      ],
    );

    blocTest<MailBloc, MailState>(
      'persists coupon fields returned by the cart refetch',
      build: () {
        when(() => mockCartRepo.applyCoupon(code: any(named: 'code')))
            .thenAnswer((_) async => {});
        when(() => mockCartRepo.getCart()).thenAnswer(
          (_) async => {
            'cart': {
              'restaurantId': 'rest_1',
              'itemsPrice': 8000,
              'totalCartPrice': 7500,
              'currency': 'SYP',
              'deliveryFee': 0,
              'originalDeliveryFee': 0,
              'couponCode': 'SAVE10',
              'couponType': 'percentage',
              'couponDiscount': 500,
              'items': [],
            },
          },
        );
        return createBloc();
      },
      act: (bloc) => bloc.add(const ApplyCouponEvent(code: 'SAVE10')),
      expect: () => [
        isA<MailState>().having((s) => s.status, 'loading', CartStatus.loading),
        isA<MailState>()
            .having((s) => s.status, 'success', CartStatus.success)
            .having((s) => s.hasCoupon, 'hasCoupon', true)
            .having((s) => s.couponCode, 'couponCode', 'SAVE10')
            .having((s) => s.couponType, 'couponType', 'percentage')
            .having((s) => s.couponDiscount, 'couponDiscount', 500.0),
      ],
    );
  });

  group('MailBloc — RemoveCouponEvent', () {
    blocTest<MailBloc, MailState>(
      'calls removeCoupon then refetches the cart',
      build: () {
        when(() => mockCartRepo.removeCoupon()).thenAnswer((_) async => {});
        when(() => mockCartRepo.getCart()).thenAnswer(
          (_) async => cartResponse(items: [], totalPrice: 8000),
        );
        return createBloc();
      },
      seed: () => MailState(
        orders: [],
        status: CartStatus.success,
        couponCode: 'SAVE10',
        couponType: 'percentage',
        couponDiscount: 500,
      ),
      act: (bloc) => bloc.add(RemoveCouponEvent()),
      expect: () => [
        isA<MailState>().having((s) => s.status, 'loading', CartStatus.loading),
        isA<MailState>()
            .having((s) => s.status, 'success', CartStatus.success)
            .having((s) => s.hasCoupon, 'hasCoupon', false),
      ],
      verify: (bloc) {
        verify(() => mockCartRepo.removeCoupon()).called(1);
      },
    );

    blocTest<MailBloc, MailState>(
      'emits error with the server message when removeCoupon throws',
      build: () {
        when(() => mockCartRepo.removeCoupon())
            .thenThrow(ApiException(AppError.ofKind(
          AppErrorKind.badRequest,
          serverMessage: 'Coupon removal failed',
        )));
        return createBloc();
      },
      act: (bloc) => bloc.add(RemoveCouponEvent()),
      expect: () => [
        isA<MailState>().having((s) => s.status, 'loading', CartStatus.loading),
        isA<MailState>()
            .having((s) => s.status, 'status', CartStatus.error)
            .having((s) => s.errorMessage, 'error msg',
                contains('Coupon removal failed')),
      ],
    );
  });
}
