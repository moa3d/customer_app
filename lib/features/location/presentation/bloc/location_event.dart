
import '../../data/models/address_model.dart';

abstract class LocationEvent {}

class ConfirmLocationEvent extends LocationEvent {
  final AddressModel address;
  ConfirmLocationEvent(this.address);
}
class LoadAddressesEvent extends LocationEvent {}

class SetDefaultAddressEvent extends LocationEvent {
  final String addressId;
  SetDefaultAddressEvent(this.addressId);
}

// ملاحظة: لا يوجد حدث تعديل مستقل — ConfirmLocationEvent يغطي الإضافة والتعديل
// معاً، لأن AuthService.addOrUpdateAddress يتحوّل إلى PATCH تلقائياً عندما يكون
// address.id غير فارغ.

class DeleteLocationEvent extends LocationEvent {
  final String addressId;
  DeleteLocationEvent(this.addressId);
}

class SelectAddressEvent extends LocationEvent {
  final AddressModel address;
  SelectAddressEvent(this.address);
}