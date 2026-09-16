import 'package:flutter_test/flutter_test.dart';
import 'package:nomnow_app/features/auth/data/models/user_model.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('UserModel', () {
    test('fromJson creates model correctly', () {
      final json = createTestUserJson();
      final user = UserModel.fromJson(json);

      expect(user.id, '123');
      expect(user.name, 'Test User');
      expect(user.phone, '0987654321');
      expect(user.gender, 'ذكر');
      expect(user.country, 'SY');
      expect(user.isBanned, false);
      expect(user.createdAt, '2025-01-01T00:00:00Z');
    });

    test('fromJson uses defaults for missing fields', () {
      final user = UserModel.fromJson({});
      expect(user.id, '');
      expect(user.name, '');
      expect(user.phone, '');
      expect(user.gender, '');
      expect(user.country, 'SY');
      expect(user.isBanned, false);
    });

    test('fromJson extracts img from nested map', () {
      final json = createTestUserJson()..['img'] = {'url': 'https://example.com/avatar.jpg'};
      final user = UserModel.fromJson(json);
      expect(user.imgUrl, 'https://example.com/avatar.jpg');
    });

    test('fromJson handles null img', () {
      final user = UserModel.fromJson(createTestUserJson());
      expect(user.imgUrl, null);
    });

    test('toJson produces correct map', () {
      final user = UserModel(
        id: '123',
        name: 'Test',
        phone: '09',
        gender: 'male',
        country: 'SY',
      );
      final json = user.toJson();
      expect(json['_id'], '123');
      expect(json['name'], 'Test');
      expect(json['phone'], '09');
      expect(json['gender'], 'male');
      expect(json['country'], 'SY');
      expect(json['img'], null);
      expect(json['createdAt'], null);
    });

    test('toJson includes img when imgUrl is set', () {
      final user = UserModel(
        id: '1',
        name: 'A',
        phone: '09',
        gender: 'f',
        country: 'SY',
        imgUrl: 'https://example.com/pic.jpg',
      );
      final json = user.toJson();
      expect(json['img'], {'url': 'https://example.com/pic.jpg'});
    });

    test('isBanned defaults to false', () {
      final user = UserModel(id: '1', name: 'A', phone: '09', gender: 'm', country: 'SY');
      expect(user.isBanned, false);
    });
  });
}
