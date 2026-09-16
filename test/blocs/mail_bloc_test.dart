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
import 'package:nomnow_app/core/services/socket_service.dart';
import 'package:nomnow_app/features/location/data/models/address_model.dart';

class MockCartRepository extends Mock implements CartRepository {}
class MockOrderRepository extends Mock implements OrderRepository {}
class MockSocketService extends Mock implements SocketService {}

void main() {
  late MockCartRepository mockCartRepo;
  late MockOrderRepository mockOrderRepo;

  setUp(() {
    mockCartRepo = MockCartRepository();
    mockOrderRepo = MockOrderRepository();
  });

  group('MailBloc', () {
    blocTest<MailBloc, MailState>(
      'emits [loading, success] when FetchCartEvent succeeds with items',
      setUp: () {
        when(() => mockCartRepo.getCart()).thenAnswer((_) async => {
          'cart': {
            'restaurantId': 'rest_1',
            // الباك يعيد itemsPrice (الأصناف فقط) و totalCartPrice (شامل التوصيل)
            'itemsPrice': 10000,
            'totalCartPrice': 11000,
            'currency': 'SYP',
            'deliveryFee': 1000,
            'originalDeliveryFee': 1000,
            'items': [
              {
                '_id': 'item_1',
                'foodId': 'food_1',
                'name': 'Pizza',
                'basePrice': 5000,
                'quantity': 2,
                'image': 'https://example.com/pizza.jpg',
                'extras': [],
                'notes': '',
              }
            ],
          },
        });
      },
      build: () => MailBloc(
        cartRepository: mockCartRepo,
        orderRepository: mockOrderRepo,
      ),
      act: (bloc) => bloc.add(FetchCartEvent()),
      expect: () => [
        MailState(orders: [], status: CartStatus.loading),
        MailState(
          orders: [],
          status: CartStatus.success,
          items: [
            MailItem(
              id: 'item_1', foodId: 'food_1', restaurantId: 'rest_1',
              title: 'Pizza', price: 5000, quantity: 2,
              imagePath: 'https://example.com/pizza.jpg',
              extras: [], notes: '',
            ),
          ],
          itemsPrice: 10000,
          currency: 'SYP',
          deliveryFee: 1000,
          originalDeliveryFee: 1000,
        ),
      ],
    );

    blocTest<MailBloc, MailState>(
      'emits [loading, error] when FetchCartEvent fails',
      setUp: () {
        when(() => mockCartRepo.getCart()).thenThrow(Exception('Network error'));
      },
      build: () => MailBloc(
        cartRepository: mockCartRepo,
        orderRepository: mockOrderRepo,
      ),
      act: (bloc) => bloc.add(FetchCartEvent()),
      expect: () => [
        MailState(orders: [], status: CartStatus.loading),
        // لا تهيئة EasyLocalization في هذا الملف، فـ tr() تُرجع المفتاح الخام
        MailState(orders: [], status: CartStatus.error, errorMessage: 'error_fetching_cart'),
      ],
    );

    blocTest<MailBloc, MailState>(
      'emits [loading, success] when AddToCartEvent succeeds',
      setUp: () {
        when(() => mockCartRepo.addToCart(
          foodId: any(named: 'foodId'),
          quantity: any(named: 'quantity'),
          size: any(named: 'size'),
          extras: any(named: 'extras'),
          notes: any(named: 'notes'),
          restaurantId: any(named: 'restaurantId'),
        )).thenAnswer((_) async {});
        when(() => mockCartRepo.getCart()).thenAnswer((_) async => {
          'cart': {'items': [], 'itemsPrice': 0, 'totalCartPrice': 0, 'currency': 'SYP', 'deliveryFee': 0},
        });
      },
      build: () => MailBloc(
        cartRepository: mockCartRepo,
        orderRepository: mockOrderRepo,
      ),
      act: (bloc) => bloc.add(
        AddToCartEvent(const MailItem(
          id: 'new_item', foodId: 'food_1', restaurantId: 'rest_1',
          title: 'Burger', price: 3000, quantity: 1, imagePath: '',
        )),
      ),
      expect: () => [
        MailState(orders: [], status: CartStatus.loading),
        MailState(orders: [], status: CartStatus.success, items: [],
            itemsPrice: 0, currency: 'SYP', deliveryFee: 0),
      ],
    );

    blocTest<MailBloc, MailState>(
      'AddToCartEvent يُظهر رسالة الخادم كما هي',
      setUp: () {
        when(() => mockCartRepo.addToCart(
          foodId: any(named: 'foodId'),
          quantity: any(named: 'quantity'),
          size: any(named: 'size'),
          extras: any(named: 'extras'),
          notes: any(named: 'notes'),
          restaurantId: any(named: 'restaurantId'),
        )).thenThrow(ApiException(AppError.ofKind(
          AppErrorKind.badRequest,
          serverMessage: 'السلة تحتوي على طعام من مطعم آخر',
        )));
      },
      build: () => MailBloc(
        cartRepository: mockCartRepo,
        orderRepository: mockOrderRepo,
      ),
      act: (bloc) => bloc.add(
        AddToCartEvent(const MailItem(
          id: 'i1', foodId: 'f1', restaurantId: 'r1',
          title: 'T', price: 100, quantity: 1, imagePath: '',
        )),
      ),
      expect: () => [
        MailState(orders: [], status: CartStatus.loading),
        // كانت الرسالة تُستبدل بـ errors.unknown_msg لأن المستودع كان يلفّ
        // الخطأ في Exception عادي فيفقد AppError تصنيفه
        MailState(orders: [], status: CartStatus.error,
            errorMessage: 'السلة تحتوي على طعام من مطعم آخر'),
      ],
    );

    blocTest<MailBloc, MailState>(
      'emits [loading, success] when RemoveItemEvent succeeds',
      setUp: () {
        when(() => mockCartRepo.removeFromCart(itemId: any(named: 'itemId')))
            .thenAnswer((_) async => {});
        when(() => mockCartRepo.getCart()).thenAnswer((_) async => {
          'cart': {'items': [], 'itemsPrice': 0, 'totalCartPrice': 0, 'currency': 'SYP', 'deliveryFee': 0},
        });
      },
      build: () => MailBloc(
        cartRepository: mockCartRepo,
        orderRepository: mockOrderRepo,
      ),
      seed: () => MailState(
        orders: [],
        items: [
          const MailItem(id: 'item_1', foodId: 'f1', restaurantId: 'r1',
              title: 'Pizza', price: 5000, quantity: 1, imagePath: ''),
        ],
        status: CartStatus.success,
      ),
      act: (bloc) => bloc.add(RemoveItemEvent(id: 'item_1', restaurantId: 'r1')),
      expect: () => [
        MailState(
          orders: [],
          items: [const MailItem(id: 'item_1', foodId: 'f1', restaurantId: 'r1',
              title: 'Pizza', price: 5000, quantity: 1, imagePath: '')],
          status: CartStatus.loading,
        ),
        MailState(orders: [], status: CartStatus.success, items: [],
            itemsPrice: 0, currency: 'SYP', deliveryFee: 0),
      ],
    );

    blocTest<MailBloc, MailState>(
      'emits [initial] on ClearCartEvent',
      build: () => MailBloc(
        cartRepository: mockCartRepo,
        orderRepository: mockOrderRepo,
      ),
      seed: () => MailState(
        orders: [],
        items: [const MailItem(id: 'i1', foodId: 'f1', restaurantId: 'r1',
            title: 'T', price: 100, quantity: 1, imagePath: '')],
        status: CartStatus.success,
        itemsPrice: 5000,
        deliveryFee: 1000,
        originalDeliveryFee: 1000,
      ),
      act: (bloc) => bloc.add(ClearCartEvent()),
      expect: () => [
        MailState(
            orders: [],
            items: [],
            status: CartStatus.initial,
            itemsPrice: 0,
            deliveryFee: 0,
            originalDeliveryFee: 0),
      ],
    );

    // v4.2 — `order:cartChanged` يُبثّ بدل `order:sent` حين تتغيّر السلة بين
    // إنشاء الطلب وإرساله. بلا مستمع له يبقى الـ Completer معلّقاً حتى تنتهي
    // مهلة العشرين ثانية — وهذا الاختبار يمسك ذلك التعليق بمهلة أقصر بكثير.
    test('order:cartChanged يُنهي الانتظار فوراً بلا مهلة العشرين ثانية',
        () async {
      final socket = MockSocketService();
      void Function(Map<String, dynamic>)? cartChangedCb;

      when(() => socket.isConnected).thenReturn(true);
      when(() => socket.listenToOrderSent(any())).thenReturn(null);
      when(() => socket.listenToPromotionExpired(any())).thenReturn(null);
      when(() => socket.listenToErrors(any())).thenReturn(null);
      when(() => socket.removeCheckoutListeners()).thenReturn(null);
      when(() => socket.listenToCartChanged(any())).thenAnswer((i) {
        cartChangedCb = i.positionalArguments.first
            as void Function(Map<String, dynamic>);
      });
      when(() => socket.sendOrderToRestaurant(any(),
          paymentIntentId: any(named: 'paymentIntentId'))).thenAnswer((_) {
        // الباك يبثّ cartChanged بدل order:sent
        cartChangedCb?.call(const {'message': 'cart changed'});
        return true;
      });

      when(() => mockOrderRepo.createOrder(
            deliveryAddress: any(named: 'deliveryAddress'),
            notes: any(named: 'notes'),
            paymentMethod: any(named: 'paymentMethod'),
          )).thenAnswer((_) async => {'order': {'_id': 'ord_1'}});
      when(() => mockCartRepo.getCart()).thenAnswer((_) async => {'cart': null});
      when(() => mockOrderRepo.getUserOrders()).thenAnswer((_) async => []);

      final bloc = MailBloc(
        cartRepository: mockCartRepo,
        orderRepository: mockOrderRepo,
        socketService: socket,
      );
      bloc.emit(const MailState(
        orders: [],
        status: CartStatus.success,
        items: [MailItem(
          id: 'i1', foodId: 'f1', restaurantId: 'r1',
          title: 'T', price: 100, quantity: 1, imagePath: '',
        )],
      ));

      final sw = Stopwatch()..start();
      bloc.add(ConfirmOrderEvent(
        deliveryAddress: AddressModel(
          addressName: 'Home', country: 'SY', city: 'D',
          area: 'A', streetChoice: 'S', buildingDetail: 'B',
        ),
        notes: '',
      ));

      await bloc.stream.firstWhere((s) => s.status == CartStatus.error)
          .timeout(const Duration(seconds: 3));
      sw.stop();

      expect(bloc.state.errorMessage, 'cart_changed_during_checkout');
      expect(sw.elapsed.inSeconds, lessThan(3),
          reason: 'يجب ألّا ينتظر مهلة العشرين ثانية');

      await bloc.close();
    });

    blocTest<MailBloc, MailState>(
      'ConfirmOrderEvent لا يفعل شيئاً والسلة فارغة',
      build: () => MailBloc(
        cartRepository: mockCartRepo,
        orderRepository: mockOrderRepo,
      ),
      act: (bloc) {
        final address = AddressModel(
          addressName: 'Home', country: 'SY', city: 'D',
          area: 'A', streetChoice: 'S', buildingDetail: 'B',
        );
        bloc.add(ConfirmOrderEvent(deliveryAddress: address, notes: 'Fast'));
      },
      expect: () => [],
      verify: (_) {
        verifyNever(() => mockOrderRepo.createOrder(
              deliveryAddress: any(named: 'deliveryAddress'),
              notes: any(named: 'notes'),
              paymentMethod: any(named: 'paymentMethod'),
            ));
      },
    );

    // المسار الكامل حتى `orderConfirmed` يمرّ بـ `SocketService()` — singleton
    // حقيقي غير قابل للحقن في MailBloc — فلا يمكن الوصول إليه في اختبار وحدة.
    // كان الاختبار السابق يتوقّع `orderConfirmed` فيحصل على لا شيء لأن حارس
    // `items.isEmpty` يسبقه. نفحص هنا الطبقة القابلة للفحص فعلاً: السلة غير
    // فارغة فيُنشأ الطلب، ثم يتوقّف التدفّق عند انعدام السوكيت.
    blocTest<MailBloc, MailState>(
      'ConfirmOrderEvent يتوقّف برسالة انقطاع الاتصال بلا سوكيت',
      setUp: () {
        when(() => mockOrderRepo.createOrder(
          deliveryAddress: any(named: 'deliveryAddress'),
          notes: any(named: 'notes'),
          paymentMethod: any(named: 'paymentMethod'),
        )).thenAnswer((_) async => {
          'order': {'_id': 'ord_1'},
        });
      },
      build: () => MailBloc(
        cartRepository: mockCartRepo,
        orderRepository: mockOrderRepo,
      ),
      seed: () => const MailState(
        orders: [],
        status: CartStatus.success,
        items: [MailItem(
          id: 'i1', foodId: 'f1', restaurantId: 'r1',
          title: 'T', price: 100, quantity: 1, imagePath: '',
        )],
      ),
      act: (bloc) {
        final address = AddressModel(
          addressName: 'Home', country: 'SY', city: 'D',
          area: 'A', streetChoice: 'S', buildingDetail: 'B',
        );
        bloc.add(ConfirmOrderEvent(deliveryAddress: address, notes: 'Fast'));
      },
      expect: () => [
        isA<MailState>().having((s) => s.status, 'loading', CartStatus.loading),
        isA<MailState>()
            .having((s) => s.status, 'error', CartStatus.error)
            .having((s) => s.errorMessage, 'msg',
                'connection_lost_order_not_sent'),
      ],
      verify: (_) {
        verify(() => mockOrderRepo.createOrder(
              deliveryAddress: any(named: 'deliveryAddress'),
              notes: any(named: 'notes'),
              paymentMethod: any(named: 'paymentMethod'),
            )).called(1);
      },
    );

    blocTest<MailBloc, MailState>(
      'emits [loading, success] when FetchUserOrdersEvent succeeds',
      setUp: () {
        when(() => mockOrderRepo.getUserOrders())
            .thenAnswer((_) async => [{'_id': 'ord_1', 'orderNumber': 'ORD-001'}]);
      },
      build: () => MailBloc(
        cartRepository: mockCartRepo,
        orderRepository: mockOrderRepo,
      ),
      act: (bloc) => bloc.add(FetchUserOrdersEvent()),
      expect: () => [
        MailState(orders: [], status: CartStatus.loading),
        MailState(orders: [{'_id': 'ord_1', 'orderNumber': 'ORD-001'}],
            status: CartStatus.success),
      ],
    );

    blocTest<MailBloc, MailState>(
      'emits [loading, success+toast] when CancelOrderEvent succeeds',
      setUp: () {
        when(() => mockOrderRepo.cancelOrder(any()))
            .thenAnswer((_) async => {});
        when(() => mockOrderRepo.getUserOrders())
            .thenAnswer((_) async => []);
      },
      build: () => MailBloc(
        cartRepository: mockCartRepo,
        orderRepository: mockOrderRepo,
      ),
      act: (bloc) => bloc.add(CancelOrderEvent('ord_1')),
      expect: () => [
        // المعرّف يرافق حالة الانتظار ليعرف الجدول أيّ بطاقة تُظهر المؤشّر،
        // ويُمسح مع وصول القائمة المحدَّثة.
        MailState(
            orders: [],
            status: CartStatus.loading,
            cancellingOrderId: 'ord_1'),
        MailState(orders: [], status: CartStatus.success, toast: 'cancelled'),
      ],
    );

    blocTest<MailBloc, MailState>(
      'يمسح معرّف الإلغاء عند فشل الإلغاء فلا يبقى مؤشّر معلّقاً',
      setUp: () {
        when(() => mockOrderRepo.cancelOrder(any()))
            .thenThrow(ApiException(AppError.ofKind(AppErrorKind.server)));
      },
      build: () => MailBloc(
        cartRepository: mockCartRepo,
        orderRepository: mockOrderRepo,
      ),
      act: (bloc) => bloc.add(CancelOrderEvent('ord_1')),
      expect: () => [
        isA<MailState>()
            .having((s) => s.cancellingOrderId, 'cancelling', 'ord_1'),
        isA<MailState>()
            .having((s) => s.status, 'status', CartStatus.error)
            .having((s) => s.cancellingOrderId, 'cancelling', isNull),
      ],
    );
  });
}
