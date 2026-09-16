import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:nomnow_app/core/services/auth_service.dart';
import 'package:nomnow_app/features/location/presentation/bloc/location_bloc.dart';
import 'package:nomnow_app/features/location/presentation/bloc/location_event.dart';
import 'package:nomnow_app/features/location/presentation/bloc/location_state.dart';
import 'package:nomnow_app/features/location/data/models/address_model.dart';
import 'package:dio/dio.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockAuthService mockAuth;
  late LocationBloc bloc;

  setUpAll(() {
    registerFallbackValue(AddressModel(
      addressName: '',
      country: '',
      city: '',
      area: '',
      streetChoice: '',
      buildingDetail: '',
    ));
  });

  setUp(() {
    mockAuth = MockAuthService();
    bloc = LocationBloc(mockAuth);
  });

  tearDown(() => bloc.close());

  AddressModel makeAddress({
    String? id = 'addr_1',
    String name = 'Home',
    String city = 'Damascus',
    String area = 'Mazzeh',
    bool isDefault = true,
  }) =>
      AddressModel(
        addressName: name,
        country: 'Syria',
        city: city,
        area: area,
        streetChoice: 'Main St',
        buildingDetail: '12',
        lat: 33.5101,
        lng: 36.2833,
        id: id,
        isDefault: isDefault,
      );

  Response makeResponse({
    required int statusCode,
    required List<Map<String, dynamic>> addresses,
  }) {
    return Response(
      requestOptions: RequestOptions(path: ''),
      statusCode: statusCode,
      data: {'addresses': addresses},
    );
  }

  List<Map<String, dynamic>> addressJsonList([int count = 1]) {
    return List.generate(count, (i) {
      return {
        '_id': 'addr_${i + 1}',
        'name': 'Address ${i + 1}',
        'country': 'Syria',
        'city': 'Damascus',
        'area': 'Area ${i + 1}',
        'street': 'Street ${i + 1}',
        'building': '${i + 10}',
        'isDefault': i == 0,
        'location': {
          'type': 'Point',
          'coordinates': [36.2833, 33.5101],
        },
      };
    });
  }

  group('LocationBloc — LoadAddressesEvent', () {
    blocTest<LocationBloc, LocationState>(
      'emits [Loading, Success] with addresses on success',
      build: () {
        when(() => mockAuth.getUserAddresses()).thenAnswer(
          (_) async => makeResponse(
            statusCode: 200,
            addresses: addressJsonList(2),
          ),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(LoadAddressesEvent()),
      expect: () => [
        isA<LocationLoading>(),
        isA<LocationSuccess>()
            .having((s) => s.addresses.length, 'count', 2)
            .having(
                (s) => s.selectedAddress?.addressName, 'selected', 'Address 1'),
      ],
    );

    blocTest<LocationBloc, LocationState>(
      'selects default address when one exists',
      build: () {
        when(() => mockAuth.getUserAddresses()).thenAnswer(
          (_) async => makeResponse(
            statusCode: 200,
            addresses: [
              {...addressJsonList(2)[0], 'isDefault': false},
              {...addressJsonList(2)[1], 'isDefault': true, 'name': 'Work'},
            ],
          ),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(LoadAddressesEvent()),
      expect: () => [
        isA<LocationLoading>(),
        isA<LocationSuccess>().having(
            (s) => s.selectedAddress?.addressName, 'selected', 'Work'),
      ],
    );

    blocTest<LocationBloc, LocationState>(
      'emits [Loading, Failure] on network error',
      build: () {
        when(() => mockAuth.getUserAddresses()).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            response: Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 500,
              data: {'message': 'Server error'},
            ),
          ),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(LoadAddressesEvent()),
      expect: () => [
        isA<LocationLoading>(),
        isA<LocationFailure>()
            .having((s) => s.error, 'error', contains('Server error')),
      ],
    );

    blocTest<LocationBloc, LocationState>(
      'handles empty addresses list',
      build: () {
        when(() => mockAuth.getUserAddresses()).thenAnswer(
          (_) async => makeResponse(statusCode: 200, addresses: []),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(LoadAddressesEvent()),
      expect: () => [
        isA<LocationLoading>(),
        isA<LocationSuccess>()
            .having((s) => s.addresses.length, 'count', 0)
            .having((s) => s.selectedAddress, 'selected', isNull),
      ],
    );
  });

  group('LocationBloc — ConfirmLocationEvent', () {
    blocTest<LocationBloc, LocationState>(
      'adds address and sets it as selected',
      build: () {
        when(() => mockAuth.addOrUpdateAddress(any())).thenAnswer(
          (_) async => makeResponse(
            statusCode: 201,
            addresses: addressJsonList(1),
          ),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(ConfirmLocationEvent(makeAddress())),
      expect: () => [
        isA<LocationLoading>(),
        isA<LocationSuccess>()
            .having((s) => s.addresses.length, 'count', 1)
            .having(
                (s) => s.selectedAddress?.addressName, 'selected', 'Address 1'),
      ],
    );

    blocTest<LocationBloc, LocationState>(
      'rejects a 6th address and keeps the list visible',
      build: () {
        return bloc;
      },
      seed: () => LocationSuccess(
        List.generate(5, (i) => makeAddress(id: 'addr_${i + 1}', name: 'A${i + 1}')),
        selectedAddress: makeAddress(),
      ),
      act: (bloc) => bloc.add(ConfirmLocationEvent(makeAddress(id: ''))),
      expect: () => [
        isA<LocationFailure>()
            .having((s) => s.error, 'error', 'max_addresses_allowed'),
        // سابقاً كان emit(state) يُلغى بالمقارنة فتبقى الشاشة على الفشل
        isA<LocationSuccess>()
            .having((s) => s.addresses.length, 'list kept', 5),
      ],
      verify: (_) {
        // الحارس يمنع رحلة شبكة مرفوضة سلفاً
        verifyNever(() => mockAuth.addOrUpdateAddress(any()));
      },
    );

    blocTest<LocationBloc, LocationState>(
      'emits failure with the backend message and no recovery when no previous list',
      build: () {
        when(() => mockAuth.addOrUpdateAddress(any())).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            response: Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 400,
              data: {'message': 'Invalid data'},
            ),
          ),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(ConfirmLocationEvent(makeAddress())),
      expect: () => [
        isA<LocationLoading>(),
        isA<LocationFailure>()
            .having((s) => s.error, 'backend message', 'Invalid data'),
      ],
    );

    blocTest<LocationBloc, LocationState>(
      'restores the previous list on failure instead of refetching',
      build: () {
        when(() => mockAuth.addOrUpdateAddress(any())).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            response: Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 400,
              data: {'message': 'Invalid data'},
            ),
          ),
        );
        return bloc;
      },
      seed: () => LocationSuccess(
        addressJsonList(2).map(AddressModel.fromJson).toList(),
      ),
      act: (bloc) => bloc.add(ConfirmLocationEvent(makeAddress())),
      expect: () => [
        isA<LocationLoading>(),
        isA<LocationFailure>(),
        // القائمة القديمة تعود بلا نداء شبكة جديد
        isA<LocationSuccess>()
            .having((s) => s.addresses.length, 'restored list', 2),
      ],
      verify: (_) {
        verifyNever(() => mockAuth.getUserAddresses());
      },
    );

    blocTest<LocationBloc, LocationState>(
      'allows editing an existing address even at the 5 address limit',
      build: () {
        when(() => mockAuth.addOrUpdateAddress(any())).thenAnswer(
          (_) async =>
              makeResponse(statusCode: 200, addresses: addressJsonList(5)),
        );
        return bloc;
      },
      seed: () => LocationSuccess(
        addressJsonList(5).map(AddressModel.fromJson).toList(),
      ),
      act: (bloc) => bloc.add(ConfirmLocationEvent(makeAddress(id: 'addr_3'))),
      expect: () => [
        isA<LocationLoading>(),
        // العنوان المُعدَّل هو المختار، لا الأخير في القائمة
        isA<LocationSuccess>()
            .having((s) => s.selectedAddress?.id, 'selected', 'addr_3'),
      ],
    );
  });

  group('LocationBloc — SetDefaultAddressEvent', () {
    blocTest<LocationBloc, LocationState>(
      'sets the new default and updates selectedAddress',
      build: () {
        when(() => mockAuth.setDefaultAddress('addr_2')).thenAnswer(
          (_) async => makeResponse(
            statusCode: 200,
            addresses: [
              {...addressJsonList(2)[0], 'isDefault': false},
              {...addressJsonList(2)[1], 'isDefault': true, 'name': 'Work'},
            ],
          ),
        );
        return bloc;
      },
      seed: () => LocationSuccess(
        addressJsonList(2).map((j) => AddressModel.fromJson(j)).toList(),
        selectedAddress: AddressModel.fromJson(addressJsonList(2)[0]),
      ),
      act: (bloc) => bloc.add(SetDefaultAddressEvent('addr_2')),
      expect: () => [
        isA<LocationSuccess>().having(
            (s) => s.selectedAddress?.addressName, 'selected', 'Work'),
      ],
    );
  });

  group('LocationBloc — DeleteLocationEvent', () {
    blocTest<LocationBloc, LocationState>(
      'deletes address and selects next default',
      build: () {
        when(() => mockAuth.deleteAddress('addr_1')).thenAnswer(
          (_) async => makeResponse(
            statusCode: 200,
            addresses: [addressJsonList(2)[1]],
          ),
        );
        return bloc;
      },
      seed: () => LocationSuccess(
        addressJsonList(2).map((j) => AddressModel.fromJson(j)).toList(),
        selectedAddress: AddressModel.fromJson(addressJsonList(2)[0]),
      ),
      act: (bloc) => bloc.add(DeleteLocationEvent('addr_1')),
      expect: () => [
        isA<LocationSuccess>()
            .having((s) => s.addresses.length, 'count', 1)
            .having(
                (s) => s.selectedAddress?.addressName, 'selected', 'Address 2'),
      ],
    );

    blocTest<LocationBloc, LocationState>(
      'prevents deleting the only address',
      build: () => bloc,
      seed: () => LocationSuccess(
        [makeAddress()],
        selectedAddress: makeAddress(),
      ),
      act: (bloc) => bloc.add(DeleteLocationEvent('addr_1')),
      expect: () => [
        // بلا تهيئة EasyLocalization في اختبار البلوك تُعيد ‎.tr()‎ المفتاح نفسه
        isA<LocationFailure>().having(
            (s) => s.error, 'error', contains('cannot_delete_only_address')),
        isA<LocationSuccess>(),
      ],
      verify: (_) {
        // الحارس يمنع النداء قبل أن يصل الباك
        verifyNever(() => mockAuth.deleteAddress(any()));
      },
    );
  });

  group('LocationBloc — SelectAddressEvent', () {
    blocTest<LocationBloc, LocationState>(
      'selects a different address',
      build: () => bloc,
      seed: () {
        final addrs = addressJsonList(2).map((j) => AddressModel.fromJson(j)).toList();
        return LocationSuccess(addrs, selectedAddress: addrs[0]);
      },
      act: (bloc) {
        final addrs = addressJsonList(2).map((j) => AddressModel.fromJson(j)).toList();
        bloc.add(SelectAddressEvent(addrs[1]));
      },
      expect: () => [
        isA<LocationSuccess>().having(
          (s) => s.selectedAddress?.addressName,
          'selected',
          'Address 2',
        ),
      ],
    );
  });
}
