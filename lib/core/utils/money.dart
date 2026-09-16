/// تنسيق موحّد للمبالغ حسب **عملة المطعم** لا حسب لغة التطبيق.
///
/// الباك أند يُرجع `currency` على المطعم (`SYP` لسوريا، `EUR` لألمانيا)، ويصل
/// مع الوجبة داخل `restaurantId` المُوسَّع. قبل هذا الملف كانت بطاقات الرئيسية
/// تقرأ العملة من مفتاح الترجمة `restaurant.currency`، فيظهر مطعم ألماني
/// بـ«ل.س» لمستخدم يقرأ بالعربية.
///
/// الصياغة مطابقة عمداً لتنسيق السلة (`cart_items_list.dart`,
/// `cart_bill_summary.dart`) حتى لا يرى المستخدم شكلين مختلفين للمبلغ نفسه
/// بين الرئيسية والسلة. عند توحيد السلة على هذه الدالة لاحقاً لن يتغيّر أي نص.
String formatMoney(num value, String? currency) {
  if (currency == 'EUR' || currency == '€') {
    return '${value.toStringAsFixed(2)} €';
  }
  final String suffix =
      (currency == null || currency.isEmpty) ? 'ل.س' : currency;
  return '${value.toInt()} $suffix';
}
