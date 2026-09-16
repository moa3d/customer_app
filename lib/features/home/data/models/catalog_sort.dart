import 'package:flutter/material.dart';

/// خيارات الترتيب المدعومة فعلياً في الباك على `/api/user/restaurant`
/// و`/api/user/food`.
///
/// **الأقرب ليس قيمة `sort`** — هو ما يفعله الباك عند غياب البارامتر تماماً.
/// إرسال `sort=nearest` لا يُعرَّف عليه الباك فيعامله كالافتراضي؛ يعمل بالصدفة
/// لكنه يكسر الكاش بمفتاح إضافي ويوهم القارئ بوجود قيمة غير موجودة. لذلك
/// `queryValue` هنا `null` لا سلسلة نصية، وطبقة الخدمة تحذف المفتاح كلياً.
///
/// الباك لا يرتّب على محور واحد أبداً بل يمزج القرب مع الإشارة الثانية:
/// الافتراضي `0.7 قرب + 0.3 تقييم`، و`rating`/`popular` بـ `0.3 قرب + 0.7`.
/// وعند غياب الموقع يسقط القرب فيتطابق «الأقرب» مع «الأعلى تقييماً».
enum CatalogSort {
  nearest(null, 'filter_nearest', Icons.location_on_outlined),
  popular('popular', 'filter_popular', Icons.local_fire_department_outlined),
  topRated('rating', 'filter_top_rated', Icons.star_outline);

  const CatalogSort(this.queryValue, this.labelKey, this.icon);

  /// قيمة معامل sort المرسلة للباك — null تعني حذف البارامتر (الأقرب)
  final String? queryValue;
  final String labelKey;
  final IconData icon;
}
