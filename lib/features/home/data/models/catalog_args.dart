import 'catalog_sort.dart';

/// ما تمرّره الشاشة الرئيسية إلى شاشتَي «جميع المطاعم» و«جميع الوجبات»
/// عبر GoRouter extra.
///
/// الرئيسية تحمّل القائمتين كاملتين إلى الذاكرة أصلاً (لا ترقيم صفحات في الباك)،
/// لذلك نمرّرها كما هي ليظهر المحتوى فوراً بلا انتظار شبكة.
class CatalogArgs<T> {
  /// القائمة المعروضة حالياً في الرئيسية — بعد تطبيق الفلتر المفعّل إن وُجد
  final List<T> initialItems;

  /// القائمة الكاملة قبل الفلتر — تُستخدم عند الضغط على «إزالة الفلتر»
  final List<T> allItems;

  /// عنوان الفلتر المفعّل في الرئيسية، أو null إن لم يكن هناك فلتر
  final String? activeFilterLabel;

  /// الترتيب المختار في الرئيسية — تبدأ به الشاشة الجديدة بدل العودة
  /// إلى الافتراضي، فلا يفقد المستخدم اختياره عند «عرض المزيد»
  final CatalogSort sort;

  /// القسم العام المفعّل — يُرسل كـ `mainCategory` عند إعادة الجلب.
  /// مدعوم على `/food` فقط.
  final String? mainCategoryId;

  /// الإحداثيات المستعملة في الرئيسية — لازمة لإعادة الجلب وحساب المسافة
  final double? lat;
  final double? lng;

  /// هل استعمل الباك موقعاً؟ عند false لا تُعرض المسافة أصلاً.
  final bool locationUsed;

  const CatalogArgs({
    required this.initialItems,
    required this.allItems,
    this.activeFilterLabel,
    this.sort = CatalogSort.nearest,
    this.mainCategoryId,
    this.lat,
    this.lng,
    this.locationUsed = false,
  });
}
