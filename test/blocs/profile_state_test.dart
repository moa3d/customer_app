import 'package:flutter_test/flutter_test.dart';
import 'package:nomnow_app/features/profile/presentation/cubit/profile_state.dart';
import 'package:nomnow_app/features/auth/data/models/user_model.dart';

void main() {
  group('ProfileState', () {
    test('ProfileInitial is equatable', () {
      final a = ProfileInitial();
      final b = ProfileInitial();
      expect(a, b);
    });

    test('ProfileLoading is equatable', () {
      final a = ProfileLoading();
      final b = ProfileLoading();
      expect(a, b);
    });

    test('ProfileLoaded stores user', () {
      final user = UserModel(
        id: '1', name: 'Test', 
        phone: '09', gender: 'm', country: 'SY',
      );
      final state = ProfileLoaded(user);
      expect(state.user, user);
    });

    test('ProfileLoaded equality', () {
      final user1 = UserModel(
        id: '1', name: 'Test', 
        phone: '09', gender: 'm', country: 'SY',
      );
      final user2 = UserModel(
        id: '2', name: 'Other', 
        phone: '08', gender: 'f', country: 'DE',
      );
      expect(ProfileLoaded(user1), ProfileLoaded(user1));
      expect(ProfileLoaded(user1) == ProfileLoaded(user2), false);
    });

    test('ProfileUpdateSuccess stores user and message', () {
      final user = UserModel(
        id: '1', name: 'A', 
        phone: '09', gender: 'm', country: 'SY',
      );
      final state = ProfileUpdateSuccess(user, 'Updated');
      expect(state.user, user);
      expect(state.message, 'Updated');
    });

    test('ProfileError stores message', () {
      expect(ProfileError('Failed').message, 'Failed');
    });

    test('ProfileError equality', () {
      expect(ProfileError('E1'), ProfileError('E1'));
      expect(ProfileError('E1') == ProfileError('E2'), false);
    });
  });
}
