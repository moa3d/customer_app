# إعداد إشعارات Push — تطبيق الزبون (v3.5)

كود Dart **منجَز بالكامل**، وإعداد أندرويد **مكتمل**. ما تبقّى إصلاحان في الباك
(أسفل هذا الملف)، وiOS إن لزم لاحقاً.

## الحالة الآن — الخطوات 1-3 منجزة ✅

| ما كان مطلوباً | الحالة |
|---|---|
| معرّف الحزمة | ✅ `com.nomnow.app` (كان `com.example.nom_now_app`) |
| تسجيل التطبيق في Firebase | ✅ `1:1072753946809:android:a5c74ae5ad9be960172b68` |
| `android/app/google-services.json` | ✅ موجود |
| إضافة Gradle | ✅ مُفعَّلة شرطياً |
| صلاحية `POST_NOTIFICATIONS` | ✅ مُصرَّحة وتُطلب بعد تسجيل الدخول |
| أيقونة إشعار أحادية اللون | ✅ `res/drawable/ic_notification.xml` + `default_notification_icon` |
| قناة `order_status` بأهمية عالية | ✅ تُنشأ في `MainActivity.onCreate` + `default_notification_channel_id` |
| تسجيل إشعارات الخلفية في سجلّ التطبيق | ✅ `onBackgroundMessage` في `lib/core/services/notification_background_handler.dart` |

`Firebase.initializeApp()` صار ينجح على أندرويد، وإضافة `google-services` تولّد
`google_app_id` و`project_id` في موارد البناء (مؤكَّد بعد `flutter build apk --debug`).

### كيف سُجِّل التطبيق بلا دخول الكونسول

مفتاح Admin SDK في `HELPER/` حساب خدمة يملك صلاحية Firebase Management API، فاستُعمل
لتسجيل الحزمة وجلب `google-services.json` برمجياً. المشروع `nomnow-c1fc3` (رقمه
`1072753946809`) يضمّ الآن تطبيقين: `com.nomnow.driver` و`com.nomnow.app`، ولكلٍّ
`appId` مستقل — تسجيل الزبون لم يمسّ تطبيق السائق.

### ما تبقّى

1. **إصلاح حالة الأحرف في الباك** (القسم الأخير من هذا الملف) — يمنع أي اختبار فعلي.
2. **ضبط `FIREBASE_PROJECT_ID` و`FIREBASE_CLIENT_EMAIL` و`FIREBASE_PRIVATE_KEY` على Render**
   — موجودة في `.env` محلياً فقط.

---

## الخطوة 4 — iOS (عند الحاجة)

يحتاج `GoogleService-Info.plist` من نفس الكونسول + شهادة APNs مرفوعة في
Firebase → Project Settings → Cloud Messaging. صلاحية الإشعارات مطلوبة صراحةً على iOS
والكود يطلبها أصلاً عبر `requestPermission`.

---

## ملاحظات لا تحتاج عملاً منك

- **`POST_NOTIFICATIONS`** (أندرويد 13+) صارت مُصرَّحة صراحةً في مانيفست التطبيق
  ولم تعد تعتمد على الدمج من مانيفست حزمة `firebase_messaging` — لأن التطبيق
  صار يطلبها أصلياً (انظر القسم التالي).
- **نصوص الإشعارات عربية فقط** حالياً (مثبّتة في الباك، §7.1 من المواصفة).
- **مفاتيح إعدادات الإشعارات محلية الأثر فقط:** إطفاؤها يمنع تسجيل الإشعار في
  سجلّ التطبيق، ولا يمنع وصول الـ push من الخادم ولا ظهوره في درج النظام —
  الباك لا يملك حقل تفضيلات على `models/User.js` ولا endpoint له. مفتاحا الصوت
  والاهتزاز وشريحة العروض حُذفت من الشاشة لأنها كانت بلا أثر إطلاقاً.
- **`driverSearchStatus: failed`** لا يصله إشعار — موثّق في المواصفة كعمل لاحق.

## صلاحية الإشعارات على أندرويد — مستقلة عن Firebase

`POST_NOTIFICATIONS` صلاحية نظام لا علاقة لها بـ FCM، ولذلك فُصلت عن Firebase تماماً
وصارت تعمل **من اليوم** حتى قبل إنجاز الخطوات أعلاه:

- قناة أصلية في `MainActivity.kt` باسم `com.nomnow.app/notification_permission`
  بثلاث دوال: `status` و`request` و`openSettings`.
- `lib/core/services/notification_permission_service.dart` هو الواجهة من جهة Dart،
  ويحوي تدفّق `maybeAskAfterLogin` كاملاً.
- الحوار التمهيدي يظهر **بعد تسجيل الدخول بنجاح** لا على السبلاش، ويسبق الانتقال
  لشاشة الموقع حتى لا يتكدّس حوارا الصلاحية فوق بعضهما.
- `messaging.requestPermission` في `push_notification_service.dart` صار محروساً
  بـ `if (!Platform.isAndroid)` — وإلا لعاد حوار النظام للظهور على أول إطار فور
  إضافة `google-services.json`، فيُبطل التوقيت المقصود. مسار iOS بلا تغيير.
- شاشة إعدادات الإشعارات تقرأ حالة النظام الحقيقية، وتُعطّل مفاتيحها وتعرض بطاقة
  تحذير بزر إصلاح حين تكون الصلاحية مغلقة.

> ⚠️ منح الصلاحية وحده **لا يُنتج إشعاراً**. وصول الإشعارات ما زال محجوباً بغياب
> `google-services.json` (الخطوات 1-3 أعلاه) وبالعائق في الباك أدناه.

## عائق الباك — عولج ✅

كان `sockets/driver.socket.js` و`restaurant.socket.js` يستدعيان
`require("./services/notification.service")` بينما اسم الملف بحرف `N` كبير،
فيسقط السيرفر على Render (لينكس يفرّق بين حالة الأحرف). الملف الآن
`sockets/services/notification.service.js` بحرف صغير والاستدعاءات تطابقه —
لم يعد هناك ما يمنع الاختبار الفعلي من هذه الجهة.
