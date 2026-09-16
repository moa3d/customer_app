# إعدادات مطلوبة قبل البناء — تطبيق المستخدم

> **لا توجد حزم جديدة تُضاف.** المشروع جاهز، لكن أربعة إعدادات لا تُرفع مع الكود
> (مفاتيح وملفات إعداد) ويجب توفيرها محلياً، وإلا بُني التطبيق وعمل — مع خريطة
> فارغة أو إشعارات صامتة وبلا أي رسالة خطأ توضّح السبب.

نظير هذا المستند في تطبيق السائق: `delivery-app-feature-professional-restructure/SETUP.md`.

---

## 1) الملفات المحلية المطلوبة

| الملف | الغرض | الحالة |
|---|---|---|
| `android/local.properties` | مسار Android SDK + `MAPS_API_KEY` لأندرويد | يُنشأ محلياً |
| `ios/Flutter/Maps.xcconfig` | `MAPS_API_KEY` لـ iOS | يُنشأ محلياً (غير متعقَّب في git) |
| `android/app/google-services.json` | إعداد Firebase لأندرويد | ✅ موجود |
| `ios/Runner/GoogleService-Info.plist` | إعداد Firebase لـ iOS | ❌ مفقود — راجع القسم 6 |

> **⚠️ تنبيه على `.gitignore`:** ملف `.gitignore` في هذا المشروع هو قالب Flutter
> الافتراضي، ولا يستثني `android/local.properties` ولا
> `android/app/google-services.json` — بخلاف تطبيق السائق الذي يستثنيهما صراحةً.
> قبل رفع المشروع إلى مستودع git، أضف السطرين وإلا رُفع مفتاح خرائط أندرويد مع
> الكود:
>
> ```gitignore
> /android/local.properties
> /android/app/google-services.json
> ```

---

## 2) مفاتيح خرائط غوغل

المفتاح لا يُكتب داخل الكود على أي من المنصّتين، بل يُحقن من ملف محلي:

| المنصّة | الملف | مسار الحقن |
|---|---|---|
| أندرويد | `android/local.properties` → `MAPS_API_KEY=...` | `app/build.gradle.kts` يقرأه ويضعه في `manifestPlaceholders` → `${MAPS_API_KEY}` في `AndroidManifest.xml` |
| iOS | `ios/Flutter/Maps.xcconfig` → `MAPS_API_KEY = ...` | `Info.plist` (`MapsApiKey = $(MAPS_API_KEY)`) → `AppDelegate.swift` يمرّره إلى `GMSServices.provideAPIKey` |

عند غياب المفتاح لا ينكسر البناء ولا يسقط التطبيق: الخريطة وحدها تظهر رمادية
فارغة **بلا أي رسالة خطأ** — وهذا أول ما يجب فحصه عند "الخريطة لا تعمل عندي".
الحارس في `AppDelegate.swift` يتخطّى `provideAPIKey` بصمت إذا كانت القيمة فارغة.

> **⚠️ مفتاح منفصل لكل منصّة — إلزامي.** مفتاح Google Cloud يقبل **نوع تقييد
> تطبيقات واحداً فقط**: إمّا "Android apps" وإمّا "iOS apps"، لا الاثنين معاً.
> فالمفتاح المشترك إمّا مقيَّد بأندرويد فتظهر خريطة iOS رمادية، وإمّا غير مقيَّد
> فيكون مكشوفاً لمن يستخرجه من الحزمة.

الإعداد المطلوب في Google Cloud Console لكل مفتاح:

| | مفتاح أندرويد | مفتاح iOS |
|---|---|---|
| التقييد | Android apps: `com.nomnow.app` + بصمة SHA-1 | iOS apps: bundle ID `com.nomnow.app` |
| الـAPI المفعَّل | Maps SDK for Android | **Maps SDK for iOS** |

نسيان تفعيل *Maps SDK for iOS* تحديداً هو السبب الأشيع لخريطة رمادية على iOS رغم
صحّة المفتاح.

---

## 3) أندرويد

الإعدادات التالية **مضبوطة أصلاً** في المشروع — القائمة هنا لتوثيق ما لا يجوز
كسره عند التعديل:

### `MainActivity.kt`

```kotlin
class MainActivity : FlutterFragmentActivity()
```

> **⚠️ لا تحوّلها إلى `FlutterActivity`.** حزمة `flutter_stripe` تتطلّب
> `FlutterFragmentActivity`، ومع `FlutterActivity` تفشل شاشة الدفع
> (`presentPaymentSheet`) عند فتحها.

الملف نفسه يستضيف قناة `com.nomnow.app/notification_permission` التي تدير صلاحية
الإشعارات أصلياً على أندرويد (بدل `FirebaseMessaging.requestPermission`) حتى تبقى
قابلة للطلب قبل اكتمال إعداد Firebase. على iOS تُرجع الدارت `unsupported` عمداً،
والصلاحية تُطلب هناك عبر `FirebaseMessaging`.

### `AndroidManifest.xml`

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
<!-- أندرويد 13+ -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

وثلاثة `meta-data` لإشعارات FCM الافتراضية:

| المفتاح | القيمة | ملاحظة |
|---|---|---|
| `default_notification_icon` | `@drawable/ic_notification` | بدونه يستعمل أندرويد أيقونة الإطلاق المعتمة فيظهر مربّع أبيض |
| `default_notification_color` | `@color/notification_accent` (`#F44F27`) | |
| `default_notification_channel_id` | `order_status` | **يجب أن يطابق `ORDER_CHANNEL_ID` في `MainActivity.kt` حرفياً**، وإلا هبط الإشعار إلى قناة احتياطية فلا يظهر منبثقاً |

### `android/app/build.gradle.kts`

`targetSdk = 34`، و `minSdk` من افتراضي Flutter (مطلوب لـ
`flutter_secure_storage`).

### توقيع الإصدار

البناء يقرأ مفتاح التوقيع من `android/key.properties` (غير متعقَّب في git). عند غياب
الملف — أو نقص أحد حقوله الأربعة أو ضياع ملف المفتاح — يعود الإصدار إلى مفاتيح
debug تلقائياً، فيبقى `flutter run --release` يعمل عند كل مطوّر، **لكن حزمة موقَّعة
بـdebug لا تُقبل على Google Play**.

التجهيز مرة واحدة:

```bash
keytool -genkey -v -keystore upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
cp android/key.properties.example android/key.properties   # ثم املأ القيم
```

للتحقّق أن الإصدار صار يلتقط المفتاح:

```bash
cd android && ./gradlew :app:signingReport
```

يجب أن يظهر تحت `Variant: release` السطر `Config: release` لا `Config: debug`.

> **⚠️ ضياع الـkeystore أو كلمة مروره = استحالة تحديث التطبيق على Google Play
> نهائياً.** احتفظ بنسخة احتياطية خارج المشروع وخارج git.

---

## 4) iOS

`ios/Runner/Info.plist` يحوي أصلاً كل ما يلزم:

| المفتاح | السبب |
|---|---|
| `NSPhotoLibraryUsageDescription` | `image_picker` — اختيار صورة الملف الشخصي |
| `NSCameraUsageDescription` | التقاط صورة الملف الشخصي |
| `NSLocationWhenInUseUsageDescription` | عرض المطاعم القريبة وتحديد العنوان على الخريطة |
| `NSLocationAlwaysAndWhenInUseUsageDescription` | متابعة حالة التوصيل أثناء الطلب |
| `UIBackgroundModes: remote-notification` | استقبال إشعارات FCM والتطبيق في الخلفية |
| `MapsApiKey` | يقرأ `$(MAPS_API_KEY)` من `Maps.xcconfig` |

> **لا تضف `UIBackgroundModes: location` هنا.** تطبيق المستخدم لا يتتبّع الموقع في
> الخلفية (بخلاف تطبيق السائق)، وإضافتها تستدعي مراجعة إضافية من App Store بلا
> فائدة.

في Xcode بعد ضبط التوقيع: `+ Capability` ← **Push Notifications** (مطلوبة لـ FCM).

---

## 5) أول بناء على ماك

الملفات المولّدة على ويندوز (`ios/Flutter/Generated.xcconfig` و `.dart_tool/` و
`build/`) تحمل مسارات `C:\flutter\...`، و `ios/Podfile` يقرأ `FLUTTER_ROOT` منها
حرفياً. لذلك بعد نقل المشروع إلى ماك، ابدأ بالتنظيف وإلا فشل `pod install` برسالة
`FLUTTER_ROOT not found`:

```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
open ios/Runner.xcworkspace   # الـworkspace لا الـxcodeproj
```

- لا يوجد `Podfile.lock` في المشروع بعد — أول `pod install` هو الذي ينشئه.
- **التوقيع:** `Runner` ← Signing & Capabilities ← اختر **Team**. لا يوجد
  `DEVELOPMENT_TEAM` محفوظ في المشروع؛ المحاكي يعمل بدونه، الجهاز الحقيقي لا.
- **لا تخفّض** `platform :ios, '15.0'` في `Podfile` ولا
  `IPHONEOS_DEPLOYMENT_TARGET = 15.0`، ولا تحذف `use_frameworks!` — الثلاثة
  مطلوبة لـ `google_maps_flutter` و Firebase 15 و `flutter_stripe`.

---

## 6) الإشعارات على iOS — غير مكتملة بعد

`firebase_core` و `firebase_messaging` مضافتان، وأندرويد يعمل عبر
`android/app/google-services.json` الموجود. أما iOS فينقصه ثلاثة أشياء:

1. تسجيل تطبيق iOS بالـbundle ID `com.nomnow.app` في مشروع Firebase
   `nomnow-c1fc3`، وتنزيل `GoogleService-Info.plist` إلى `ios/Runner/`
   **وإضافته إلى هدف Runner من داخل Xcode** — نسخه إلى المجلد وحده لا يكفي، لن
   يُحزَم مع التطبيق.
2. مفتاح APNs (‎.p8) من Apple Developer، مرفوعاً في Firebase ←
   Project Settings ← Cloud Messaging. بدونه لا يصل أي إشعار على iOS مهما كان
   الكود صحيحاً.
3. Xcode: `+ Capability` ← **Push Notifications**.

`Firebase.initializeApp()` في `PushNotificationService` محاط بـ`try/catch`، وعند
فشله يبقى `isAvailable == false` ويعمل التطبيق بالسوكيت وحده — أي **غياب هذه
الإعدادات لا يُسقط التطبيق ولا يؤخّر إقلاعه**، الإشعارات وحدها تبقى معطّلة.

---

## 7) الدفع وعنوان الخادم

| | الموضع | الحالة |
|---|---|---|
| مفتاح Stripe العلني | `lib/core/config/payment_config.dart` | مفتاح **اختبار** (`pk_test_...`) — استبدله بـ `pk_live_...` قبل النشر، وتأكّد أن الباك يستخدم المفتاح السرّي المقابل لنفس البيئة |
| عنوان الـAPI | `lib/core/network/dio_client.dart` → `baseUrl` | مثبَّت على `https://nomnow-o4ba.onrender.com/` — تغيير البيئة يتم بتعديل هذا الثابت |

المفتاح العلني لـ Stripe مصمَّم ليكون مكشوفاً في التطبيق، فوجوده في الكود ليس
تسريباً — المهم ألّا يكون **المفتاح السرّي** في أي مكان هنا.

---

## 8) تحقّق سريع بعد الإعداد

| السيناريو | النتيجة المتوقّعة |
|---|---|
| فتح شاشة تحديد العنوان (أندرويد و iOS) | تظهر الخريطة بتفاصيلها، لا مساحة رمادية فارغة |
| تشغيل iOS بلا `Maps.xcconfig` | التطبيق يعمل كاملاً والخريطة وحدها فارغة (لا سقوط) |
| أول تسجيل دخول على أندرويد 13+ | يظهر حوار صلاحية الإشعارات (لا على شاشة السبلاش) |
| تغيّر حالة الطلب والتطبيق مصغَّر | يصل إشعار منبثق بأيقونة ملوّنة صحيحة لا مربّع أبيض |
| فتح شاشة الدفع | تُفتح شاشة Stripe دون انهيار (اختبار `FlutterFragmentActivity`) |
| اختيار صورة الملف الشخصي على iOS | يظهر حوار صلاحية الصور لا انهيار صامت |
| تشغيل بلا إعداد Firebase على iOS | التطبيق يعمل والإشعارات وحدها معطّلة |
