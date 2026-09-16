import 'package:flutter_test/flutter_test.dart';
import 'package:nomnow_app/features/location/data/models/address_model.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('AddressModel', () {
    test('fromJson creates model correctly', () {
      final json = createTestAddressJson();
      final address = AddressModel.fromJson(json);

      expect(address.id, 'addr_1');
      expect(address.addressName, 'Home');
      expect(address.country, 'Syria');
      expect(address.city, 'Damascus');
      expect(address.area, 'Mazzah');
      expect(address.streetChoice, 'Main St');
      expect(address.buildingDetail, '12');
      expect(address.isDefault, true);
      expect(address.lat, 33.5101);
      expect(address.lng, 36.2833);
    });

    test('fromJson uses defaults for missing fields', () {
      final address = AddressModel.fromJson({});
      expect(address.addressName, '');
      expect(address.country, '');
      expect(address.city, '');
      expect(address.area, '');
      expect(address.streetChoice, '');
      expect(address.buildingDetail, '');
      expect(address.isDefault, false);
      expect(address.lat, null);
      expect(address.lng, null);
    });

    test('fromJson handles missing location', () {
      final json = createTestAddressJson()..remove('location');
      final address = AddressModel.fromJson(json);
      expect(address.lat, null);
      expect(address.lng, null);
    });

    test('fromJson handles null coordinates', () {
      final json = createTestAddressJson()
        ..['location'] = {'type': 'Point', 'coordinates': null};
      final address = AddressModel.fromJson(json);
      expect(address.lat, null);
      expect(address.lng, null);
    });

    test('fromJson supports area fallback to zone', () {
      final json = createTestAddressJson()
        ..remove('area')
        ..['zone'] = 'Downtown';
      final address = AddressModel.fromJson(json);
      expect(address.area, 'Downtown');
    });

    test('toJson produces correct structure', () {
      final address = AddressModel(
        addressName: 'Home',
        country: 'Syria',
        city: 'Damascus',
        area: 'Mazzah',
        streetChoice: 'Main St',
        buildingDetail: '12',
        lat: 33.51,
        lng: 36.28,
        isDefault: true,
      );
      final json = address.toJson();
      expect(json['name'], 'Home');
      expect(json['country'], 'SY');
      expect(json['city'], 'Damascus');
      expect(json['area'], 'Mazzah');
      expect(json['street'], 'Main St');
      expect(json['building'], '12');
      expect(json['isDefault'], true);
      expect(json['location']['type'], 'Point');
      expect(json['location']['coordinates'], [36.28, 33.51]);
    });

    test('toJson converts Syria-related country to SY', () {
      final a1 = AddressModel(
        addressName: 'H', country: 'Syria', city: 'D', area: 'A',
        streetChoice: 'S', buildingDetail: 'B',
      );
      expect(a1.toJson()['country'], 'SY');

      final a2 = AddressModel(
        addressName: 'H', country: 'سوريا', city: 'D', area: 'A',
        streetChoice: 'S', buildingDetail: 'B',
      );
      expect(a2.toJson()['country'], 'SY');

      final a3 = AddressModel(
        addressName: 'H', country: '', city: 'D', area: 'A',
        streetChoice: 'S', buildingDetail: 'B',
      );
      expect(a3.toJson()['country'], 'SY');
    });

    // كان `toJson` يضع إحداثيات دمشق بديلاً عند غياب الموقع، فتعبر تحقّق
    // الباك من الإحداثيات ويُنشَأ طلب وجهته وسط دمشق لا عنوان المستخدم.
    test('toJson omits location entirely when lat/lng are null', () {
      final address = AddressModel(
        addressName: 'H', country: 'SY', city: 'D', area: 'A',
        streetChoice: 'S', buildingDetail: 'B',
      );
      final json = address.toJson();
      expect(address.hasCoordinates, isFalse);
      expect(json.containsKey('location'), isFalse);
      expect(json.containsKey('lat'), isFalse);
      expect(json.containsKey('lng'), isFalse);
      // بقية الحقول تُرسل كما هي
      expect(json['country'], 'SY');
      expect(json['city'], 'D');
    });

    test('toJson keeps real coordinates untouched', () {
      final address = AddressModel(
        addressName: 'H', country: 'SY', city: 'D', area: 'A',
        streetChoice: 'S', buildingDetail: 'B',
        lat: 34.7304, lng: 36.7096,
      );
      final json = address.toJson();
      expect(address.hasCoordinates, isTrue);
      // GeoJSON: الطول أولاً ثم العرض
      expect(json['location']['coordinates'], [36.7096, 34.7304]);
      expect(json['lat'], 34.7304);
      expect(json['lng'], 36.7096);
    });
  });
}
