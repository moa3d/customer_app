import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nomnow_app/core/services/auth_service.dart';
import 'package:nomnow_app/features/auth/data/models/user_model.dart';
import 'package:nomnow_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:nomnow_app/features/profile/presentation/cubit/profile_state.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockAuthService mockAuth;

  setUp(() {
    mockAuth = MockAuthService();
  });

  group('ProfileCubit', () {
    final testUser = UserModel(
      id: '1', name: 'Test', 
      phone: '09', gender: 'm', country: 'SY',
    );

    blocTest<ProfileCubit, ProfileState>(
      'emits [loading, loaded] when fetchProfile succeeds',
      setUp: () {
        when(() => mockAuth.getUserProfile()).thenAnswer((_) async => testUser);
      },
      build: () => ProfileCubit(mockAuth),
      act: (cubit) => cubit.fetchProfile(),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileLoaded>().having((s) => s.user.name, 'name', 'Test'),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      'emits [loading, error] when fetchProfile fails',
      setUp: () {
        when(() => mockAuth.getUserProfile())
            .thenThrow(Exception('Server down'));
      },
      build: () => ProfileCubit(mockAuth),
      act: (cubit) => cubit.fetchProfile(),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileError>().having((s) => s.message, 'msg', contains('Server down')),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      'emits [loading, updateSuccess, loaded] when updateProfile succeeds',
      setUp: () {
        when(() => mockAuth.updateProfile(
          name: any(named: 'name'),
          gender: any(named: 'gender'),
          imageFile: any(named: 'imageFile'),
        )).thenAnswer((_) async {});
        when(() => mockAuth.getUserProfile())
            .thenAnswer((_) async => testUser);
      },
      build: () => ProfileCubit(mockAuth),
      seed: () => ProfileLoaded(testUser),
      act: (cubit) => cubit.updateProfile(name: 'Updated', gender: 'f'),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileUpdateSuccess>()
            .having((s) => s.user.name, 'name', 'Test')
            .having((s) => s.message, 'msg', 'تم تحديث البيانات بنجاح'),
        isA<ProfileLoaded>()
            .having((s) => s.user.name, 'name', 'Test'),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      'emits [loading, error, loaded] when updateProfile fails',
      setUp: () {
        when(() => mockAuth.updateProfile(
          name: any(named: 'name'),
          gender: any(named: 'gender'),
          imageFile: any(named: 'imageFile'),
        )).thenThrow(Exception('Failed'));
        when(() => mockAuth.getUserProfile())
            .thenAnswer((_) async => testUser);
      },
      build: () => ProfileCubit(mockAuth),
      seed: () => ProfileLoaded(testUser),
      act: (cubit) => cubit.updateProfile(name: 'X', gender: 'm'),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileError>().having((s) => s.message, 'msg', contains('Failed')),
        isA<ProfileLoaded>()
            .having((s) => s.user.name, 'name', 'Test'),
      ],
    );
  });
}
