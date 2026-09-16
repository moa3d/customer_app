import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../core/map/map_styles.dart';
import '../../../../../core/map/marker_bitmap.dart';
import '../../../../../core/utils/app_sizes.dart';
import 'driver_info_card.dart';

/// خريطة تتبّع حقيقية بدل صورة `map_placeholder.png` الثابتة.
///
/// كانت هذه الودجة **معرّفة وغير مستخدمة إطلاقاً**، وكانت شاشة التتبّع تعرض
/// بدلاً منها مسافة ووقتاً مثبتين في الكود (`1.4 كم` و`10 دقائق`) لكل زبون
/// ولكل طلب — أرقام مُختلَقة تُعرض كأنها حقيقة.
///
/// الآن: عنوان التسليم يُرسم من إحداثيات الطلب الفعلية. أمّا موقع المطعم
/// فالباك أند لا يُرسله حالياً — `getUserOrders` يملأ `restaurantId` بـ
/// `"name image address"` فقط بلا `location`. الودجة **جاهزة** له: أضف
/// `location` إلى سلسلة الـ populate وسيظهر مؤشّر المطعم والخط والمسافة
/// الحقيقية تلقائياً بلا أي تعديل هنا.
class TrackingMapView extends StatelessWidget {
  final bool isDark;
  final Map<String, dynamic> orderData;
  final Map<String, dynamic>? driverInfo;

  const TrackingMapView({
    super.key,
    required this.isDark,
    required this.orderData,
    this.driverInfo,
  });

  /// إحداثيات MongoDB تأتي بترتيب [lng, lat] لا [lat, lng]
  static LatLng? _extractPoint(dynamic node) {
    if (node is! Map) return null;
    final loc = node['location'];
    if (loc is! Map) return null;
    final coords = loc['coordinates'];
    if (coords is! List || coords.length < 2) return null;

    final lng = (coords[0] as num?)?.toDouble();
    final lat = (coords[1] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    if (lat.abs() < 0.0001 && lng.abs() < 0.0001) return null;
    if (lat.abs() > 90 || lng.abs() > 180) return null;

    return LatLng(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final destination = _extractPoint(orderData['deliveryAddress']);
    final restaurant = _extractPoint(orderData['restaurantId']);

    return Container(
      height: 380,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[200],
        borderRadius: BorderRadius.circular(AppSizes.radius24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (destination != null)
            _buildMap(destination, restaurant, isDark)
          else
            _buildNoLocation(theme),

          Positioned(
            top: 15,
            left: 15,
            right: 15,
            child: DriverInfoCard(driverInfo: driverInfo),
          ),

          Positioned(
            bottom: 20,
            left: 15,
            right: 15,
            child: _buildStatsCard(theme, destination, restaurant),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(LatLng destination, LatLng? restaurant, bool isDark) {
    // العلامات تُبنى صوراً نقطية بشكل غير متزامن، لذا FutureBuilder.
    // الخريطة تُعرض فوراً بلا علامات ثم تظهر عليها فور جهوزها — أفضل من
    // حجب الخريطة كلها بانتظار رسم أيقونتين.
    return FutureBuilder<Set<Marker>>(
      future: _buildMarkers(destination, restaurant),
      builder: (context, snapshot) {
        return GoogleMap(
          initialCameraPosition: CameraPosition(
            target: restaurant == null
                ? destination
                : LatLng(
                    (destination.latitude + restaurant.latitude) / 2,
                    (destination.longitude + restaurant.longitude) / 2,
                  ),
            zoom: restaurant == null ? 15.0 : 13.0,
          ),
          style: isDark ? MapStyles.dark : null,
          markers: snapshot.data ?? const <Marker>{},
          polylines: {
            if (restaurant != null)
              Polyline(
                polylineId: const PolylineId('route'),
                points: [destination, restaurant],
                width: 3,
                color: const Color(0xFFFF6B44),
              ),
          },
          // نُبقي التفاعل مطابقاً لما كان: سحب وتكبير فقط، بلا دوران أو ميلان
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          mapToolbarEnabled: false,
        );
      },
    );
  }

  Future<Set<Marker>> _buildMarkers(
      LatLng destination, LatLng? restaurant) async {
    return {
      if (restaurant != null)
        Marker(
          markerId: const MarkerId('restaurant'),
          position: restaurant,
          anchor: const Offset(0.5, 0.5),
          icon: await MarkerBitmap.circleIcon(
            icon: Icons.storefront,
            color: const Color(0xFFFF6B44),
          ),
        ),
      Marker(
        markerId: const MarkerId('destination'),
        position: destination,
        anchor: const Offset(0.5, 0.5),
        icon: await MarkerBitmap.circleIcon(
          icon: Icons.location_on,
          color: const Color(0xFF00D254),
        ),
      ),
    };
  }

  Widget _buildNoLocation(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.map_outlined, size: 48, color: theme.hintColor),
          const SizedBox(height: 8),
          Text('map_unavailable'.tr(),
              style: TextStyle(color: theme.hintColor, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStatsCard(
      ThemeData theme, LatLng? destination, LatLng? restaurant) {
    // المسافة تُحسب فقط عندما تتوفّر النقطتان فعلاً.
    // لا نعرض رقماً مُختلَقاً عندما لا نعرف.
    // المسافة عبر geolocator بدل Distance من latlong2 — يعمل على أرقام
    // مجرّدة فلا يربط الملف بنوع إحداثيات ثانٍ بجانب نوع خرائط غوغل.
    double? km;
    if (destination != null && restaurant != null) {
      km = Geolocator.distanceBetween(
            restaurant.latitude,
            restaurant.longitude,
            destination.latitude,
            destination.longitude,
          ) /
          1000;
    }

    final address =
        orderData['deliveryAddress'] is Map
            ? orderData['deliveryAddress']['fullAddress']?.toString()
            : null;

    return Container(
      padding: const EdgeInsets.all(AppSizes.p12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radius16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: km != null
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat(theme, Icons.near_me_rounded,
                    '${km.toStringAsFixed(1)} ${'km'.tr()}',
                    'remaining_distance'.tr(), Colors.orange),
                Container(
                    width: 1,
                    height: 30,
                    color: theme.dividerColor.withValues(alpha: 0.2)),
                _stat(theme, Icons.access_time_filled, _eta(km),
                    'estimated_time'.tr(), Colors.green),
              ],
            )
          : Row(
              children: [
                const Icon(Icons.location_on,
                    color: Color(0xFF00D254), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    address ?? 'delivery_address'.tr(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ));
  }

  /// تقدير تقريبي مبني على مسافة حقيقية — بمتوسط 25 كم/سا زائد هامش تحضير.
  /// ليس وعداً: الباك أند لا يوفّر ETA.
  String _eta(double km) {
    final minutes = ((km / 25.0) * 60).round() + 5;
    return '~$minutes ${'minutes'.tr()}';
  }

  Widget _stat(ThemeData theme, IconData icon, String value, String label,
      Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            Icon(icon, color: color, size: 16),
          ],
        ),
        Text(label, style: TextStyle(color: theme.hintColor, fontSize: 10)),
      ],
    );
  }
}
