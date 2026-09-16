import 'package:flutter_test/flutter_test.dart';
import 'package:nomnow_app/features/location/presentation/bloc/location_event.dart';
import 'package:nomnow_app/features/location/data/models/address_model.dart';

void main() {
  group('LocationEvent', () {
    test('ConfirmLocationEvent stores address', () {
      final addr = AddressModel(addressName: 'Home', country: 'SY', city: 'D',
          area: 'A', streetChoice: 'S', buildingDetail: 'B');
      final event = ConfirmLocationEvent(addr);
      expect(event.address, addr);
    });

    test('LoadAddressesEvent is an instance', () {
      expect(LoadAddressesEvent(), isA<LocationEvent>());
    });

    test('SetDefaultAddressEvent stores addressId', () {
      expect(SetDefaultAddressEvent('addr1').addressId, 'addr1');
    });

    // لا يوجد UpdateLocationEvent — ConfirmLocationEvent يغطي التعديل عبر id
    test('ConfirmLocationEvent carries the id when editing', () {
      final addr = AddressModel(id: 'addr_9', addressName: 'Work',
          country: 'SY', city: 'D', area: 'A', streetChoice: 'S',
          buildingDetail: 'B');
      final event = ConfirmLocationEvent(addr);
      expect(event.address.id, 'addr_9');
    });

    test('DeleteLocationEvent stores addressId', () {
      expect(DeleteLocationEvent('addr2').addressId, 'addr2');
    });

    test('SelectAddressEvent stores address', () {
      final addr = AddressModel(addressName: 'Home', country: 'SY', city: 'D',
          area: 'A', streetChoice: 'S', buildingDetail: 'B');
      final event = SelectAddressEvent(addr);
      expect(event.address, addr);
    });
  });
}
