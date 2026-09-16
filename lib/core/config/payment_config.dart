// إعدادات Stripe — تُستخدم فقط لطلبات مطاعم ألمانيا (DE)
//
// ⚠️ هذا مفتاح TEST (وضع تجريبي) منسوخ من backend/.env و backend/src/test.html
// الموجودين في نفس المشروع — وهو آمن للاستخدام في كود العميل (Publishable Key
// مصمَّم أصلاً ليكون عاماً/مكشوفاً، بعكس Secret Key الذي يبقى على السيرفر فقط).
//
// قبل الإطلاق الفعلي لألمانيا: استبدل هذا القيمة بمفتاح pk_live_ الحقيقي
// من لوحة تحكم Stripe الخاصة بحساب الإنتاج.
class PaymentConfig {
  static const String stripePublishableKey =
      "pk_test_51TLs8ULziGG7MRaTYJoVvxKyhZ7CaTdrdWdFIeC2RQJjtnTp7fKjOvnGpfVNHjRJ0lYfGvuqWYdyDCMrknER6yDD00kGBkjONe";
}
