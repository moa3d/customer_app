
import '../../data/models/address_model.dart';

abstract class LocationState {}

class LocationInitial extends LocationState {}

class LocationLoading extends LocationState {}

// تم دمج LocationLoaded و LocationSuccess في حالة واحدة قوية
class LocationSuccess extends LocationState {
  final List<AddressModel> addresses;

  // 👈 هذا هو مفتاح الحل: سيحتوي على العنوان الذي اختاره المستخدم يدوياً
  // إذا كان null، فهذا يعني أن المستخدم لم يختر عنواناً بعد (حتى لو لديه عناوين قديمة)
  final AddressModel? selectedAddress;

  LocationSuccess(this.addresses, {this.selectedAddress});
}

class LocationFailure extends LocationState {
  final String error;

  LocationFailure(this.error);
}