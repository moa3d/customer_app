import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../../../core/network/app_error.dart';
import '../../../../core/services/socket_service.dart';
import '../../../orders/data/repositories/order_repository.dart'
    show OrderCreationException, PaymentIntentException, OrderRepository;
import '../../data/repositories/cart_repository.dart';
import '../../domain/models/mail_item.dart';

import 'mail_event.dart';
import 'mail_state.dart';

class MailBloc extends Bloc<MailEvent, MailState> {
  final CartRepository cartRepository;
  final OrderRepository orderRepository;
  final Map<String, Timer> _updateDebouncers = {};
  final Map<String, int> _itemOriginalQuantities = {};

  /// رسالة نجاح يُضبطها الإلغاء لتُحمل على حالة جلب الطلبات التالية
  String? _pendingCancelToast;

  /// السوكيت قابل للحقن حتى يكون مسار إتمام الطلب قابلاً للاختبار. الافتراضي
  /// هو الـ singleton نفسه، فلا يتغيّر أي موضع إنشاء في التطبيق.
  final SocketService _socket;

  MailBloc({
    required this.cartRepository,
    required this.orderRepository,
    SocketService? socketService,
  })  : _socket = socketService ?? SocketService(),
        super(const MailState(orders: [])) {
    on<AddToCartEvent>((event, emit) async {
      emit(state.copyWith(status: CartStatus.loading));
      try {
        final itemData = event.item.toJson();
        await cartRepository.addToCart(
          foodId: itemData['foodId'],
          quantity: itemData['quantity'],
          size: itemData['size'],
          extras: itemData['extras'],
          notes: itemData['notes'],
          restaurantId: event.item.restaurantId,
        );
        add(FetchCartEvent());
      } catch (e) {
        emit(state.copyWith(
            status: CartStatus.error,
            errorMessage: AppError.from(e).message));
      }
    });

    on<FetchCartEvent>((event, emit) async {
      emit(state.copyWith(status: CartStatus.loading));
      try {
        final response = await cartRepository.getCart();
        List<MailItem> fetchedItems = [];
        final cart = response['cart'] ?? response['data']?['cart'];

        if (cart != null && cart['items'] != null) {
          for (var item in cart['items']) {
            final sizeData = item['size'] is Map ? item['size'] : null;
            fetchedItems.add(MailItem(
              id: item['_id']?.toString() ?? '',
              foodId: item['foodId']?.toString() ?? '',
              restaurantId: cart['restaurantId']?.toString() ?? '',
              title: item['name']?.toString() ?? 'Meal',
              price: (item['basePrice'] as num?)?.toDouble() ?? 0.0,
              originalPrice: (item['originalPrice'] as num?)?.toDouble(),
              quantity: (item['quantity'] as num?)?.toInt() ?? 1,
              imagePath: item['image']?.toString() ?? '',
              size: sizeData?['name']?.toString(),
              sizePrice: (sizeData?['price'] as num?)?.toDouble(),
              extras: List<Map<String, dynamic>>.from(item['extras'] ?? []),
              notes: item['notes']?.toString() ?? "",
            ));
          }
        }

        emit(state.copyWith(
          status: CartStatus.success,
          items: fetchedItems,
          itemsPrice: (cart?['itemsPrice'] as num?)?.toDouble() ?? 0.0,
          currency: cart?['currency']?.toString() ?? state.currency,
          deliveryFee: (cart?['deliveryFee'] as num?)?.toDouble() ??
              state.deliveryFee,
          originalDeliveryFee:
              (cart?['originalDeliveryFee'] as num?)?.toDouble() ?? 0.0,
          couponCode: cart?['couponCode']?.toString(),
          couponType: cart?['couponType']?.toString(),
          couponDiscount: (cart?['couponDiscount'] as num?)?.toDouble() ?? 0.0,
          changedPrices: null,
        ));
      } catch (e) {
        emit(state.copyWith(
            status: CartStatus.error, errorMessage: "error_fetching_cart".tr()));
      }
    }, transformer: droppable());

    on<RemoveItemEvent>((event, emit) async {
      emit(state.copyWith(status: CartStatus.loading));
      try {
        await cartRepository.removeFromCart(itemId: event.id);
        add(FetchCartEvent());
      } catch (e) {
        emit(state.copyWith(
            status: CartStatus.error, errorMessage: "error_removing_item".tr()));
      }
    });

    on<UpdateCartItemEvent>((event, emit) {
      _updateDebouncers[event.itemId]?.cancel();

      if (!_itemOriginalQuantities.containsKey(event.itemId)) {
        final current = state.items.cast<MailItem?>().firstWhere(
              (i) => i?.id == event.itemId,
              orElse: () => null,
            );
        if (current != null) {
          _itemOriginalQuantities[event.itemId] = current.quantity;
        }
      }

      final updated = state.items.map((item) {
        if (item.id == event.itemId) {
          return MailItem(
            id: item.id,
            foodId: item.foodId,
            restaurantId: item.restaurantId,
            title: item.title,
            price: item.price,
            originalPrice: item.originalPrice,
            quantity: event.quantity,
            imagePath: item.imagePath,
            size: item.size,
            sizePrice: item.sizePrice,
            extras: item.extras,
            notes: item.notes,
          );
        }
        return item;
      }).toList();

      emit(state.copyWith(items: updated, status: CartStatus.success));

      final itemId = event.itemId;
      _updateDebouncers[itemId] =
          Timer(const Duration(milliseconds: 400), () async {
        _updateDebouncers.remove(itemId);

        final currentItem =
            state.items.cast<MailItem?>().firstWhere(
                  (i) => i?.id == itemId,
                  orElse: () => null,
                );
        if (currentItem == null) return;

        // زال هنا التقاطُ الكوبون وإعادةُ تطبيقه بعد النداء: كانا لازمين
        // حين كان تحديث الكمية `DELETE` ثم `POST`، فحذفُ آخر عنصر يحذف وثيقة
        // السلة ومعها `couponCode`. الباك صار يعدّل العنصر بمكانه ولا يحذف
        // شيئاً، فالكوبون باقٍ بلا تدخّل منا.
        try {
          final res = await cartRepository.updateCartItem(
            itemId: itemId,
            quantity: currentItem.quantity,
          );
          _itemOriginalQuantities.remove(itemId);

          if (res['cart'] != null) {
            add(FetchCartEvent());
          }
        } catch (e) {
          final originalQty = _itemOriginalQuantities.remove(itemId);
          if (originalQty != null) {
            // حدثٌ لا `emit`: صلاحية emit انتهت مع انتهاء المعالج المتزامن
            add(CartItemUpdateFailedEvent(
              itemId: itemId,
              originalQuantity: originalQty,
            ));
          }
        }
      });
    });

    on<CartItemUpdateFailedEvent>((event, emit) {
      final reverted = state.items.map((item) {
        if (item.id == event.itemId) {
          return MailItem(
            id: item.id,
            foodId: item.foodId,
            restaurantId: item.restaurantId,
            title: item.title,
            price: item.price,
            originalPrice: item.originalPrice,
            quantity: event.originalQuantity,
            imagePath: item.imagePath,
            size: item.size,
            sizePrice: item.sizePrice,
            extras: item.extras,
            notes: item.notes,
          );
        }
        return item;
      }).toList();
      emit(state.copyWith(items: reverted, status: CartStatus.success));
    });

    on<ClearCartEvent>((event, emit) async {
      try {
        await cartRepository.clearCart();
      } catch (_) {}
      for (final timer in _updateDebouncers.values) {
        timer.cancel();
      }
      _updateDebouncers.clear();
      _itemOriginalQuantities.clear();
      emit(state.copyWith(
          items: [],
          status: CartStatus.initial,
          itemsPrice: 0,
          deliveryFee: 0,
          originalDeliveryFee: 0,
          couponCode: null,
          couponType: null,
          couponDiscount: 0));
    });

    on<ClearAndAddToCartEvent>((event, emit) async {
      emit(state.copyWith(status: CartStatus.loading));
      try {
        // تبديل المطعم صار نداءً واحداً: `replaceCart` يصفّر السلة ويربطها
        // بالمطعم الجديد داخل نفس عملية الإضافة. كان قبله تفريغٌ يدوي بحذف
        // العناصر واحداً واحداً — عدّة نداءات، وأيّ فشل في منتصفها يترك
        // المستخدم بسلة نصف فارغة لا هي القديمة ولا الجديدة.
        for (final timer in _updateDebouncers.values) {
          timer.cancel();
        }
        _updateDebouncers.clear();
        _itemOriginalQuantities.clear();

        final itemData = event.item.toJson();
        await cartRepository.addToCart(
          foodId: itemData['foodId'],
          quantity: itemData['quantity'],
          size: itemData['size'],
          extras: itemData['extras'],
          notes: itemData['notes'],
          restaurantId: event.item.restaurantId,
          replaceCart: true,
        );

        add(FetchCartEvent());
      } catch (e) {
        emit(state.copyWith(
            status: CartStatus.error,
            errorMessage: AppError.from(e).message));
      }
    });

    on<ApplyCouponEvent>((event, emit) async {
      emit(state.copyWith(status: CartStatus.loading));
      try {
        await cartRepository.applyCoupon(code: event.code);
        add(FetchCartEvent());
      } catch (e) {
        // نفضّل رسالة السيرفر المترجمة (كوبون غير صالح، منتهي... إلخ)
        emit(state.copyWith(
            status: CartStatus.error, errorMessage: _couponErrorMessage(e)));
      }
    });

    on<RemoveCouponEvent>((event, emit) async {
      emit(state.copyWith(status: CartStatus.loading));
      try {
        await cartRepository.removeCoupon();
        add(FetchCartEvent());
      } catch (e) {
        emit(state.copyWith(
            status: CartStatus.error, errorMessage: _couponErrorMessage(e)));
      }
    });

    on<ConfirmOrderEvent>(_onConfirmOrder);

    on<FetchUserOrdersEvent>((event, emit) async {
      emit(state.copyWith(status: CartStatus.loading));
      try {
        final orders = await orderRepository.getUserOrders();
        final String? toast = _pendingCancelToast;
        _pendingCancelToast = null;
        emit(state.copyWith(
            status: CartStatus.success,
            orders: orders,
            cancellingOrderId: null,
            toast: toast));
      } catch (e) {
        _pendingCancelToast = null;
        emit(state.copyWith(
            status: CartStatus.error,
            errorMessage: "error_fetching_orders".tr(),
            cancellingOrderId: null));
      }
    });

    on<CancelOrderEvent>((event, emit) async {
      // المعرّف يرافق الحالة حتى ينتهي الجلب التالي: بدونه كانت الشاشة
      // تستنتج الإلغاء من `loading` وحدها فتضيء المؤشّر على كل البطاقات.
      emit(state.copyWith(
          status: CartStatus.loading, cancellingOrderId: event.orderId));
      try {
        await orderRepository.cancelOrder(event.orderId);
        _pendingCancelToast = 'cancelled'.tr();
        add(FetchUserOrdersEvent());
      } catch (e) {
        _pendingCancelToast = null;
        emit(state.copyWith(
            status: CartStatus.error,
            errorMessage: _cancelErrorMessage(e),
            cancellingOrderId: null,
            toast: null));
      }
    });

    on<ClearToastEvent>((event, emit) {
      emit(state.copyWith(toast: null));
    });
  }

  @override
  Future<void> close() {
    for (final timer in _updateDebouncers.values) {
      timer.cancel();
    }
    _updateDebouncers.clear();
    _itemOriginalQuantities.clear();
    return super.close();
  }

  /// رسالة خطأ الإلغاء: رسالة السيرفر إن وُجدت، وإلا رسالة عامة خاصة بالإلغاء.
  ///
  /// تُقرأ من `AppError` بدل تفكيك نص الاستثناء يدوياً: المستودعات صارت ترمي
  /// [ApiException] حاملاً التصنيف والرسالة معاً.
  String _cancelErrorMessage(Object e) =>
      AppError.from(e).serverMessage ?? 'error_cancelling_order'.tr();

  /// رسالة خطأ الكوبون — رسالة السيرفر المترجمة (كوبون غير صالح، منتهٍ...)
  /// وإلا رسالة عامة.
  String _couponErrorMessage(Object e) =>
      AppError.from(e).serverMessage ?? 'coupons.apply_failed'.tr();

  Future<void> _onConfirmOrder(ConfirmOrderEvent event,
      Emitter<MailState> emit) async {
    if (state.status == CartStatus.loading) return;
    if (state.status == CartStatus.orderConfirmed) return;
    if (state.items.isEmpty) return;

    emit(state.copyWith(status: CartStatus.loading));

    try {
      final response = await orderRepository.createOrder(
        deliveryAddress: event.deliveryAddress.toJson(),
        notes: event.notes,
        paymentMethod: "cash",
      );

      if (response['order'] == null) {
        emit(state.copyWith(
          status: CartStatus.error,
          errorMessage: "order_creation_failed".tr(),
        ));
        return;
      }

      final orderData = response['order'];
      final Map<String, dynamic> orderMap = (orderData is List)
          ? Map<String, dynamic>.from(orderData[0])
          : Map<String, dynamic>.from(orderData);
      final String orderId = orderMap['_id'].toString();
      orderMap['currency'] = state.currency;

      // ── الدفع عبر Stripe لطلبات مطاعم ألمانيا (DE) ──────────────────
      // الباك يفرض paymentMethod = "card" تلقائياً على هذه الطلبات داخل
      // createOrder (بغض النظر عمّا أرسلناه)، ويُرفق taxBreakdown جاهزاً
      // ضمن نفس استجابة إنشاء الطلب — لذلك لا حاجة لمعرفة دولة المستخدم
      // مسبقاً هنا: الباك هو مصدر الحقيقة الوحيد.
      String? paymentIntentId;
      final bool requiresCardPayment = orderMap['paymentMethod'] == 'card';

      if (requiresCardPayment) {
        if (orderMap['taxBreakdown'] != null) {
          emit(state.copyWith(
            taxBreakdown: Map<String, dynamic>.from(orderMap['taxBreakdown']),
          ));
        }

        try {
          final intentResponse = await orderRepository.createPaymentIntent();

          await Stripe.instance.initPaymentSheet(
            paymentSheetParameters: SetupPaymentSheetParameters(
              paymentIntentClientSecret:
                  intentResponse['clientSecret']?.toString(),
              merchantDisplayName: 'NomNow',
            ),
          );
          await Stripe.instance.presentPaymentSheet();

          paymentIntentId = intentResponse['paymentIntentId']?.toString();
        } on StripeException catch (e) {
          // المستخدم ألغى الدفع أو فشلت البطاقة. الطلب الذي أنشأناه للتو
          // يبقى بحالة not_confirmed على السيرفر وسيُنظَّف تلقائياً عند أي
          // محاولة تأكيد قادمة (الباك يحذف not_confirmed القديمة قبل كل
          // إنشاء طلب جديد لنفس المستخدم) — لا حاجة لإلغائه يدوياً هنا.
          emit(state.copyWith(
            status: CartStatus.error,
            errorMessage: e.error.message ?? "payment_failed".tr(),
          ));
          return;
        } on PaymentIntentException catch (e) {
          emit(state.copyWith(
            status: CartStatus.error,
            errorMessage: e.message,
          ));
          return;
        }
      }

      final socket = _socket;

      if (!socket.isConnected) {
        emit(state.copyWith(
          status: CartStatus.error,
          errorMessage: "connection_lost_order_not_sent".tr(),
        ));
        return;
      }

      final completer = Completer<String?>();
      bool promotionExpired = false;
      bool cartChanged = false;

      socket.listenToOrderSent((_) {
        if (!completer.isCompleted) completer.complete(null);
      });
      socket.listenToPromotionExpired((_) {
        promotionExpired = true;
        if (!completer.isCompleted) completer.complete(null);
      });
      // v4.2 — السلة تغيّرت أثناء إتمام الطلب فلم يُرسَل. يُبثّ بدل
      // `order:sent`، فبلا هذا المستمع ينتظر المستخدم عشرين ثانية ثم يرى
      // «تعذّر تأكيد حالة الطلب» بلا سبب مفهوم.
      socket.listenToCartChanged((_) {
        cartChanged = true;
        if (!completer.isCompleted) completer.complete(null);
      });
      socket.listenToErrors((msg) {
        if (!completer.isCompleted) completer.complete(msg);
      });

      if (!socket.sendOrderToRestaurant(orderId,
          paymentIntentId: paymentIntentId)) {
        socket.removeCheckoutListeners();
        emit(state.copyWith(
          status: CartStatus.error,
          errorMessage: "connection_lost_order_not_sent".tr(),
        ));
        return;
      }

      String? serverError;
      bool timedOut = false;
      try {
        serverError = await completer.future
            .timeout(const Duration(seconds: 20));
      } on TimeoutException {
        timedOut = true;
      }

      socket.removeCheckoutListeners();

      if (promotionExpired) {
        add(FetchCartEvent());
        emit(state.copyWith(
          status: CartStatus.error,
          errorMessage: "offer_no_longer_available".tr(),
        ));
        return;
      }

      if (cartChanged) {
        // السلة سليمة على الخادم بكامل عناصرها — نُعيد جلبها ليراجعها المستخدم
        add(FetchCartEvent());
        emit(state.copyWith(
          status: CartStatus.error,
          errorMessage: "cart_changed_during_checkout".tr(),
        ));
        return;
      }

      if (serverError != null && serverError.isNotEmpty) {
        emit(state.copyWith(
          status: CartStatus.error,
          errorMessage: serverError,
        ));
        return;
      }

      if (timedOut) {
        emit(state.copyWith(
          status: CartStatus.error,
          errorMessage: "order_status_unknown_check_orders".tr(),
        ));
        return;
      }

      emit(state.copyWith(
        items: [],
        status: CartStatus.orderConfirmed,
        lastOrder: orderMap,
      ));

      // حدّث قائمة الطلبات فوراً عند إتمام النقل من السلة
      // حتى تظهر في "طلباتي" دون انتظار إعادة تشغيل التطبيق
      add(FetchUserOrdersEvent());

      // أعد جلب السلة بعد التأكيد حتى تُنظَّف الحالة عند رجوع المستخدم
      // من شاشة تأكيد الطلب (بدلاً من بقائها عالقة على orderConfirmed → loading)
      add(FetchCartEvent());
    } catch (e) {
      if (e is OrderCreationException) {
        emit(state.copyWith(
          status: CartStatus.error,
          errorMessage: e.message,
          changedPrices: e.changedItems,
        ));
      } else {
        emit(state.copyWith(
            status: CartStatus.error,
            errorMessage: AppError.from(e).message));
      }
    }
  }
}
