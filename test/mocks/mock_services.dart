import 'package:mocktail/mocktail.dart';
import 'package:nomnow_app/core/services/auth_service.dart';
import 'package:nomnow_app/core/services/socket_service.dart';
import 'package:nomnow_app/core/services/user_location_service.dart';
import 'package:nomnow_app/features/restaurant/data/services/restaurant_service.dart';
import 'package:nomnow_app/features/favorite/data/services/favorite_service.dart';
import 'package:nomnow_app/features/profile/data/services/profile_service.dart';

class MockAuthService extends Mock implements AuthService {}

class MockSocketService extends Mock implements SocketService {}

class MockRestaurantService extends Mock implements RestaurantService {}

class MockFavoriteService extends Mock implements FavoriteService {}

class MockProfileService extends Mock implements ProfileService {}

class MockUserLocationService extends Mock
    implements UserLocationService {}
