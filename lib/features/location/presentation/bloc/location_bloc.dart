import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/services/auth_service.dart';
import '../../data/models/address_model.dart';
import 'location_event.dart';
import 'location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final AuthService _authService;

  LocationBloc(this._authService) : super(LocationInitial()) {

    on<ConfirmLocationEvent>((event, emit) async {
      // يُلتقط قبل أي emit — نستعيده عند الفشل بدل جولة شبكة جديدة
      final previousState = state;
      final bool isEditing =
          event.address.id != null && event.address.id!.isNotEmpty;

      if (previousState is LocationSuccess) {
        if (previousState.addresses.length >= 5 && !isEditing) {
          emit(LocationFailure("max_addresses_allowed".tr()));
          emit(previousState);
          return;
        }
      }

      emit(LocationLoading());
      try {
        final response = await _authService.addOrUpdateAddress(event.address);

        if (response.statusCode == 200 || response.statusCode == 201) {
          final List rawData = response.data['addresses'] ?? [];
          final List<AddressModel> updatedList = rawData
              .map((item) => AddressModel.fromJson(item))
              .toList();

          // العنوان المختار: المُعدَّل إن كنا نعدّل، وإلا الافتراضي، وإلا الأخير
          AddressModel? selected;
          if (updatedList.isNotEmpty) {
            selected = _pickFirstOrNull(
                    updatedList, (a) => isEditing && a.id == event.address.id) ??
                _pickFirstOrNull(updatedList, (a) => a.isDefault) ??
                updatedList.last;
          }
          emit(LocationSuccess(updatedList, selectedAddress: selected));
        }
      } catch (e) {
        emit(LocationFailure(_handleDioError(e)));
        // استعادة القائمة المعروفة بدل ترك الشاشة فارغة
        if (previousState is LocationSuccess) emit(previousState);
      }
    });

    // 2. جلب العناوين (مع مزامنة الحالة الافتراضية التلقائية)
    on<LoadAddressesEvent>((event, emit) async {
      emit(LocationLoading());
      try {
        final response = await _authService.getUserAddresses();
        if (response.statusCode == 200) {
          final List rawData = response.data['addresses'] ?? [];
          final List<AddressModel> list = rawData.map((item) =>
              AddressModel.fromJson(item)).toList();

          AddressModel? defaultAddr;
          try {
            defaultAddr = list.firstWhere((addr) => addr.isDefault == true);
          } catch (_) {
            // الباك أند يعين أول عنوان كافتراضي تلقائياً، هنا نضمن المزامنة
            defaultAddr = list.isNotEmpty ? list.first : null;
          }

          emit(LocationSuccess(list, selectedAddress: defaultAddr));
        }
      } catch (e) {
        emit(LocationFailure(_handleDioError(e)));
      }
    });

    // 3. تعيين العنوان كافتراضي
    on<SetDefaultAddressEvent>((event, emit) async {
      final currentState = state;
      if (currentState is LocationSuccess) {
        try {
          final response = await _authService.setDefaultAddress(
              event.addressId);
          if (response.statusCode == 200) {
            final List rawData = response.data['addresses'] ?? [];
            final List<AddressModel> updatedList = rawData
                .map((item) => AddressModel.fromJson(item))
                .toList();

            final selected = updatedList.firstWhere((a) =>
            a.id == event.addressId);
            emit(LocationSuccess(updatedList, selectedAddress: selected));
          }
        } catch (e) {
          emit(LocationFailure(_handleDioError(e)));
          emit(currentState); // البقاء على القائمة الحالية في حال الفشل
        }
      }
    });

    // 4. حذف الموقع (مع حماية "العنوان الوحيد")
    on<DeleteLocationEvent>((event, emit) async {
      final currentState = state;
      if (currentState is LocationSuccess) {
        // حماية برمجية في الفرونت أند: منع إرسال طلب الحذف إذا كان هناك عنوان واحد فقط
        if (currentState.addresses.length <= 1) {
          emit(LocationFailure("cannot_delete_only_address".tr()));
          emit(currentState);
          return;
        }

        try {
          final response = await _authService.deleteAddress(event.addressId);
          if (response.statusCode == 200) {
            final List rawData = response.data['addresses'] ?? [];
            final List<AddressModel> updatedList = rawData
                .map((item) => AddressModel.fromJson(item))
                .toList();

            AddressModel? nextSelected = updatedList.isNotEmpty
                ? updatedList.firstWhere((a) => a.isDefault,
                orElse: () => updatedList.first)
                : null;

            emit(LocationSuccess(updatedList, selectedAddress: nextSelected));
          }
        } catch (e) {
          emit(LocationFailure(_handleDioError(e)));
          emit(currentState);
        }
      }
    });

    // 5. اختيار عنوان يدوي من القائمة
    on<SelectAddressEvent>((event, emit) {
      final currentState = state;
      if (currentState is LocationSuccess) {
        emit(LocationSuccess(
            currentState.addresses, selectedAddress: event.address));
      }
    });
  }

  // أول عنصر يحقق الشرط، أو null — بديل firstWhere بلا استثناء
  AddressModel? _pickFirstOrNull(
      List<AddressModel> list, bool Function(AddressModel) test) {
    for (final item in list) {
      if (test(item)) return item;
    }
    return null;
  }

  // ✅ استخراج رسائل الخطأ التفصيلية من الباك أند
  String _handleDioError(dynamic e) {
    if (e is DioException && e.response != null) {
      // محاولة جلب رسالة الخطأ المترجمة القادمة من السيرفر
      return e.response?.data['message'] ?? "حدث خطأ في الخادم";
    }
    return "تأكد من الاتصال بالإنترنت";
  }
}