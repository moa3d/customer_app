import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import 'auth_service.dart';

/// إحداثيات المستخدم كما تُرسل إلى الباك أند.
class UserCoords {
  final double lat;
  final double lng;

  const UserCoords(this.lat, this.lng);
}

/// مصدر واحد لإحداثيات المستخدم في طلبات الكتالوج.
///
/// **لماذا الأولوية بهذا الشكل:** الباك أند نفسه يفضّل العنوان الافتراضي
/// المحفوظ على `lat`/`lng` المرسلَين في الـ query (انظر `getAllRestaurant`
/// و`getAllFood` في `user.controller.js`)، فالبارامترات ليست إلا خطة بديلة.
/// لذلك لا فائدة من قراءة الـ GPS إن كان للمستخدم عنوان أصلاً — سيتجاهله
/// الباك. نقرأه فقط عندما لا يجد الباك ما يستعمله، وإلا عاد
/// `locationUsed: false` وتحوّل ترتيب «الأقرب» صامتاً إلى ترتيب بالتقييم.
class UserLocationService {
  UserLocationService._internal();

  static final UserLocationService _instance = UserLocationService._internal();

  factory UserLocationService() => _instance;

  final AuthService _authService = AuthService();

  /// رفض المستخدم إذن الموقع في هذه الجلسة — لا نُلحّ عليه بنافذة الإذن
  /// عند كل إعادة جلب.
  bool _gpsDenied = false;

  /// نص العنوان الافتراضي («دمشق - المزة») لعرضه في ترويسة الرئيسية،
  /// يُملأ كأثر جانبي لآخر [resolve] ناجح قرأ العناوين.
  String? lastAddressLabel;

  /// عدد الخانات العشرية المُبقاة على الإحداثيات.
  ///
  /// ثلاث خانات ≈ 100 متر. التدوير إلزامي لا تجميلي: `DioClient.cached()`
  /// يستعمل `CachePolicy.forceCache` ومفتاح الكاش هو الـ URL كاملاً، فإحداثيات
  /// GPS خام تتغيّر مع كل قراءة وتولّد مفتاحاً جديداً في كل مرة — أي كاش معطّل
  /// عملياً على أثقل نداءين في التطبيق.
  static const int _precision = 3;

  static double _round(double value) {
    final factor = math.pow(10, _precision).toDouble();
    return (value * factor).roundToDouble() / factor;
  }

  /// يُرجع الإحداثيات المتاحة، أو `null` إن لم يتوفّر عنوان ولا GPS.
  ///
  /// الأولوية: العنوان الافتراضي ← أول عنوان محفوظ ← الـ GPS.
  Future<UserCoords?> resolve() async {
    final fromAddress = await _fromSavedAddresses();
    if (fromAddress != null) return fromAddress;
    return _fromGps();
  }

  Future<UserCoords?> _fromSavedAddresses() async {
    try {
      final response = await _authService.getUserAddresses();
      final addresses = response.data?['addresses'];
      if (addresses is! List || addresses.isEmpty) return null;

      // الباك يبحث عن isDefault حصراً؛ نتبع القاعدة نفسها ثم نتراجع لأول
      // عنوان حتى لا يفقد المستخدم المسافة لمجرد أنه لم يعيّن عنواناً افتراضياً.
      final Map? chosen = addresses.firstWhere(
        (a) => a is Map && a['isDefault'] == true,
        orElse: () => addresses.first is Map ? addresses.first : null,
      ) as Map?;
      if (chosen == null) return null;

      lastAddressLabel = "${chosen['city'] ?? ''} - ${chosen['area'] ?? ''}";

      final coordinates = chosen['location']?['coordinates'];
      if (coordinates is! List || coordinates.length < 2) return null;

      // GeoJSON: [lng, lat] — لا [lat, lng].
      final lng = (coordinates[0] as num?)?.toDouble();
      final lat = (coordinates[1] as num?)?.toDouble();
      if (lat == null || lng == null) return null;

      return UserCoords(_round(lat), _round(lng));
    } catch (_) {
      return null;
    }
  }

  Future<UserCoords?> _fromGps() async {
    if (_gpsDenied) return null;
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _gpsDenied = true;
        return null;
      }

      final position = await Geolocator.getCurrentPosition();
      return UserCoords(_round(position.latitude), _round(position.longitude));
    } catch (_) {
      // خدمة الموقع مطفأة أو انتهت المهلة — لا نُعيد المحاولة في هذه الجلسة.
      _gpsDenied = true;
      return null;
    }
  }
}
