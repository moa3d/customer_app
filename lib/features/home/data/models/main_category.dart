/// قسم عام يديره الأدمن — شريط الأقسام أعلى الشاشة الرئيسية.
/// المصدر: `GET /api/user/main-categories`، ويُمرَّر `_id` كـ `mainCategory`
/// إلى `GET /api/user/food`.
///
/// ملاحظة: موديل `MainCategory` في الباك **لا يحمل حقل country** بينما الأكل
/// مفلتر ببلد المستخدم، فقد يعطي قسمٌ قائمةً فارغة تماماً في بلد معيّن.
/// الواجهة تحتاج حالة فارغة صريحة لا شاشة بيضاء.
class MainCategory {
  final String id;
  final String name;

  /// قد يكون null — الحقل `image.url` افتراضيه null في الباك.
  final String? imageUrl;

  const MainCategory({
    required this.id,
    required this.name,
    this.imageUrl,
  });

  factory MainCategory.fromJson(Map<String, dynamic> json) {
    final image = json['image'];
    final url = (image is Map) ? image['url']?.toString() : null;

    return MainCategory(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      imageUrl: (url != null && url.isNotEmpty) ? url : null,
    );
  }
}
