# تقرير تدقيق — customer_app / nomnow_app (تدقيق بفرقة + تفنيد + مقارنة)

## ملخص تنفيذي
تطبيق زبون Flutter (`Bloc/Cubit + go_router + Dio + Stripe + socket + FCM`)، 162 ملف Dart. دققته فرقة 4 صيادين مستقلين (مالي، Bloc، شبكة/أمان، معمارية) ثم مُفنّد مستقل حاول إسقاط أخطر 6 ادعاءات، ثم وحدت النتائج مع التحقق اليدوي من الحرجة. الحالة: **الدفع بالبطاقة خطر حقيقي** — دفعة Stripe تتم ثم يفشل إرسال الطلب بلا تعويض وإعادة المحاولة تدفع ثانية (C-1)، مع غياب idempotency على REST والسوكيت معاً (C-3)؛ وتسريب OTP في body الدخول يلغي قيمة SMS (C-2)؛ والموقع معطل على iOS لغياب مفاتيح `Info.plist` (C-4). البنية فيها نقاط مضيئة حقيقية: التوكن في التخزين الآمن مع ترحيل، والعميل لا يرسل أي مبلغ (الباك يحسب)، و`AppError` يفلتر التقني.

| الخطورة | العدد |
|---|---|
| 🔴 حرجة | 4 |
| 🟠 عالية | 10 |
| 🟡 متوسطة | 10 |
| 🔵 منخفضة | 8 |

**نطاق الفحص:** قراءة كاملة لمسارات `cart` (البلوك والحالة والمستودع والفواتير)، `orders` (المستودع والتتبع والتأكيد)، `auth` (شاشات الدخول/التحقق/الاستعادة)، `core/network` و`core/services` و`core/routing`، `Info.plist` و`AndroidManifest`، و`payment_config`. تصفح لبقية `features` والـ docs. **تجاهلت الألماني لغوياً حسب التعليمات** وفحصت EUR/الضريبة/Stripe كأرقام فقط. لا باك داخل الريبو (عميل فقط ضد Render) — بنود السيرفر في "تحتاج تأكيد".
**الثوابت:** الإجمالي = الأصناف + التوصيل − الكوبون (+ ضريبة) ويحسبه الباك؛ لا دفع مزدوج لكل intent؛ سلة مطعم واحد؛ كمية ≥1 ولا إجمالي سالب؛ انتقالات الطلب قانونية؛ العملة ثابتة داخل الطلب؛ لا إتمام بسعر قديم بعد `changedPrices`.

---

## مقارنة بين الصيادين والمُفنّد

| المحور | مالي | Bloc | شبكة/أمان | معمارية | المُفنّد | الحكم |
|---|---|---|---|---|---|---|
| دفعة Stripe يتيمة + إعادة تدفع ثانية | ✅ F1 حرجة + مصدر `stripe.dart` | — | ✅ يدعم (F3: بلا idempotency/ack) | — | **مؤكد**: لا refund/cancel/intent-key؛ تعليق `not_confirmed` ينظف الطلب لا المال | 🔴 C-1 |
| OTP في body + ملء تلقائي | — | — | ✅ F1 حرجة | — | **مؤكد** مع تضييق: بلا flag، لكن النطاق حسابات `requiresVerification` + server-side verify | 🔴 C-2 (بصياغة مضيقة) |
| `order:send` بلا ack/idempotency → طلبان | ✅ يدعم (مهلة 20s) | — | ✅ F3 عالية + مصدر سوكيت (`sendBuffer` بلا dedup) | ✅ يدعم (بلا retry/queue) | لم يُفنَّد مباشرة؛ الأدلة متطابقة من صيادين | 🔴 C-3 |
| iOS بلا مفاتيح موقع | — | — | ✅ F4 عالية | سؤال plist ضمني | لم يُعترض؛ تحققت يدوياً: `Info.plist` بلا `NSLocation*` فعلاً | 🔴 C-4 |
| رمز الاستعادة يُعرض | — | — | ✅ F2 حرجة | — | **مخفف**: التعليق يعترف "مرحلة اختبار"؛ العميل عارض سلبي بلا prefill؛ الإصلاح باك | 🟠 H-5 |
| `droppable` يسقط `FetchCart` | — | ✅ 🔴 + مصدر `droppable.dart` | — | — | **مخفف**: الإسقاط حقيقي لكن الأثر GET يشفى ذاتياً + debounced + الافتراضي concurrent لا sequential | 🟡 M-8 |
| بلا guards في `go_router` | — | ✅ 🟠 | — | ✅ يدعم (H8: تنقل مزدوج) | **مخفف**: النواة صحيحة لكن الحماية الكشفية حقيقية (`dio:115-129` → 401/403 → توجيه + تنظيف) | 🟠 H-7 بصياغة "غياب وقائي" |
| presentation يستورد Dio/http | — | — | — | ✅ 🔴 | **مخفف/جزء باطل**: `http` لمواقع Nominatim مبرر؛ الصحيح 4 شاشات auth + شيت التقييم تفكك يدوياً | 🟠 H-8 مُضيَّق |
| تنقل مزدوج `go_router` + `Navigator` | — | ✅ 🔴 (shell) | — | ✅ 🟠 H8 | لم يُعترض؛ الدليلان متطابقان | 🟠 H-6 |
| دورة `taxBreakdown` مكسورة | ✅ 🟠 | — | — | ✅ يدعم (تكرار الفوترة) | لم يُعترض | 🟠 H-1 |
| تنسيق العملة مكرر 6+ | — | — | — | ✅ 🟠 | لم يُعترض | 🟠 H-9 |
| `Map` خام بدل DTOs | ✅ يدعم (fallback) | — | — | ✅ 🟠 | لم يُعترض | 🟠 H-10 |
| درس C-3 السابق مطبق: لا ادعاء "إطار يرمي" دون مصدر مكتبة؛ لا حجة "بلاطات" لخرائط غوغل؛ فحص prefill قبل السيناريو؛ أرقام أسطر متحقق منها | — | ✅ التزم (مصدر `bloc_concurrency` + تنبيه platform view) | ✅ التزم (مصادر سوكيت/كاش) | ✅ التزم (عدّ محلي للأسطر) | ✅ وظيفته | لا تكرار لأخطاء تدقيق السائق الستة |

---

## 🔴 مشاكل حرجة

### [C-1] دفع Stripe يتم ثم يفشل إرسال الطلب بلا تعويض — وإعادة المحاولة تدفع ثانية
**الموقع:** `lib/features/cart/presentation/bloc/mail_bloc.dart:392-517` (خاصة `:402,409,411,433-439,463-471,476-477,493-517`) + `lib/features/orders/data/repositories/order_repository.dart:116-119`
**ما يحدث:** الترتيب: `createOrder` → `createPaymentIntent` → `initPaymentSheet` → `presentPaymentSheet` (نجاح الدفع هنا) → **بعده** فحوصات تكتفي بـ `emit(error)`: سوكيت غير متصل، `sendOrderToRestaurant=false`، `promotionExpired`، `cartChanged`، `serverError`، `timedOut` (مهلة 20s). لا refund/void في كامل `lib` (grep صفر) و`paymentIntentId` يُستخدم مرة واحدة فقط لتمريره للإرسال (`:463`). والحراس (`:356-358`) يمنعان التكرار أثناء `loading` فقط — بعد الخطأ الزر يعمل وينشئ طلباً + intent جديدين (الـ endpoint لا يستقبل أي `orderId`).
**السيناريو:** زبون يدفع بالبطاقة بنجاح ثم ينقطع السوكيت لحظتها → "تعذّر تأكيد الطلب" → يعيد التأكيد → خصم ثانٍ. (طلبات البطاقة فقط.)
**الأثر:** خصم مضاعف حقيقي من البطاقة مقابل طلب واحد.
**الدليل:** `await Stripe.instance.presentPaymentSheet(); // 409` ثم `if (!socket.isConnected) { emit(error); return; } // 433-439 بلا تعويض`. سلوك `presentPaymentSheet` روجع في `flutter_stripe-11.5.0/.../stripe.dart:466-471` (الوصول لـ `:411` يعني نجاح الدفع عميلاً).
**الإصلاح:** authorize أولاً ثم capture بعد `order:sent`، أو استدعاء إلغاء/استرداد الـ `paymentIntentId` عند أي فشل بعده، أو مفتاح idempotency + تعطيل الزر حتى الحسم الكامل.
**كيف تتحقق:** طلب تجريبي: أكمل الدفع ثم اقطع السوكيت قبل `order:send` → PaymentIntent مؤكد بلا طلب في Dashboard؛ أعد التأكيد → intent ثانٍ.

### [C-2] الـ OTP يُرجَع في body الدخول ويُملأ تلقائياً — SMS بلا قيمة
**الموقع:** `lib/features/auth/presentation/pages/login_phone_screen.dart:83,91` + `phone_verification_screen.dart:15,49-54` — تحققت يدوياً
**ما يحدث:** `response.data['otp'].toString()` يُمرر `receivedOtp` وتملأ الحقول الستة في `initState` بلا أي flag اختبار. من يعرف الهاتف + كلمة المرور لا يحتاج قناة SMS.
**السيناريو:** Proxy/log يكشف body → استيلاء على حسابات `requiresVerification`.
**الأثر:** تجاوز عامل التحقق الثاني. (التضييق: `verifyPhoneOtp` ما زال server-side، والنطاق حسابات غير مفعلة فقط.)
**الإصلاح:** السيرفر لا يرجع `otp` أبداً؛ احذف `receivedOtp` والملء؛ إدخال يدوي فقط.
**كيف تتحقق:** Proxy أثناء دخول يتطلب تحققاً → الرد يجب ألا يحوي `otp` و`grep receivedOtp lib` فارغ.

### [C-3] إنشاء الطلب ثم `order:send` بلا idempotency وبلا ack — طلبان/دفعتان
**الموقع:** `lib/features/orders/data/repositories/order_repository.dart:57-67` + `mail_bloc.dart:363-477` + `lib/core/services/socket_service.dart:154-167`
**ما يحدث:** `POST order` بلا مفتاح عدم تكرار، ثم `emit('order:send', {orderId, paymentIntentId})` بلا ack (fire-and-forget مؤكد من مصدر السوكيت: `!connected` يُخزَّن في `sendBuffer` ويُعاد بلا dedup، و`retries` غير مضبوط). الانتظار `timeout(20s)` وعند `timedOut` رسالة `order_status_unknown` — وإعادة المحاولة تنشئ `_id` جديداً. يشمل النقدي (طلبان مكرران) والبطاقة (دفعتان عبر C-1).
**السيناريو:** الرد (`order:sent/error`) يضيع → timeout → تأكيد ثانٍ → طلبان.
**الأثر:** طلبات/مدفوعات مكررة.
**الإصلاح:** `uuid` كـ `idempotencyKey` في REST والسوكيت (السيرفر يرفض التكرار) + `emitWithAck` بمهلة + تعطيل الزر حتى الحسم.
**كيف تتحقق:** اقطع الشبكة بعد `emit` وأعدها؛ راقب إنشاء `_id` ثانٍ.

### [C-4] iOS بلا مفاتيح موقع — GPS معطل على iPhone
**الموقع:** `ios/Runner/Info.plist:1-54` (فقط `NSPhotoLibrary:5` و`NSCamera:7` و`$(MAPS_API_KEY):53` — تحققت يدوياً، لا `NSLocation*`) مقابل 4 مواضع تطلب GPS (`user_location_service.dart:105`، `add_location_page:96`، `set_location_screen:174`، `location_picker_page:174`)
**ما يحدث:** أول طلب موقع على iOS يفشل؛ `resolve:56-60` يعود `null` ويتحول ترتيب "الأقرب" للتقييم بصمت.
**الأثر:** ميزة الموقع/الأقرب معطلة على iOS.
**الإصلاح:** أضف `NSLocationWhenInUseUsageDescription` (+ المؤقت إن لزم) واختبر على جهاز حقيقي.
**كيف تتحقق:** `grep NSLocation Info.plist` يرجع سطراً؛ طلب موقع على iPhone ينجح.

---

## 🟠 مشاكل عالية

### [H-1] دورة `taxBreakdown` مكسورة: إجمالي ناقص قبل الدفع وضريبة قديمة تلوث اللاحق
**الموقع:** `mail_bloc.dart:83-96` (FetchCart لا يقرأ ضريبة) + `:393-397` (تُضبط بعد `createOrder` فقط) + `:220-228` (ClearCart لا يصفّرها) + `cart_bill_summary.dart:40-42` (`tax = taxBreakdown?['totalTax'] ?? 0`)
**ما يحدث:** قبل التأكيد المعروض `items − كوبون + توصيل + 0` بينما الـ intent يحسبه الباك مع الضريبة؛ وبعد أي طلب تبقى الضريبة القديمة في الحالة فتُضاف لسلال لاحقة (حتى نقدية).
**السيناريو:** سلة €10 وضريبة €1.9 → معروض €10 وخصم €11.9؛ وبعد طلب DE سلة سورية جديدة تحمل ضريبة اليورو.
**الإصلاح:** اقرأ الحقول الضريبية في FetchCart أو صفّرها صراحةً + صفّرها في ClearCart + سطر "الضريبة تُحسب عند الدفع" لـ EUR ما دامت null.
**كيف تتحقق:** قارن معروض سلة DE قبل التأكيد مع `amount` الـ intent؛ وبعد Clear أضف صنفاً وراقب `state.taxBreakdown`.

### [H-2] شاشة التأكيد مطبوع عليها "نقداً" حتى للبطاقة
**الموقع:** `order_confirmed_screen.dart:70-72` (`value: 'cash'.tr()` ثابت) مقابل `mail_bloc.dart:390` (يميز `'card'`) و`cart_options_section.dart:73-76`
**ما يحدث:** إيصال يقول "نقداً" لمدفوع Stripe.
**الأثر:** نزاع "دفعتُ أم سأدفع؟" عند التوصيل.
**الإصلاح:** `_paymentLabel(lastOrder['paymentMethod'])` كشاشة التتبع (`:641-644`).
**كيف تتحقق:** أتمم طلب بطاقة → `/order-confirmed` تعرض cash.

### [H-3] كشف التتبع يسقط الكوبون ويستخدم عملة الجهاز بدل الطلب
**الموقع:** `order_tracking_screen.dart:456-517` (لا ذكر لكوبون — grep مؤكد) + `:299,447-454` (`'currency'.tr()`) مقابل `order_confirmed:25-33` و`mail_bloc:87` (`state.currency` سيرفرية)
**ما يحدث:** `subtotal + delivery + tax ≠ total` بلا سطر يفسر الفرق؛ وطلب يورو قد يُعرض برمز ل.س حسب لغة الجهاز.
**الإصلاح:** سطر كوبون من `orderData['couponDiscount']` + عملة الطلب لـ `_fmt`.
**كيف تتحقق:** تتبع طلب بكوبون → لا سطر خصم؛ غيّر لغة الجهاز → يتغير رمز العملة.

### [H-4] ورقة المراجعة تستبعد الإضافات — الموافقة على مبلغ ناقص
**الموقع:** `cart_bill_summary.dart:226-262` (يعرض `price × quantity` فقط) مقابل `cart_items_list.dart:61-62,98-110` (سعر الوحدة شامل الإضافات)
**ما يحدث:** آخر ما يراه المستخدم قبل "تأكيد" أقل من المشحون فعلياً (المشحون `itemsPrice` سيرفري شامل الإضافات). مثال: 10000 + إضافات 3000 ×2 → الورقة 20000 والخصم 26000.
**الأثر:** شكاوى "خُصم أكثر مما وافقت". (عرضي — الشحن صحيح.)
**الإصلاح:** `(price + extrasUnit) × quantity` + سطر أسماء الإضافات (كالتتبع `:399-416`)، وبطاقة السلة تعرض الإجمالي السطري.
**كيف تتحقق:** سلة بإضافات → اجمع بنود الورقة وقارن مع `total` و`itemsPrice`.

### [H-5] رمز الاستعادة يُعرض في الواجهة — مصدره الباك (مخفف من حرجة)
**الموقع:** `reset_password_screen.dart:116-119` (تعليق "مرحلة اختبار: الباك يُرجع الرمز ضمن نص الرسالة مؤقتاً") + `:355-358` (`_buildInfoBanner(_serverMessage)`) — تحققت يدوياً
**ما يحدث:** pass-through لرسالة السيرفر تُعرض حرفياً. بلا prefill والإدخال يدوي — العميل عارض سلبي والذنب باك.
**الأثر:** shoulder-surfing يكشف الرمز مع الهاتف المعروض.
**الإصلاح:** رسالة عامة "تم إرسال الرمز" ولا تعرض `message` الخام حتى ينظف الباك.
**كيف تتحقق:** اطلب رمزاً → يجب ألا يظهر في الشاشة ولا في `response.data['message']`.

### [H-6] ملاحة مختلطة تكسر الـ Shell — ستاك مزدوج
**الموقع:** `cart_options_section.dart:184,214` + `order_card_item.dart:140` + `home_page.dart:82` (`Navigator.push(MaterialPageRoute)`) رغم وجود `/account/addresses:222` و`/order-tracking:269` في `app_router`
**ما يحدث:** تعديل العنوان/التتبع خارج `goBranch` → Back يضيع التبويب والديب-لينك مكسور.
**الإصلاح:** `context.push(...)` بالمسارات + `extra`، وحصر `MaterialPageRoute` خارج الـ Shell.
**كيف تتحقق:** `grep MaterialPageRoute lib` خارج شجرة Shell فقط.

### [H-7] لا `redirect` وقائي في الراوتر — الحماية كشفية فقط (مخفف)
**الموقع:** `app_router.dart:41-44` (بلا `redirect/refreshListenable` — grep صفر) + `splash:98-112` (فحص إقلاع مرة واحدة يتجاوزه الديب-لينك)
**ما يحدث:** `/orders` بتوكن منتهٍ يبني مباشرة؛ لكن أول API مصادق يعيد التوجيه (`dio:115-129` → 401/403 → logout + تنظيف `auth_service:36-53`).
**الأثر:** شاشات محمية تُبنى لحظياً ثم تُطرد — وميض + 401.
**الإصلاح:** `redirect` مركزي يقرأ `TokenStorage`.
**كيف تتحقق:** `go('/orders')` بلا توكن ينتهي في الدخول مباشرة.

### [H-8] تفكيك `DioException` يدوياً في 4 شاشات auth + التقييم (مضيَّق)
**الموقع:** `login_phone:118-120`، `order_rating_sheet:263-271`، `location_bloc:158-164` (نص عربي مثبّت يكسر de/en)، `profile_cubit:20` (`e.toString()` خام) — مستثنى: `http` لمواقع Nominatim الثلاث (مبرر: خارجي بلا توكن)
**ما يحدث:** تجاوز `AppError.from` (`app_error:90-97` + فلترة `181-189`) → رسائل عامة/تقنية/صمت حسب الشاشة.
**الإصلاح:** منع `dio/http` من `presentation/`؛ الخدمة ترمي `ApiException(AppError.from(e))`.
**كيف تتحقق:** `grep "package:dio|package:http" .../presentation` → صفر عدا theme؛ و`e.response?.data` تختفي من الواجهات.

### [H-9] تنسيق العملة وحساب الفاتورة مكرر 6+ — divergence بصري
**الموقع:** القانوني `core/utils/money.dart:11-17`؛ المكررات `cart_bill_summary:264-269`، `cart_items_list:153-158`، `coupon_section:125-130`، `coupon.dart:103-109`، `order_confirmed:34-39`، `order_tracking:447-454`؛ حساب في build (`bill:39-42`، `mail_state:67-70` fallback يتجاهل الإضافات، `price_summary:28-30` بـ `toInt()` يتجاهل سنتات اليورو)
**ما يحدث:** نفس السلة تُعرض `10.01 €` و`10 €` و`10 ل.س` حسب الشاشة.
**الإصلاح:** احذف الخاص واستدعِ `formatMoney` فقط + getter واحد مختبر للإجمالي.
**كيف تتحقق:** grep الخاص → صفر عدا `money.dart` + test واحد `EUR/SYP/null`.

### [H-10] `Map` خام بدل DTOs — لا عقد مع الباك
**الموقع:** `meal.dart:27-31`، `cart_repository:41,51,71,116,128`، `order_repository:42-50,93-96`، `order_tracking:17,344-345,457-467`، `mail_state:24,27,40`، `meal_details:36-38`
**ما يحدث:** إعادة تسمية حقل (`totalPrice → total`) تُسقط القيم بصمت لـ `0` في N شاشات بلا فشل بناء.
**الإصلاح:** DTOs في `data/` فقط (`OrderDetails/Cart/TaxBreakdown`) والباقي أنواع قوية.
**كيف تتحقق:** كسر مفتاح في test يفشل test الـ DTO لا 5 شاشات.

---

## 🟡 متوسطة (مختصرة)
- **[M-1]** خلط أخطاء: `favorite:66-68` صمت (`debugPrint` فقط)، `mail_bloc:97-99` يستبدل رسالة الخادم بعامة، `ClearCart:214` يبتلع، `home:76-78` و`meal_details:95-97` تبتلعان "ليس حرجاً" — وحّد على `AppError` + `AppErrorView(onRetry)`.
- **[M-2]** موقع بلا سقف: `user_location_service:105` + 3 صفحات (`getCurrentPosition()` عارية) والكتالوج ينتظرها (`home_catalog:95`) → علق GPS = علق الرئيسية. أضف `timeLimit(8s)` + fallback.
- **[M-3]** `http.get` لـ Nominatim بلا timeout ويتجاهل غير-200 (3 ملفات مواقع `:113-119`/`192-198`/`190-196`) → فورم متجمد. أضف `timeout(10s)` + رسالة.
- **[M-4]** كاش يتجاهل اللغة: `dio_client:40-48` + `defaultCacheKeyBuilder = url` فقط (مصدر `http_cache_core:75-81`) → بعد `ar→en` قوائم باللغة القديمة حتى `maxStale`. أضف `keyBuilder` باللغة أو امسح عند تغييرها.
- **[M-5]** رفع بلا سقف: تسجيل `imageQuality:80` فقط (مقابل `512×512` في تعديل البروفايل) + `filename:"profile.jpg"` ثابت + بلا `sendTimeout` (`dio:76-84`) → صورة 20MB تعلق. وحّد `1024×1024/75` + فحص 2MB + `sendTimeout:60s`.
- **[M-6]** سجلات PII في debug (`dio:109-112` كامل body، `auth:84-86`، `push:75,161`، `socket:165` يحوي ids) → خفّض لـ statusCode+path خلف `kDebugMode`.
- **[M-7]** توكن FCM + سجل إشعارات plaintext في prefs (`push:35,123-130` + `order_notifications:110,265-281`) + نسخ احتياطي غير مقيد (`Manifest:8-12` بلا `allowBackup=false`) → امسح عند الخروج (موجود جزئياً) وقيد النسخ.
- **[M-8]** `droppable` على `FetchCart:101` يسقط جلباً أثناء in-flight (مصدر `droppable:5-9,35` مؤكد) لكن الأثر stale مؤقت يشفى (debounce 400ms + retry يدوي) → استبدل `sequential/restartable` (ثانوي).
- **[M-9]** لا قيد `couponDiscount ≤ الإجمالي` (`bill:41-42` بلا `max(0,…)`) → إجمالي سالب معروض (عرضي فقط — الباك يحسب ولا يُرسل مبلغ). أضف `max` وأصلح fallback `totalAmount:67-70` ليشمل الإضافات.
- **[M-10]** أداء قوائم: `DateFormat` داخل `build` لكل بطاقة (`order_card:39` + `history:32` + `profile:46`) → `static final`؛ و`Image.network` في بطاقتي عروض (`offer:56` + `offerr_meal:59`) مقابل `CachedNetworkImage` في الباقي → وحّد؛ و`BlocBuilder` بحجم الصفحة (`home:97`) → `buildWhen/select`.

## 🔵 منخفضة (قائمة مسطحة)
- **[L-1]** `baseUrl` صلبة (`dio:16`) + `pk_test` (`payment_config:10-11`) بلا env/flavors — `--dart-define` مع fallback dev (التعليق يحذر من `pk_live` قبل الإطلاق — صحيح).
- **[L-2]** `google-services.json:18,37` مرفوع (`AIza` علني بطبيعته) و`.gitignore` لا يستثنيه — قيّده بالحزمة/الشهادة؛ خرائط أندرويد عبر placeholder (`Manifest:53-55` + `gradle:42-46`) سليمة.
- **[L-3]** ملفات عملاقة (~10 فوق 400 سطر: تتبع 684، عنوان 609، سلة 546...) — استخرج `BillSummary/CheckoutOrchestrator/AddressForm` (دين صيانة لا عطل).
- **[L-4]** DI يدوي بلا حاوية + `DioClient → AppRouter.go` من الـ interceptor (`dio:6-8,121-124`) ودورة محتملة — ابث حدث `unauthorized` بدل تنقل مباشر.
- **[L-5]** تسميات: `Mail*` داخل feature اسمها `cart` + `HomBody/Resturant/Languege/textfiled/offerr` — rename ميكانيكي (سؤال: هل `Mail` دومين مقصود؟).
- **[L-6]** `lib.rar` (281KB) بجانب `lib/` مجهول المحتوى — احذف أو وثّق وأضف لـ `.gitignore`.
- **[L-7]** `changedPrices` استشارية لا تمنع الإتمام (`cart:99-101,218-246` + أزرار `104-106,180-182`) — الباك يرفض 409 مجدداً، فالأثر رحلة فاشلة إضافية فقط.
- **[L-8]** تقريبات عرضية (`toInt/toStringAsFixed(0)` في عروض/خطوات وجبة بعملة الواجهة) + تنقل "كوبوناتي" المتفائل (`my_coupons:58-69` → سلة قد تعرض شاشة خطأ) — وحّد منسقاً يحترم العملة.

---

## ملاحظات تحتاج تأكيدك (باك/منتج)
- capture الـ Stripe: فوري أم authorize-ثم-capture عند `order:send`؟ وهل `not_confirmed` يُبطل الـ intent المرتبط أم يحذف الطلب فقط؟ (يحدد: خصم مضاعف أم حجز مضاعف.)
- هل `GET cart` يرجع حقول ضريبية يتجاهلها العميل (FetchCart لا يقرأها)؟
- Idempotency سيرفرية لـ `POST order` و`order:send`؟ وغرف السوكيت (`/user` + auth) تُربط تلقائياً بعد reconnect؟
- `Rate-limit` العام (العميل يعالج 429 في الاستعادة فقط) و`Cache-Control` من الباك (التعليق يدعي غيابها) وpinning/SSL وdeep-links خارجية.
- قيود مفاتيح Firebase/Stripe في اللوحات؛ و`isUsable/remainingUses` للكوبونات وفلترة العروض تاريخ/دولة (العميل يعتمد `isActive` و409 كحارس).
- `lib.rar`؟ و`Mail` مقصود أم rename؟ وزر خروج أندرويد `exit(0)` (`home_shell:64`) مقصود؟ و`NSLocation` سقط أم في ملف آخر؟ (grep يقول سقط.)

## ما فُحص وكان سليماً
- العميل لا يرسل أي مبلغ (`createOrder:63-67` عنوان/ملاحظات/طريقة فقط)؛ سلة المطعم الواحد (فحص `meal_details:259-265` + `replaceCart:231-261` + رفض `400 differentRestaurant`)؛ حراس الكمية (واجهة + سيرفر + تراجع متفائل)؛ مسار 409 مكتمل (`changedItems → changedPrices` + لافتة + مسح)؛ إلغاء الدفع قبل النجاح آمن (`StripeException` قبل الإرسال)؛ كوبون DE مخفي عميلاً ومرفوض باكاً؛ `totalCartPrice` المزدوج مُتجنَّب (`mail_state:14-16`).
- التوكن في الآمن مع ترحيل (`token_storage:14,24-25,47,61-62`)؛ prefs للثيم فقط؛ كاش ذاكرة فقط + `noCache` افتراضي + مسح عند الخروج؛ 401 بلا حلقة (`_handlingUnauthorized`)؛ Push lifecycle (تسجيل `onBackgroundMessage` قبل `runApp` + تأجيل init بعد أول إطار)؛ dedup إشعارات (سقف 50 + `orderId::status`)؛ أحداث السوكيت متسقة لفظياً؛ reconnect مفعلة (`2s/15s`)؛ `clientSecret` لا يُسجَّل؛ خرائط عبر placeholder؛ لا `usesCleartextTraffic`؛ `AppError` يفلتر التقني.
- Bloc: إلغاء debouncers (`close:333`)؛ `LocationBloc` يستعيد الحالة بعد الفشل؛ `OrderTrackerCubit` يفحص `isClosed`؛ `mounted` محروس بعد كل `await` مفحوص؛ `orderConfirmed/Tracking` خارج الـ Shell + منع `PopScope`؛ تنظيف مستمعي checkout.

## خطة إصلاح مقترحة بالترتيب
1. **[C-2]** أوقف إرجاع `otp` واحذف الملء — سطرا باك + سطرا عميل، يغلق استيلاءً.
2. **[C-1]+[C-3]** بوابة الدفع: idempotency أولاً (يمنع التكرار)، ثم authorize/capture أو استرداد تلقائي — يوقف النزيف المالي.
3. **[C-4]** مفاتيح iOS — تعيد iPhone للخدمة.
4. **[H-5]+[H-2]+[H-3]+[H-4]+[H-1]** نظافة الفوترة (رسالة عامة + تسمية الدفع + سطر الكوبون + الإضافات + دورة الضريبة).
5. **[H-6]+[H-7]+[H-8]** الملاحة والأخطاء (`push` موحد + `redirect` + `AppError` شامل).
6. **[H-9]+[H-10]** توحيد العملة وDTOs — يمنع drift الباك القادم.
7. **[M-1→M-10]** ثم **[L-1→L-8]** تدريجياً، مع tests للحرج (`order 409`، `differentRestaurant`، `money EUR/SYP`، `router extra=null`) قبل أي تسليم.
