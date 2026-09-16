import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/auth_service.dart';
import '../../../auth/data/models/user_model.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final AuthService _authService;

  ProfileCubit(this._authService) : super(ProfileInitial());

  // جلب بيانات الملف الشخصي من السيرفر
  Future<void> fetchProfile() async {
    emit(ProfileLoading());
    try {
      final user = await _authService.getUserProfile();
      emit(ProfileLoaded(user));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  // تحديث بيانات الملف الشخصي
  Future<void> updateProfile({
    required String name,
    required String gender,
    File? imageFile,
  }) async {
    final currentState = state;
    UserModel? oldUser;
    if (currentState is ProfileLoaded) {
      oldUser = currentState.user;
    }

    emit(ProfileLoading());
    try {
      await _authService.updateProfile(
        name: name,
        gender: gender,
        imageFile: imageFile,
      );

      // إعادة جلب البيانات المحدثة لضمان مزامنة كل الشاشات
      final updatedUser = await _authService.getUserProfile();
      emit(ProfileUpdateSuccess(updatedUser, "تم تحديث البيانات بنجاح"));
      emit(ProfileLoaded(updatedUser));
    } catch (e) {
      emit(ProfileError("فشل التحديث: $e"));
      if (oldUser != null) {
        emit(ProfileLoaded(oldUser));
      }
    }
  }
}