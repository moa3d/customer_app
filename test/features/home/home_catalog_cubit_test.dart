import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nomnow_app/core/services/user_location_service.dart';
import 'package:nomnow_app/features/home/data/models/catalog_sort.dart';
import 'package:nomnow_app/features/home/presentation/cubit/home_catalog_cubit.dart';

import '../../mocks/mock_services.dart';

Response<dynamic> _response(Map<String, dynamic> data) => Response(
      requestOptions: RequestOptions(path: '/'),
      statusCode: 200,
      data: data,
    );

Map<String, dynamic> _food({
  required String id,
  required String restaurantId,
  int? discount,
}) =>
    {
      '_id': id,
      'name': 'وجبة $id',
      'price': 5000,
      'time': 20,
      'rating': 4,
      'restaurantId': {'_id': restaurantId, 'name': 'مطعم $restaurantId'},
      if (discount != null)
        'promotions': [
          {'type': 'discount', 'discountValue': discount},
        ],
    };

Map<String, dynamic> _restaurant(String id) =>
    {'_id': id, 'name': 'مطعم $id', 'rating': 4.5};

void main() {
  late MockRestaurantService service;
  late MockUserLocationService location;

  /// آخر قيمة sort وصلت إلى /restaurant
  Object? capturedRestaurantSort() => verify(() => service.getAllRestaurants(
        lat: any(named: 'lat'),
        lng: any(named: 'lng'),
        sort: captureAny(named: 'sort'),
        forceRefresh: any(named: 'forceRefresh'),
      )).captured.last;

  Object? capturedFoodMainCategory() => verify(() => service.getAllFood(
        lat: any(named: 'lat'),
        lng: any(named: 'lng'),
        sort: any(named: 'sort'),
        mainCategory: captureAny(named: 'mainCategory'),
        forceRefresh: any(named: 'forceRefresh'),
      )).captured.last;

  void stubCatalog({
    List<Map<String, dynamic>>? restaurants,
    List<Map<String, dynamic>>? foods,
    bool locationUsed = true,
    String? restaurantSignal,
    String? foodSignal,
  }) {
    when(() => service.getAllRestaurants(
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          sort: any(named: 'sort'),
          forceRefresh: any(named: 'forceRefresh'),
        )).thenAnswer((_) async => _response({
          'restaurant': restaurants ?? [_restaurant('r1')],
          'locationUsed': locationUsed,
          // الحقل غائب افتراضياً — كما يفعل الباك الحالي قبل شحن الإصلاح
          'sortSignal': ?restaurantSignal,
        }));

    when(() => service.getAllFood(
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          sort: any(named: 'sort'),
          mainCategory: any(named: 'mainCategory'),
          forceRefresh: any(named: 'forceRefresh'),
        )).thenAnswer((_) async => _response({
          'foods': foods ?? [_food(id: 'f1', restaurantId: 'r1')],
          'locationUsed': locationUsed,
          'sortSignal': ?foodSignal,
        }));
  }

  setUp(() {
    service = MockRestaurantService();
    location = MockUserLocationService();

    when(() => location.resolve())
        .thenAnswer((_) async => const UserCoords(33.51, 36.29));
    when(() => location.lastAddressLabel).thenReturn('دمشق - المزة');

    when(() => service.getMainCategories(
            forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => _response({
              'success': true,
              'mainCategories': [
                {'_id': 'cat_1', 'name': 'وجبات سريعة'},
                {'_id': 'cat_2', 'name': 'مشاوي'},
              ],
            }));

    stubCatalog();
  });

  HomeCatalogCubit build() =>
      HomeCatalogCubit(service: service, locationService: location);

  group('HomeCatalogCubit — الترتيب', () {
    // أكثر نقطة يقع فيها الخطأ: «الأقرب» ليس sort=nearest بل غياب البارامتر.
    test('الأقرب لا يرسل بارامتر sort إطلاقاً', () async {
      final cubit = build();
      await cubit.loadInitial();

      expect(cubit.state.sort, CatalogSort.nearest);
      expect(capturedRestaurantSort(), isNull);

      await cubit.close();
    });

    test('الأعلى تقييماً يرسل sort=rating', () async {
      final cubit = build();
      await cubit.loadInitial();
      await cubit.changeSort(CatalogSort.topRated);

      expect(capturedRestaurantSort(), 'rating');

      await cubit.close();
    });

    test('الأشهر يرسل sort=popular', () async {
      final cubit = build();
      await cubit.loadInitial();
      await cubit.changeSort(CatalogSort.popular);

      expect(capturedRestaurantSort(), 'popular');

      await cubit.close();
    });

    test('اختيار الترتيب المفعّل نفسه لا يعيد الجلب', () async {
      final cubit = build();
      await cubit.loadInitial();
      clearInteractions(service);

      await cubit.changeSort(CatalogSort.nearest);

      verifyNever(() => service.getAllRestaurants(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            sort: any(named: 'sort'),
            forceRefresh: any(named: 'forceRefresh'),
          ));

      await cubit.close();
    });
  });

  group('HomeCatalogCubit — القسم العام', () {
    test('يرسل mainCategory ويضيّق المطاعم على الظاهرة في الوجبات', () async {
      final cubit = build();
      await cubit.loadInitial();

      // الباك لا يدعم mainCategory على /restaurant، فيعيد المطاعم الثلاثة
      stubCatalog(
        restaurants: [_restaurant('r1'), _restaurant('r2'), _restaurant('r3')],
        foods: [
          _food(id: 'f1', restaurantId: 'r1'),
          _food(id: 'f2', restaurantId: 'r3'),
        ],
      );
      await cubit.selectMainCategory('cat_1');

      expect(capturedFoodMainCategory(), 'cat_1');
      expect(cubit.state.meals.length, 2);
      // r2 لا يقدّم شيئاً في هذا القسم فيسقط من الشريط
      expect(cubit.state.restaurants.map((r) => r.id), ['r1', 'r3']);
      // القائمة الخام تبقى كاملة لتُستخدم عند إزالة الفلتر
      expect(cubit.state.allRestaurants.length, 3);

      await cubit.close();
    });

    test('العودة إلى «الكل» تُسقط البارامتر وتُعيد كل المطاعم', () async {
      final cubit = build();
      await cubit.loadInitial();
      await cubit.selectMainCategory('cat_1');

      stubCatalog(
        restaurants: [_restaurant('r1'), _restaurant('r2')],
        foods: [_food(id: 'f1', restaurantId: 'r1')],
      );
      await cubit.selectMainCategory(null);

      expect(capturedFoodMainCategory(), isNull);
      expect(cubit.state.mainCategoryId, isNull);
      expect(cubit.state.restaurants.length, 2);

      await cubit.close();
    });

    test('اسم القسم المختار يُقرأ من الأقسام المجلوبة', () async {
      final cubit = build();
      await cubit.loadInitial();
      await cubit.selectMainCategory('cat_2');

      expect(cubit.state.selectedMainCategoryName, 'مشاوي');

      await cubit.close();
    });
  });

  group('HomeCatalogCubit — فلتر العروض', () {
    test('يفلتر محلياً بلا أي نداء شبكة', () async {
      final cubit = build();
      stubCatalog(
        restaurants: [_restaurant('r1'), _restaurant('r2')],
        foods: [
          _food(id: 'f1', restaurantId: 'r1', discount: 20),
          _food(id: 'f2', restaurantId: 'r2'),
        ],
      );
      await cubit.loadInitial();
      clearInteractions(service);

      cubit.toggleOffersOnly();

      expect(cubit.state.meals.map((m) => m.id), ['f1']);
      expect(cubit.state.restaurants.map((r) => r.id), ['r1']);
      verifyNever(() => service.getAllFood(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            sort: any(named: 'sort'),
            mainCategory: any(named: 'mainCategory'),
            forceRefresh: any(named: 'forceRefresh'),
          ));

      // الإلغاء يستعيد القائمتين من الذاكرة
      cubit.toggleOffersOnly();
      expect(cubit.state.meals.length, 2);
      expect(cubit.state.restaurants.length, 2);

      await cubit.close();
    });
  });

  group('HomeCatalogCubit — الموقع', () {
    test('يقرأ locationUsed ونص العنوان من الجلب', () async {
      final cubit = build();
      await cubit.loadInitial();

      expect(cubit.state.locationUsed, isTrue);
      expect(cubit.state.addressLabel, 'دمشق - المزة');

      await cubit.close();
    });

    test('بلا إحداثيات لا يُرسل lat/lng ويعود locationUsed=false', () async {
      when(() => location.resolve()).thenAnswer((_) async => null);
      when(() => location.lastAddressLabel).thenReturn(null);
      stubCatalog(locationUsed: false);

      final cubit = build();
      await cubit.loadInitial();

      final coords = verify(() => service.getAllRestaurants(
            lat: captureAny(named: 'lat'),
            lng: captureAny(named: 'lng'),
            sort: any(named: 'sort'),
            forceRefresh: any(named: 'forceRefresh'),
          )).captured;
      expect(coords, everyElement(isNull));
      expect(cubit.state.locationUsed, isFalse);

      await cubit.close();
    });

    test('يحلّ الإحداثيات مرة واحدة لكل الجلبات', () async {
      final cubit = build();
      await cubit.loadInitial();
      await cubit.changeSort(CatalogSort.popular);
      await cubit.changeSort(CatalogSort.topRated);

      // إعادة قراءة الـ GPS مع كل تبديل فلتر هدرٌ للبطارية وتأخيرٌ ظاهر
      verify(() => location.resolve()).called(1);

      await cubit.close();
    });
  });

  group('HomeCatalogCubit — إشارة الترتيب', () {
    // أهم اختبار في المجموعة: الحقل غير مشحون في الباك بعد، ولا يجوز أن
    // يُظهر غيابه تنبيهاً كاذباً للمستخدم اليوم.
    test('غياب sortSignal يعني وجود إشارة', () async {
      final cubit = build();
      await cubit.loadInitial();
      await cubit.changeSort(CatalogSort.topRated);

      expect(cubit.state.sortHasNoSignal, isFalse);

      await cubit.close();
    });

    test('اتفاق الردَّين على none يرفع العلَم', () async {
      final cubit = build();
      await cubit.loadInitial();
      stubCatalog(restaurantSignal: 'none', foodSignal: 'none');
      await cubit.changeSort(CatalogSort.topRated);

      expect(cubit.state.sortHasNoSignal, isTrue);

      await cubit.close();
    });

    // المحوران مستقلان: تقييم المطعم قد يكون صفراً بينما لأصنافه تقييمات،
    // فوجود إشارة في أحدهما يعني أن الفلتر فعل شيئاً.
    test('إشارة في أحد الردَّين تكفي لإسكات التنبيه', () async {
      final cubit = build();
      await cubit.loadInitial();
      stubCatalog(restaurantSignal: 'none', foodSignal: 'ok');
      await cubit.changeSort(CatalogSort.topRated);

      expect(cubit.state.sortHasNoSignal, isFalse);

      await cubit.close();
    });

    test('«الأقرب» لا يرفع العلَم أبداً — لا يعتمد تقييماً', () async {
      final cubit = build();
      stubCatalog(restaurantSignal: 'none', foodSignal: 'none');
      await cubit.loadInitial();

      expect(cubit.state.sort, CatalogSort.nearest);
      expect(cubit.state.sortHasNoSignal, isFalse);

      await cubit.close();
    });

    test('العودة إلى «الأقرب» تُصفّر العلَم', () async {
      final cubit = build();
      await cubit.loadInitial();
      stubCatalog(restaurantSignal: 'none', foodSignal: 'none');
      await cubit.changeSort(CatalogSort.popular);
      expect(cubit.state.sortHasNoSignal, isTrue);

      await cubit.changeSort(CatalogSort.nearest);
      expect(cubit.state.sortHasNoSignal, isFalse);

      await cubit.close();
    });
  });

  group('HomeCatalogCubit — أولوية التنبيهين', () {
    // القاعدة: لا يُعرض تنبيهان معاً، وتنبيه الموقع يسبق لأنه قابل للإصلاح
    // من المستخدم بينما غياب التقييمات ليس بيده شيء.
    test('بلا موقع: تنبيه الموقع وحده حتى لو كانت الإشارة none', () async {
      when(() => location.resolve()).thenAnswer((_) async => null);
      when(() => location.lastAddressLabel).thenReturn(null);
      stubCatalog(
        locationUsed: false,
        restaurantSignal: 'none',
        foodSignal: 'none',
      );

      final cubit = build();
      await cubit.loadInitial();
      await cubit.changeSort(CatalogSort.topRated);

      expect(cubit.state.showLocationNotice, isTrue);
      expect(cubit.state.showSortNotice, isFalse);

      await cubit.close();
    });

    test('مع موقع وإشارة none: تنبيه الترتيب وحده', () async {
      final cubit = build();
      await cubit.loadInitial();
      stubCatalog(restaurantSignal: 'none', foodSignal: 'none');
      await cubit.changeSort(CatalogSort.topRated);

      expect(cubit.state.showLocationNotice, isFalse);
      expect(cubit.state.showSortNotice, isTrue);

      await cubit.close();
    });

    test('الحالة السليمة: لا تنبيه إطلاقاً', () async {
      final cubit = build();
      await cubit.loadInitial();
      stubCatalog(restaurantSignal: 'ok', foodSignal: 'ok');
      await cubit.changeSort(CatalogSort.topRated);

      expect(cubit.state.showLocationNotice, isFalse);
      expect(cubit.state.showSortNotice, isFalse);

      await cubit.close();
    });

  });

  group('HomeCatalogCubit — الجلسة', () {
    // الـ cubit عام بينما HomBody يُعاد إنشاؤه عند تسجيل خروج ثم دخول:
    // بلا تصفير يرث الحساب الجديد قوائم السابق وإحداثياته.
    test('إعادة التحميل تُصفّر الحالة وتُعيد حلّ الإحداثيات', () async {
      final cubit = build();
      await cubit.loadInitial();
      await cubit.selectMainCategory('cat_1');
      cubit.toggleOffersOnly();

      await cubit.loadInitial();

      expect(cubit.state.mainCategoryId, isNull);
      expect(cubit.state.offersOnly, isFalse);
      expect(cubit.state.sort, CatalogSort.nearest);
      verify(() => location.resolve()).called(2);

      await cubit.close();
    });
  });

  group('HomeCatalogCubit — الأخطاء', () {
    test('فشل القوائم يُسجَّل في error ويُنهي التحميل', () async {
      when(() => service.getAllRestaurants(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            sort: any(named: 'sort'),
            forceRefresh: any(named: 'forceRefresh'),
          )).thenThrow(Exception('network down'));

      final cubit = build();
      await cubit.loadInitial();

      expect(cubit.state.error, isNotNull);
      expect(cubit.state.isLoading, isFalse);

      await cubit.close();
    });

    // شريط الأقسام تحسين لا شرط: فشله لا يجوز أن يُسقط الشاشة
    test('فشل الأقسام لا يمنع ظهور القوائم', () async {
      when(() => service.getMainCategories(
              forceRefresh: any(named: 'forceRefresh')))
          .thenThrow(Exception('boom'));

      final cubit = build();
      await cubit.loadInitial();

      expect(cubit.state.mainCategories, isEmpty);
      expect(cubit.state.error, isNull);
      expect(cubit.state.meals, isNotEmpty);

      await cubit.close();
    });
  });
}
