import 'package:equatable/equatable.dart';
import '../../../location/data/models/address_model.dart';
import '../../domain/models/mail_item.dart'; // المسار المنظم

abstract class MailEvent extends Equatable {
  const MailEvent();

  @override
  List<Object?> get props => [];
}

class FetchCartEvent extends MailEvent {}

class AddToCartEvent extends MailEvent {
  final MailItem item;

  const AddToCartEvent(this.item);

  @override
  List<Object?> get props => [item];
}

class RemoveItemEvent extends MailEvent {
  final String id;
  final String restaurantId;

  const RemoveItemEvent({required this.id, required this.restaurantId});

  @override
  List<Object?> get props => [id, restaurantId];
}

class ConfirmOrderEvent extends MailEvent {
  final AddressModel deliveryAddress;
  final String? notes;

  const ConfirmOrderEvent({required this.deliveryAddress, this.notes});

  @override
  List<Object?> get props => [deliveryAddress, notes];
}

class CancelOrderEvent extends MailEvent {
  final String orderId;

  const CancelOrderEvent(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

/// مسح رسالة النجاح العابرة بعد عرضها (توست مرة واحدة)
class ClearToastEvent extends MailEvent {}

class FetchUserOrdersEvent extends MailEvent {}

class UpdateCartItemEvent extends MailEvent {
  final String itemId;
  final int quantity;

  const UpdateCartItemEvent({required this.itemId, required this.quantity});

  @override
  List<Object?> get props => [itemId, quantity];
}

/// فشل مزامنة كمية عنصر مع الخادم — يُرسله مؤقّت التأجيل ليعيد البلوك الكمية
/// إلى ما كانت عليه.
///
/// حدثٌ لا نداءَ `emit` مباشراً: معالج [UpdateCartItemEvent] متزامن فينتهي
/// فوراً، وتنتهي معه صلاحية `emit`. فاستدعاؤه من داخل المؤقّت بعد 400ms كان
/// يرمي `StateError` في bloc 9، فلا يحدث الرجوع وتبقى الكمية المتفائلة على
/// الشاشة مخالفةً للخادم.
class CartItemUpdateFailedEvent extends MailEvent {
  final String itemId;
  final int originalQuantity;

  const CartItemUpdateFailedEvent({
    required this.itemId,
    required this.originalQuantity,
  });

  @override
  List<Object?> get props => [itemId, originalQuantity];
}

class ClearCartEvent extends MailEvent {}

class ClearAndAddToCartEvent extends MailEvent {
  final MailItem item;

  const ClearAndAddToCartEvent(this.item);

  @override
  List<Object?> get props => [item];
}

class ApplyCouponEvent extends MailEvent {
  final String code;

  const ApplyCouponEvent({required this.code});

  @override
  List<Object?> get props => [code];
}

class RemoveCouponEvent extends MailEvent {}