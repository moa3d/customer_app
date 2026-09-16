import 'package:flutter_test/flutter_test.dart';
import 'package:nomnow_app/features/location/presentation/bloc/location_state.dart';
import 'package:nomnow_app/features/location/data/models/address_model.dart';

void main() {
  group('LocationState', () {
    test('LocationInitial is an instance', () {
      expect(LocationInitial(), isA<LocationState>());
    });

    test('LocationLoading is an instance', () {
      expect(LocationLoading(), isA<LocationState>());
    });

    test('LocationSuccess stores addresses', () {
      final addresses = [
        AddressModel(addressName: 'Home', country: 'SY', city: 'D',
            area: 'A', streetChoice: 'S', buildingDetail: 'B'),
      ];
      final state = LocationSuccess(addresses);
      expect(state.addresses.length, 1);
      expect(state.selectedAddress, null);
    });

    test('LocationSuccess can have selectedAddress', () {
      final addr = AddressModel(addressName: 'Home', country: 'SY', city: 'D',
          area: 'A', streetChoice: 'S', buildingDetail: 'B');
      final state = LocationSuccess([addr], selectedAddress: addr);
      expect(state.selectedAddress, addr);
    });

    test('LocationFailure stores error', () {
      final state = LocationFailure('Error loading');
      expect(state.error, 'Error loading');
    });
  });
}
