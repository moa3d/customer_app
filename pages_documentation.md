# NomNow App - Pages Documentation (From Top to Bottom)

## Onboarding Flow (Intro)

---

### 1. Splash Screen
- **File:** `lib/features/intro/presentation/pages/splash_screen.dart`
- **Class:** `SplashScreen`
- **Description:** شاشة البداية تعرض لوجو التطبيق مع تأثير Fade-in/Fade-out. عند اكتمال الأنيميشن، تفحص التوكن:
  - إذا كان المستخدم مسجل دخول → تنتقل إلى `HomeShell`
  - إذا كان أول مرة → تنتقل إلى `WelcomeScreen`
  - إذا كان مستخدم عائد → تنتقل إلى `AuthSelectionScreen`

---

### 2. Welcome Screen
- **File:** `lib/features/intro/presentation/pages/welcome_screen.dart`
- **Class:** `WelcomeScreen`
- **Description:** شاشة ترحيبية تحتوي على صورة خلفية، عنوان ونص فرعي، وزر "Get Started" الذي ينقل إلى `SelectDisplayScreen`.

---

### 3. Select Display Screen
- **File:** `lib/features/intro/presentation/pages/select_display_screen.dart`
- **Class:** `SelectDisplayScreen`
- **Description:** شاشة اختيار المظهر (وضع فاتح / غامق) مع بطاقات عرض. بعد الاختيار ينتقل إلى `SelectLanguageScreen`.

---

### 4. Select Language Screen
- **File:** `lib/features/intro/presentation/pages/select_language_screen.dart`
- **Class:** `SelectLanguageScreen`
- **Description:** شاشة اختيار اللغة (العربية، الإنجليزية، الألمانية). عند المتابعة، يضع `is_first_time=false` في SharedPreferences وينتقل إلى `AuthSelectionScreen`.

---

## Authentication Flow

---

### 5. Auth Selection Screen
- **File:** `lib/features/auth/presentation/pages/auth_selection_screen.dart`
- **Class:** `AuthSelectionScreen`
- **Description:** شاشة الدخول الرئيسية: تعرض لوجو، زر "Login" مع خيارات الهاتف/البريد، خيارات تسجيل الدخول عبر Google/Apple، ورابط للتسجيل. تنتقل إلى `LoginPhoneScreen`، `LoginEmailScreen`، أو `RegisterScreen`.

---

### 6. Login Email Screen
- **File:** `lib/features/auth/presentation/pages/login_email_screen.dart`
- **Class:** `LoginEmailScreen`
- **Description:** شاشة تسجيل الدخول بالبريد الإلكتروني مع حقلي البريد وكلمة المرور والتحقق منهما، رابط "نسيت كلمة المرور"، وزر الإرسال. عند النجاح تنتقل إلى `EmailVerificationScreen` أو `SetLocationScreen`.

---

### 7. Login Phone Screen
- **File:** `lib/features/auth/presentation/pages/login_phone_screen.dart`
- **Class:** `LoginPhoneScreen`
- **Description:** شاشة تسجيل الدخول برقم الهاتف مع حقلي الهاتف وكلمة المرور. عند النجاح تنتقل إلى `PhoneVerificationScreen` أو `SetLocationScreen`.

---

### 8. Register Screen
- **File:** `lib/features/auth/presentation/pages/register_screen.dart`
- **Class:** `RegisterScreen`
- **Description:** شاشة التسجيل: تحتوي على منتقي الصورة الشخصية، وحقول الاسم الكامل، البريد، الهاتف، كلمة المرور، تاريخ الميلاد، واختيار الجنس. تتحقق من جميع الحقول وتستدعي API التسجيل.

---

### 9. Phone Verification Screen
- **File:** `lib/features/auth/presentation/pages/phone_verification_screen.dart`
- **Class:** `PhoneVerificationScreen`
- **Description:** شاشة التحقق من الهاتف عبر OTP (6 أرقام). تملأ OTP تلقائياً إن ورد من السيرفر. عند التحقق تنتقل إلى `SetLocationScreen`.

---

### 10. Email Verification Screen
- **File:** `lib/features/auth/presentation/pages/email_verification_screen.dart`
- **Class:** `EmailVerificationScreen`
- **Description:** شاشة التحقق من البريد عبر OTP (6 أرقام) مع تصميم متحرك وأيقونة بريد. عند التحقق تنتقل إلى `SetLocationScreen` مع مسح رزمة التنقل.

---

### 11. Reset Password Screen
- **File:** `lib/features/auth/presentation/pages/reset_password_screen.dart`
- **Class:** `ResetPasswordScreen`
- **Description:** شاشة إعادة تعيين كلمة المرور مع اختيار طريقة إرسال الكود (بريد/هاتف). تحتوي على حقل إدخال وزر "Send Code".

---

### 12. Banned Account Screen
- **File:** `lib/features/auth/presentation/pages/banned_account_screen.dart`
- **Class:** `BannedAccountScreen`
- **Description:** شاشة الحساب المحظور/المرفوض مع أيقونة الحالة، نص الرسالة، زر التواصل مع الدعم، وزر تسجيل الخروج (يعود إلى AuthSelectionScreen).

---

## Location Setup (First-Time Flow)

---

### 13. Set Location Screen
- **File:** `lib/features/location/presentation/pages/set_location_screen.dart`
- **Class:** `SetLocationScreen`
- **Description:** شاشة إعداد الموقع (التدفق الأولي): تحتوي على `FlutterMap` مع OpenStreetMap، زر GPS، ونموذج عنوان من 6 خطوات (الاسم، الدولة، المدينة، المنطقة، الشارع، المبنى). تعرض `FullAddressSummaryCard` عند الاكتمال.

---

## Main App Shell (Bottom Navigation)

---

### 14. Home Shell
- **File:** `lib/features/home/presentation/pages/home_shell.dart`
- **Class:** `HomeShell`
- **Description:** الغلاف الرئيسي للتطبيق. يحتوي على `StatefulNavigationShell` مع `CustomBottomNavBar` لخمس تبويبات:
  1. **الرئيسية (Home)**
  2. **السلة (Cart)**
  3. **الطلبات (Orders)**
  4. **المفضلة (Favorites)**
  5. **الحساب (Profile)**

---

### 15. Home Page (الرئيسية)
- **File:** `lib/features/home/presentation/pages/home_page.dart`
- **Class:** `HomBody`
- **Description:** الصفحة الرئيسية: تعرض الصورة الرمزية والموقع في AppBar، حقل بحث، بانر ترويجي، أزرار تصفيف أفقية، شبكة وجبات، وقائمة مطاعم عمودية. تجلب البيانات من `RestaurantService` و `AuthService`.

---

### 16. Cart Screen (السلة)
- **File:** `lib/features/cart/presentation/pages/cart_screen.dart`
- **Class:** `CartScreen`
- **Description:** شاشة سلة التسوق: تعرض قائمة المنتجات مع `CartItemsList`، خيارات التوصيل والدفع عبر `CartOptionsSection`، وملخص الفاتورة مع `CartBillSummary`. تعالج حالة السلة الفارغة.

---

### 17. Complete Pay Page (إتمام الدفع)
- **File:** `lib/features/cart/presentation/pages/complete_pay_page.dart`
- **Class:** `CompletePayPage`
- **Description:** شاشة تأكيد الدفع: تعرض بطاقة المبلغ، شبكة طرق الدفع (Credit Card, PayPal, STC Pay, Apple Pay)، البطاقات المحفوظة، نموذج بطاقة جديدة، شارات الأمان، وزر الدفع.

---

### 18. Payment Success Page (نجاح الدفع)
- **File:** `lib/features/cart/presentation/pages/payment_success_page.dart`
- **Class:** `PaymentSucsessPage`
- **Description:** شاشة نجاح الدفع: رأس متحرك للنجاح، معلومات الطلب (الرقم، التاريخ/الوقت)، تفاصيل الطلب قابلة للتبديل، طريقة الدفع، عنوان التوصيل، وقت الوصول المقدر، وأزرار لتتبع الطلب أو العودة للرئيسية.

---

### 19. Orders Screen (الطلبات)
- **File:** `lib/features/orders/presentation/pages/orders_screen.dart`
- **Class:** `OrdersScreen`
- **Description:** شاشة الطلبات مع تبديل التبويبات (الطلبات الحالية / السجل). تعرض `OrderCardItem` للطلبات الحالية و `HistoryCardItem` للطلبات السابقة. تستمع إلى Socket للتحديثات المباشرة.

---

### 20. Order Tracking Screen (تتبع الطلب)
- **File:** `lib/features/orders/presentation/pages/order_tracking_screen.dart`
- **Class:** `OrderTrackingScreen`
- **Description:** شاشة تتبع الطلب المباشر: تعرض بطاقة معلومات السائق، خريطة مع مسافة/وقت الوصول، بطاقة حالة الطلب، بطاقة تأكيد التوصيل (عند وصول السائق)، وتفاصيل المنتجات.

---

### 21. Favorites Screen (المفضلة)
- **File:** `lib/features/favorite/presentation/pages/favorite_screen.dart`
- **Class:** `FavoritesScreen`
- **Description:** شاشة المفضلة مع تبديل التبويبات (مطاعم مفضلة / أطباق مفضلة). تعرض العناصر عبر `FavoriteListItem` مع الصورة، العنوان، التقييم، الوقت، وزر الإعجاب. تدعم التنقل لصفحة الوجبة أو المطعم.

---

### 22. Profile Page (الحساب)
- **File:** `lib/features/profile/presentation/pages/profile_page.dart`
- **Class:** `ProfilePage`
- **Description:** شاشة الحساب: تعرض الصورة الرمزية، الاسم، البريد، وتاريخ العضوية. تحتوي على قائمة خيارات: المعلومات الشخصية، العناوين، طرق الدفع، الإشعارات، اللغة، الدعم. تتضمن زر تسجيل الخروج مع Bottom Sheet تأكيد.

---

### 23. Profile Navigator
- **File:** `lib/features/profile/presentation/pages/profile_navigator.dart`
- **Class:** `ProfileNavigator`
- **Description:** يلف `ProfilePage` ويتعامل مع التنقل الداخلي للخيارات: تعديل الملف الشخصي، العناوين، طرق الدفع، الإشعارات، اللغة، والدعم عبر المسارات الفرعية.

---

## Restaurant & Meal Flow

---

### 24. Restaurant Page
- **File:** `lib/features/restaurant/presentation/pages/restaurant_page.dart`
- **Class:** `ResturantPage`
- **Description:** صفحة تفاصيل المطعم: رأس مع معلومات المطعم، اختيار تبويبات القائمة (3 تبويبات)، شبكة من عناصر القائمة عبر `MenuItemWidget`، وقسم الأطباق المميزة عبر `FeaturedDishWidget`. تحمل القائمة من API.

---

### 25. Meal Details Page
- **File:** `lib/features/meal_selection/presentation/pages/meal_details_page.dart`
- **Class:** `MealDetailsPage`
- **Description:** صفحة تفاصيل الوجبة/الشراء: تدفق متعدد الخطوات (الخطوة 0: إضافة للسلة، الخطوة 1: اختيار الحجم، الخطوة 2: الكمية، الخطوة 3: التخصيص والإضافات، الخطوة 4: المراجعة). تعرض معلومات الوجبة، ملخص السعر، وزر الإضافة للسلة.

---

## Offers Flow

---

### 26. Offers Screen
- **File:** `lib/features/offers/presentation/pages/offers_screen.dart`
- **Class:** `OffersScreen`
- **Description:** شاشة العروض: أزرار تصفيف أفقية (الكل، الوجبات، المشروبات، عشوائي)، قائمة `OfferCard` تعرض صورة المطعم، الاسم، نسبة الخصم، التقييم، وقت التوصيل، وزر الإعجاب. النقر ينتقل إلى `ResturantOffersPage`.

---

### 27. Restaurant Offers Page
- **File:** `lib/features/restaurant_offer/presentation/pages/restaurant_offers_pages.dart`
- **Class:** `ResturantOffersPage`
- **Description:** صفحة عروض المطعم: رأس مع صورة خلفية، اسم المطعم، تقييم، وقت التوصيل، نسبة الخصم. تعرض بطاقة العرض الرئيسية (`MainOfferCard`)، قسم ماذا يشمل العرض، الأطباق المشمولة مع السعر القديم والجديد، شروط العرض (`OfferTermsCard`)، ونصائح (`TipCard`).

---

## Notifications Flow

---

### 28. Notifications Page
- **File:** `lib/features/notifications/presentation/pages/notifications_page.dart`
- **Class:** `NotificationsPage`
- **Description:** شاشة الإشعارات (نسخة): تعرض بطاقات الإشعارات مع تبويبات تصفيف (الكل / غير المقروء)، أزرار "قراءة الكل" و"مسح الكل"، وحالة فارغة. تستخدم بيانات تجريبية.

---

### 29. Notifications Screen
- **File:** `lib/features/notifications/presentation/pages/notifications_screen.dart`
- **Class:** `NotificationsScreen`
- **Description:** شاشة الإشعارات (نسخة بديلة): مشابهة لـ `NotificationsPage` مع تبويبات (الكل/غير المقروء)، بطاقات إشعارات مع إجراءات الحذف/تحديد كمقروء، زر "مسح الكل"، وحالة فارغة.

---

### 30. Notification Settings Page
- **File:** `lib/features/notifications/presentation/pages/notification_settings_page.dart`
- **Class:** `NotificationSettingsPage`
- **Description:** شاشة إعدادات الإشعارات: مفتاح رئيسي (جميع الإشعارات)، مفاتيح لكل فئة (حالة الطلب، التوصيل، العروض)، إعدادات النظام (الصوت، الاهتزاز)، وزر "إرسال إشعار تجريبي".

---

## Settings Flow

---

### 31. Language Page
- **File:** `lib/features/settings/presentation/pages/language_page.dart`
- **Class:** `LanguegeScreen`
- **Description:** شاشة إعدادات اللغة: تعرض بطاقة اللغة الحالية، قائمة راديو للغات (العربية، الإنجليزية، الألمانية) مع إيموجي الأعلام، مربع معلومات توضيحي، إحصائيات الاتجاهات/البلدان، وزر "طلب لغة جديدة". تغيّر اللغة عبر `EasyLocalization`.

---

## Location (Post-Setup)

---

### 32. Add Location Page
- **File:** `lib/features/location/presentation/pages/add_location_page.dart`
- **Class:** `AddLocationPage`
- **Description:** شاشة إضافة عنوان جديد: تعرض قائمة العناوين المحفوظة مع إمكانية الاختيار، تبديل لإضافة عنوان جديد، خريطة تفاعلية، نموذج عنوان من 6 خطوات، وزر تأكيد. تتضمن `FullAddressPreviewCard`.

---

### 33. Location Picker Page
- **File:** `lib/features/location/presentation/pages/location_picker_page.dart`
- **Class:** `LocationPickerPage`
- **Description:** شاشة اختيار الموقع (تعديل/إضافة): مشابهة لـ `SetLocationScreen` مع `FlutterMap`، GPS، نموذج عنوان من 6 خطوات، و `FullAddressSummaryCard`. تملأ البيانات مسبقاً إذا كان التعديل لموقع موجود.

---

## Placeholder (Coming Soon)

---

### 34. Placeholder Page
- **File:** `lib/core/widgets/placeholder_page.dart`
- **Class:** `PlaceholderPage`
- **Description:** صفحة عامة للميزات غير المطورة بعد (المعلومات الشخصية، طرق الدفع، الدعم). تعرض أيقونة "قريباً" ورسالة مع زر رجوع واسم الميزة في AppBar.
