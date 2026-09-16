import 'package:flutter_test/flutter_test.dart';

/// ماتشر مخصص للتحقق من أن قيمة معينة ليست null
Matcher isNotNullValue(dynamic value) => isNotNull;

/// Helper لإنشاء Map جاهز لمستخدم وهمي
Map<String, dynamic> createTestUserJson({
  String id = '123',
  String name = 'Test User',
  String phone = '0987654321',
  String gender = 'ذكر',
}) {
  return {
    '_id': id,
    'name': name,
    'phone': phone,
    'gender': gender,
    'country': 'SY',
    'isBanned': false,
    'createdAt': '2025-01-01T00:00:00Z',
  };
}

/// Helper لإنشاء Map جاهز لمطعم وهمي
Map<String, dynamic> createTestRestaurantJson({
  String id = 'rest_1',
  String name = 'Test Restaurant',
}) {
  return {
    '_id': id,
    'name': name,
    'description': 'Test description',
    'image': {'url': 'https://example.com/image.jpg'},
    'rating': 4.5,
  };
}

/// Helper لإنشاء Map جاهز لوجبة وهمية
Map<String, dynamic> createTestMealJson({
  String id = 'meal_1',
  String name = 'Test Meal',
  String restaurantId = 'rest_1',
}) {
  return {
    '_id': id,
    'name': name,
    'description': 'Yummy',
    'image': {'url': 'https://example.com/meal.jpg'},
    'rating': 4.0,
    'price': 5000,
    'time': 20,
    'restaurantId': restaurantId,
    'ingredients': ['Tomato', 'Cheese'],
    'sizes': [{'name': 'Large', 'price': 6000}],
    'extras': [{'name': 'Extra Cheese', 'price': 500}],
  };
}

/// Helper لإنشاء Map جاهز لعنوان وهمي
Map<String, dynamic> createTestAddressJson({
  String id = 'addr_1',
}) {
  return {
    '_id': id,
    'name': 'Home',
    'country': 'Syria',
    'city': 'Damascus',
    'area': 'Mazzah',
    'street': 'Main St',
    'building': '12',
    'isDefault': true,
    'location': {
      'type': 'Point',
      'coordinates': [36.2833, 33.5101],
    },
  };
}

/// Helper لإنشاء Map جاهز لطلب وهمي
Map<String, dynamic> createTestOrderJson({
  String id = 'order_1',
  String status = 'pending',
}) {
  return {
    '_id': id,
    'orderNumber': 'ORD-001',
    'orderStatus': status,
    'totalPrice': 15000,
    'restaurantId': {'name': 'Test Restaurant'},
  };
}
