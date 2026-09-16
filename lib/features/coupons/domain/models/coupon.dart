import 'package:easy_localization/easy_localization.dart';

class Coupon {
  final String code;
  final String type; // percentage | fixed | free_delivery
  final num? value;
  final num? maxDiscountAmount;
  final num? minOrderValue;
  final bool hasExpiry;
  final DateTime? endDate;
  final int usedByMe;
  final num? maxUsesPerUser;
  final bool isUsable;

  const Coupon({
    required this.code,
    required this.type,
    this.value,
    this.maxDiscountAmount,
    this.minOrderValue,
    this.hasExpiry = false,
    this.endDate,
    this.usedByMe = 0,
    this.maxUsesPerUser,
    this.isUsable = true,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      code: json['code']?.toString() ?? '',
      type: json['type']?.toString() ?? 'fixed',
      value: (json['value'] as num?),
      maxDiscountAmount: (json['maxDiscountAmount'] as num?),
      minOrderValue: (json['minOrderValue'] as num?),
      hasExpiry: json['hasExpiry'] == null ? false : json['hasExpiry'] == true,
      endDate: _parseDate(json['endDate']),
      usedByMe: (json['usedByMe'] as num?)?.toInt() ?? 0,
      maxUsesPerUser: (json['maxUsesPerUser'] as num?),
      isUsable: json['isUsable'] == null ? true : json['isUsable'] == true,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  /// نص قيمة العرض للكوبون موحّد للشاشات كلها.
  /// percentage → "خصم {value}%" (+ "بحد أقصى {max}" إن وجد)
  /// fixed     → "خصم {value}" بالعملة
  /// free_delivery → "توصيل مجاني 🎉"
  String formatValue({String currency = 'ل.س'}) {
    switch (type) {
      case 'percentage':
        final base = 'coupons.offer_percent'.tr(namedArgs: {'value': value?.toString() ?? '0'});
        final max = maxDiscountAmount;
        if (max != null && max > 0) {
          return '$base ${'coupons.offer_max'.tr(namedArgs: {'max': _fmtNum(max)})}';
        }
        return base;
      case 'free_delivery':
        return 'coupons.free_delivery_value'.tr();
      case 'fixed':
      default:
        return 'coupons.offer_fixed'.tr(
          namedArgs: {'value': _formatMoney(value?.toDouble() ?? 0, currency)},
        );
    }
  }

  /// نص الحالة (الصلاحية) — لا يعرض أبداً ISO خام.
  String expiryLabel() {
    if (!hasExpiry || endDate == null) return 'coupons.no_expiry'.tr();
    final diff = endDate!.difference(DateTime.now());
    if (diff.isNegative || diff.inSeconds == 0) {
      return 'coupons.expired'.tr();
    }
    if (diff.inDays >= 1) {
      return 'coupons.expires_in_days'.tr(namedArgs: {'days': diff.inDays.toString()});
    }
    if (diff.inHours >= 1) {
      return 'coupons.expires_in_hours'.tr(namedArgs: {'hours': diff.inHours.toString()});
    }
    if (diff.inMinutes >= 1) {
      return 'coupons.expires_in_minutes'.tr(namedArgs: {'minutes': diff.inMinutes.toString()});
    }
    return 'coupons.expires_today'.tr();
  }

  bool get isExpired {
    if (!hasExpiry || endDate == null) return false;
    return endDate!.difference(DateTime.now()).isNegative;
  }

  /// عدد مرات الاستخدام المتبقية للمستخدم (يحسبها الفرونت).
  int? get remainingUses {
    if (maxUsesPerUser == null) return null;
    return (maxUsesPerUser!.toInt()) - usedByMe;
  }

  String _formatMoney(double v, String currency) {
    if (currency == 'EUR' || currency == '€') {
      return '${v.toStringAsFixed(2)} €';
    }
    final c = currency.isEmpty ? 'ل.س' : currency;
    return '${v.toInt()} $c';
  }

  static String _fmtNum(num v) {
    if (v == v.toInt()) return v.toInt().toString();
    return v.toString();
  }
}
