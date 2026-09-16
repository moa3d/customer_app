class Routes {
  // المسارات التعريفية المستقلة
  static const String splash = '/';
  static const String authSelection = '/auth-selection';
  static const String banned = '/banned';

  static const String welcome = '/welcome';
  static const String selectDisplay = '/select-display';
  static const String selectLanguage = '/select-language';

  // المسارات الأساسية للشريط السفلي (Branches)
  static const String home = '/home';
  static const String cart = '/cart';
  static const String orders = '/orders';
  static const String favorites = '/favorites';

  // مسار الحساب الرئيسي ومساراته الفرعية المنظمة
  static const String account = '/account';
  static const String editProfile = 'edit-profile'; // مسار نسبي (Nested)

  static const String addresses = 'addresses'; // مسار نسبي
  static const String notifications = 'notifications'; // مسار نسبي
  static const String language = 'language'; // مسار نسبي
  static const String support = 'support'; // مسار نسبي
  static const String coupons = 'coupons'; // مسار نسبي

  // مسارات التفاصيل (تفتح فوق الشريط السفلي Push)
  static const String restaurantDetails = '/restaurant-details';
  static const String mealDetails = '/meal-details';
  static const String offers = '/offers';

  // قوائم «عرض المزيد» الكاملة — تُفتح من عناوين أقسام الرئيسية
  static const String allRestaurants = '/home/all-restaurants';
  static const String allMeals = '/home/all-meals';

  // صفحة البحث المستقلة — تُفتح بالنقر على حقل البحث في الرئيسية
  static const String search = '/home/search';

  // مسارات الطلبات
  static const String orderConfirmed = '/order-confirmed';
  static const String orderTracking = '/order-tracking';
}