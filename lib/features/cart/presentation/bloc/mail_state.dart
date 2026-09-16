import 'package:equatable/equatable.dart';

import '../../domain/models/mail_item.dart';

//  أضفنا الحالة orderConfirmed لضمان عدم إظهار رسالة النجاح إلا بعد رد السيرفر
enum CartStatus { initial, loading, success, error, orderConfirmed }

class MailState extends Equatable {
  final List<MailItem> items;
  final List<dynamic> orders;
  final CartStatus status;
  final String? errorMessage;

  // سعر الأصناف فقط — cart['itemsPrice'] القادم من الباك.
  // ملاحظة: الباك يعيد أيضاً totalCartPrice لكنه يساوي (الأصناف + التوصيل)،
  // فقراءته هنا كانت تؤدي لاحتساب رسوم التوصيل مرتين في الفاتورة.
  final double itemsPrice;

  // الحقول لدعم نظام الضرائب ومنطق الدولة (ألمانيا/سوريا)
  final double deliveryFee; // رسوم التوصيل القادمة من السيرفر
  // رسوم التوصيل قبل تطبيق عرض التوصيل المجاني — cart['originalDeliveryFee']
  final double originalDeliveryFee;
  final String currency; // العملة (ل.س أو €)
  final Map<String, dynamic>? taxBreakdown; // تفاصيل الضرائب (خاص بألمانيا)

  // بيانات آخر طلب تم تأكيده — تُستخدم في شاشة التأكيد
  final Map<String, dynamic>? lastOrder;

  // رسالة نجاح عابرة (مثل "تم الإلغاء") — تعرض مرة واحدة ثم تُمسح
  final String? toast;

  /// معرّف الطلب الجاري إلغاؤه، أو null إن لم يكن هناك إلغاء جارٍ.
  ///
  /// كانت شاشة الطلبات تستنتج «جارٍ الإلغاء» من `status == loading` وحده،
  /// وهي حالة يدخلها كل جلب للطلبات — فيضيء سبينر الإلغاء على **كل**
  /// البطاقات مع أي تحديث للقائمة. المعرّف يحصر المؤشّر ببطاقته.
  final String? cancellingOrderId;

  // عناصر تغيّرت أسعارها (من 409 Price Changed) — تُظهر banner في السلة
  final List<Map<String, dynamic>>? changedPrices;

  // حقول الكوبون — قيم جاهزة من الباك (لا يُعاد حسابها محلياً)
  final String? couponCode; // cart['couponCode'] — قد يكون null بصمت
  final String? couponType; // percentage | fixed | free_delivery
  final double couponDiscount; // cart['couponDiscount']

  const MailState({
    this.items = const [],
    this.orders = const [],
    this.status = CartStatus.initial,
    this.errorMessage,
    this.itemsPrice = 0.0,
    this.deliveryFee = 0.0,
    this.originalDeliveryFee = 0.0,
    this.currency = "",
    this.taxBreakdown,
    this.lastOrder,
    this.changedPrices,
    this.toast,
    this.cancellingOrderId,
    this.couponCode,
    this.couponType,
    this.couponDiscount = 0.0,
  });

  /// سعر الأصناف فقط — بلا توصيل وبلا ضريبة.
  double get totalAmount {
    if (itemsPrice > 0) return itemsPrice;
    return items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  /// عرض التوصيل المجاني مفعّل: الباك صفّر الرسوم وأبقى السعر الأصلي.
  bool get hasFreeDelivery => originalDeliveryFee > 0 && deliveryFee == 0;

  /// هل تم تطبيق كوبون حالياً على السلة؟ (قيمة null تُعامل كحالة "بدون كوبون" بصمت)
  bool get hasCoupon => couponCode != null && couponCode!.isNotEmpty;

  MailState copyWith({
    List<MailItem>? items,
    List<dynamic>? orders,
    CartStatus? status,
    Object? errorMessage = _sentinel,
    double? itemsPrice,
    double? deliveryFee,
    double? originalDeliveryFee,
    String? currency,
    Object? taxBreakdown = _sentinel,
    Object? lastOrder = _sentinel,
    Object? changedPrices = _sentinel,
    Object? toast = _sentinel,
    Object? cancellingOrderId = _sentinel,
    Object? couponCode = _sentinel,
    Object? couponType = _sentinel,
    double? couponDiscount,
  }) {
    return MailState(
      items: items ?? this.items,
      orders: orders ?? this.orders,
      status: status ?? this.status,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      itemsPrice: itemsPrice ?? this.itemsPrice,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      originalDeliveryFee: originalDeliveryFee ?? this.originalDeliveryFee,
      currency: currency ?? this.currency,
      taxBreakdown: identical(taxBreakdown, _sentinel)
          ? this.taxBreakdown
          : taxBreakdown as Map<String, dynamic>?,
      lastOrder: identical(lastOrder, _sentinel)
          ? this.lastOrder
          : lastOrder as Map<String, dynamic>?,
      changedPrices: identical(changedPrices, _sentinel)
          ? this.changedPrices
          : changedPrices as List<Map<String, dynamic>>?,
      toast: identical(toast, _sentinel) ? this.toast : toast as String?,
      cancellingOrderId: identical(cancellingOrderId, _sentinel)
          ? this.cancellingOrderId
          : cancellingOrderId as String?,
      couponCode: identical(couponCode, _sentinel)
          ? this.couponCode
          : couponCode as String?,
      couponType: identical(couponType, _sentinel)
          ? this.couponType
          : couponType as String?,
      couponDiscount: couponDiscount ?? this.couponDiscount,
    );
  }

  static const _sentinel = Object();

  @override
  List<Object?> get props =>
      [
        items,
        orders,
        status,
        errorMessage,
        itemsPrice,
        deliveryFee,
        originalDeliveryFee,
        currency,
        taxBreakdown,
        lastOrder,
        changedPrices,
        toast,
        cancellingOrderId,
        couponCode,
        couponType,
        couponDiscount,
      ];
}