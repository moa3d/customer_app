import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/socket_service.dart';
import '../widgets/tracking/map_view.dart';
import '../../../../core/utils/app_sizes.dart';
import '../../bloc/order_tracker_cubit.dart';
import '../../bloc/order_tracker_state.dart';


class OrderTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const OrderTrackingScreen({super.key, required this.orderData});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  late String _orderStatus;
  Map<String, dynamic>? _driverInfo;

  /// كان الاشتراك يُنشأ ولا يُخزَّن ولا يُلغى — لم يكن في الشاشة dispose
  /// أصلاً، فكل فتح للتتبّع يُراكم مستمعاً دائماً يحتفظ بمرجع لكامل الـ State.
  StreamSubscription<Map<String, dynamic>>? _orderStatusSub;

  /// طيّ/توسيع تفصيل الفاتورة — تُعرض الفاتورة مطوية افتراضياً
  bool _showBillSummary = false;


  @override
  void initState() {
    super.initState();
    _initializeData();
    _setupSocketListeners();
  }

  void _initializeData() {
    _orderStatus = (widget.orderData['orderStatus'] ?? 'pending').toString();
    final driver = widget.orderData['driverId'];
    if (driver is Map && driver['name'] != null) {
      _driverInfo = Map<String, dynamic>.from(driver);
    }
  }

  void _setupSocketListeners() {
    _orderStatusSub = SocketService().listenToOrderStatus((data) {
      if (mounted && data['orderId'] == widget.orderData['_id']) {
        setState(() {
          _orderStatus = data['status'].toString();
        });

        if (_orderStatus == 'delivered') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('order_completed_successfully'.tr()),
                behavior: SnackBarBehavior.floating),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _orderStatusSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 170,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(AppSizes.radius24)),
        ),
        flexibleSpace: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Column(
              children: [
                _buildTopBar(theme),
                AppSizes.h12,
                BlocBuilder<OrderTrackerCubit, OrderTrackerState>(
                  builder: (context, state) {
                    if (state is OrderTracking && state.driverData != null) {
                      _driverInfo = state.driverData;
                    }
                    return _buildDriverCard(theme);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
          child: Column(
            children: [
              AppSizes.h20,
              _buildMapSection(theme, isDark),
              AppSizes.h20,
              // v3.0 — الزبون يتابع الحالة فقط (لا إجراء تأكيد). بطاقة
              // الحالة تُعرض دائماً؛ حالة delivered_by_driver التي كانت
              // تُبدّل لبطاقة التأكيد لم تعد تصل من الباك.
              _buildStatusCard(theme),
              AppSizes.h20,
              _buildOrderItemsDetails(theme),
              AppSizes.h20,
              _buildBillSummary(theme),
              AppSizes.h20,
              _buildExtraOrderInfo(theme),
              AppSizes.h24,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme) {
    return Row(
      children: [
        IconButton(
          style: IconButton.styleFrom(
            backgroundColor: theme.hintColor.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        AppSizes.w12,
        Expanded(
          child: Text(
              'track_order_title'.tr(),
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _buildDriverCard(ThemeData theme) {
    final String plate =
        _driverInfo?['vehicleplate']?.toString() ?? '';
    final String phone = _driverInfo?['phone']?.toString() ?? '';
    final String rating = _driverInfo?['rating']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(AppSizes.p12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppSizes.radius16),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12)),
            child: const Center(
                child: Icon(Icons.delivery_dining,
                    size: 28, color: Colors.orange)),
          ),
          AppSizes.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    _driverInfo?['name'] ?? 'searching_driver'.tr(),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis),
                Text(
                    _driverInfo?['vehicletype'] ?? 'delivery_driver'.tr(),
                    style:
                        TextStyle(color: theme.hintColor, fontSize: 12)),
                if (plate.isNotEmpty || rating.isNotEmpty ||
                    phone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (phone.isNotEmpty)
                        '${'driver_phone'.tr()}: $phone',
                      if (plate.isNotEmpty)
                        '${'vehicle_plate'.tr()}: $plate',
                      if (rating.isNotEmpty)
                        '${'driver_rating'.tr()}: $rating',
                    ].join('  •  '),
                    style: TextStyle(
                        color: theme.hintColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
          ),
          _buildActionButton(Icons.chat_bubble_outline, Colors.blue),
          AppSizes.w12,
          _buildActionButton(Icons.phone_in_talk_outlined, Colors.green),
        ],
      ),
    );
  }

  Widget _buildMapSection(ThemeData theme, bool isDark) {
    // كانت هنا صورة ثابتة map_placeholder.png فوقها مسافة ووقت مثبتان
    // في الكود (1.4 كم / 10 دقائق) يراهما كل زبون في كل طلب.
    return TrackingMapView(
      isDark: isDark,
      orderData: widget.orderData,
      driverInfo: _driverInfo,
    );
  }

  String get _restaurantName {
    final r = widget.orderData['restaurantId'];
    if (r is Map) return r['name'] ?? 'Restaurant';
    return 'Restaurant';
  }

  Widget _buildStatusCard(ThemeData theme) {
    final restaurantName = _restaurantName;
    final totalPrice = widget.orderData['totalPrice'] ?? '0';

    return Container(
      padding: const EdgeInsets.all(AppSizes.p20),
      decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(AppSizes.radius24)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(restaurantName,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                AppSizes.h8,
                Row(
                  children: [
                    CircleAvatar(
                        radius: 20,
                        backgroundColor: theme.primaryColor,
                        child: const Icon(Icons.delivery_dining,
                            color: Colors.white)),
                    AppSizes.w8,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_orderStatus.tr(),
                              style: const TextStyle(fontSize: 13)),
                          Text(
                              _restaurantName,
                              style: TextStyle(
                                  color: theme.hintColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text('$totalPrice ${'currency'.tr()}',
              style: TextStyle(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ],
      ),
    );
  }

  // v3.0 — حُذفت _buildDeliveryConfirmationCard و_confirmDelivery:
  // كانتا تعرضان زر "تأكيد الاستلام" وتُصدران order:confirmDelivery المحذوف.
  // بما أن حالة delivered_by_driver لم تعد تصل من الباك، لم يكن للزبون أي
  // إجراء تأكيد؛ الطلب ينتقل من on_the_way إلى delivered مباشرة بيد السائق.

  Widget _buildOrderItemsDetails(ThemeData theme) {
    final List items = widget.orderData['items'] ?? [];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.p20),
      decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(AppSizes.radius24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('order_details_label'.tr(),
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          AppSizes.h12,
          if (items.isEmpty)
            Text('order_details_empty'.tr(),
                style: TextStyle(color: theme.hintColor))
          else
            ...items.asMap().entries.map((entry) => Padding(
                  padding: EdgeInsets.only(
                      bottom: entry.key == items.length - 1 ? 0 : 12),
                  child: _buildItemRow(theme, entry.value),
                )),
        ],
      ),
    );
  }

  Widget _buildItemRow(ThemeData theme, dynamic item) {
    final Map<String, dynamic> data =
        item is Map ? Map<String, dynamic>.from(item) : {};
    final String name = data['name']?.toString() ?? '';
    final int quantity = (data['quantity'] as num?)?.toInt() ?? 1;
    final String image = data['image']?.toString() ?? '';
    final dynamic sizeRaw = data['size'];
    final String? sizeName =
        sizeRaw is Map ? sizeRaw['name']?.toString() : null;
    final num? sizePrice = sizeRaw is Map
        ? (sizeRaw['price'] as num?)
        : null;
    final List extras = data['extras'] is List ? data['extras'] : [];
    final num? lineTotal = data['totalPrice'] as num?;

    final sizeLabel = sizeName != null && sizeName.isNotEmpty
        ? 'units.size_$sizeName'.tr()
        : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radius12),
          child: SizedBox(
            width: 60,
            height: 60,
            child: image.startsWith('http')
                ? CachedNetworkImage(
                    imageUrl: image,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) =>
                        _placeholderImage(theme),
                    placeholder: (_, _) => _placeholderImage(theme),
                  )
                : _placeholderImage(theme),
          ),
        ),
        AppSizes.w12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              if (sizeLabel != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '$sizeLabel'
                    '${sizePrice != null ? ' (+${_fmt(sizePrice)})' : ''}',
                    style: TextStyle(
                        color: theme.hintColor, fontSize: 12),
                  ),
                ),
              if (extras.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    extras.map((e) {
                      final en = e is Map ? e : const <String, dynamic>{};
                      final price = en['price'];
                      final extraName = en['name']?.toString() ?? '';
                      return price != null
                          ? '$extraName (+${_fmt(price)})'
                          : extraName;
                    }).join('، '),
                    style: TextStyle(
                        color: theme.hintColor, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
        AppSizes.w8,
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('×$quantity',
                style: TextStyle(
                    color: theme.hintColor, fontSize: 12)),
            if (lineTotal != null)
              Text(_fmt(lineTotal),
                  style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor)),
          ],
        ),
      ],
    );
  }

  Widget _placeholderImage(ThemeData theme) {
    return Container(
      color: theme.hintColor.withValues(alpha: 0.1),
      child: const Center(
        child: Icon(Icons.restaurant, color: Colors.grey),
      ),
    );
  }

  String _fmt(num? value) {
    if (value == null) return '';
    final String symbol = 'currency'.tr();
    if (symbol == 'EUR' || symbol == '€') {
      return '${value.toStringAsFixed(2)} €';
    }
    return '${value.toInt()} $symbol';
  }

  Widget _buildBillSummary(ThemeData theme) {
    final num itemsPrice = (widget.orderData['itemsPrice'] as num?) ?? 0;
    final num deliveryFee = (widget.orderData['deliveryFee'] as num?) ?? 0;
    final num originalDeliveryFee =
        (widget.orderData['originalDeliveryFee'] as num?) ?? 0;
    final bool hasFreeDelivery = originalDeliveryFee > 0 && deliveryFee == 0;
    final num taxPrice = (widget.orderData['taxPrice'] as num?) ?? 0;
    final num totalPrice = (widget.orderData['totalPrice'] as num?) ?? 0;
    final Map<String, dynamic>? taxBreakdown =
        widget.orderData['taxBreakdown'] is Map
            ? Map<String, dynamic>.from(widget.orderData['taxBreakdown'])
            : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.p20),
      decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(AppSizes.radius24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _showBillSummary = !_showBillSummary),
            child: Row(
              children: [
                Expanded(
                  child: Text('order_summary'.tr(),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                Icon(
                  _showBillSummary
                      ? Icons.expand_less
                      : Icons.expand_more,
                  color: theme.hintColor,
                ),
              ],
            ),
          ),
          if (_showBillSummary) ...[
            AppSizes.h12,
            const Divider(height: 1),
            AppSizes.h12,
            _buildBillRow(theme, 'subtotal'.tr(), itemsPrice),
            if (hasFreeDelivery)
              _buildFreeDeliveryRow(theme, originalDeliveryFee)
            else
              _buildBillRow(theme, 'delivery_fee'.tr(), deliveryFee),
            if (taxBreakdown != null && taxBreakdown.isNotEmpty)
              _buildTaxRows(theme, taxBreakdown, taxPrice)
            else if (taxPrice > 0)
              _buildBillRow(theme, 'tax'.tr(), taxPrice),
            AppSizes.h8,
            const Divider(height: 1),
            AppSizes.h8,
            _buildBillRow(theme, 'total'.tr(), totalPrice, isTotal: true),
          ],
        ],
      ),
    );
  }

  Widget _buildTaxRows(
      ThemeData theme, Map<String, dynamic> breakdown, num totalTax) {
    final num? foodTax = breakdown['foodTax'] as num?;
    final num? deliveryTax = breakdown['deliveryTax'] as num?;
    final num? foodRate = breakdown['foodTaxRate'] as num?;
    final num? deliveryRate = breakdown['deliveryTaxRate'] as num?;

    return Column(
      children: [
        if (foodTax != null && foodTax > 0)
          _buildBillRow(
              theme, 'food_tax'.tr().replaceFirst('{}', '${foodRate ?? ''}'),
              foodTax),
        if (deliveryTax != null && deliveryTax > 0)
          _buildBillRow(
              theme,
              'delivery_tax'.tr().replaceFirst('{}', '${deliveryRate ?? ''}'),
              deliveryTax),
      ],
    );
  }

  Widget _buildBillRow(ThemeData theme, String label, num value,
      {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: isTotal ? theme.primaryColor : theme.hintColor,
                  fontSize: isTotal ? 16 : 13,
                  fontWeight:
                      isTotal ? FontWeight.bold : FontWeight.w500)),
          Text(_fmt(value),
              style: TextStyle(
                  color: isTotal ? theme.primaryColor : null,
                  fontSize: isTotal ? 16 : 13,
                  fontWeight:
                      isTotal ? FontWeight.bold : FontWeight.w500)),
        ],
      ),
    );
  }

  /// سطر رسوم التوصيل عند تفعيل عرض التوصيل المجاني —
  /// السعر الأصلي مشطوباً وبجانبه شارة "توصيل مجاني".
  Widget _buildFreeDeliveryRow(ThemeData theme, num originalDeliveryFee) {
    const Color freeGreen = Color(0xFF2E7D32);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('delivery_fee'.tr(),
              style: TextStyle(
                  color: theme.hintColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_fmt(originalDeliveryFee),
                  style: TextStyle(
                      color: theme.hintColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: theme.hintColor)),
              const SizedBox(width: 8),
              Text('free_delivery'.tr(),
                  style: const TextStyle(
                      color: freeGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExtraOrderInfo(ThemeData theme) {
    final String notes = widget.orderData['notes']?.toString() ?? '';
    final String payment =
        widget.orderData['paymentMethod']?.toString() ?? '';
    final dynamic address = widget.orderData['deliveryAddress'];
    final String fullAddress = address is Map
        ? address['fullAddress']?.toString() ?? ''
        : '';

    final rows = <Widget>[];
    if (notes.isNotEmpty) {
      rows.add(_buildInfoRow(theme, Icons.notes, 'order_notes'.tr(), notes));
    }
    if (payment.isNotEmpty) {
      rows.add(_buildInfoRow(
          theme, Icons.payment, 'payment_method'.tr(), _paymentLabel(payment)));
    }
    if (fullAddress.isNotEmpty) {
      rows.add(_buildInfoRow(
          theme, Icons.location_on_outlined, 'delivery_address'.tr(),
          fullAddress));
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.p20),
      decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(AppSizes.radius24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows,
      ),
    );
  }

  String _paymentLabel(String method) {
    if (method == 'cash') return 'cash'.tr();
    return method.replaceAll('_', ' ').toUpperCase();
  }

  Widget _buildInfoRow(
      ThemeData theme, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.hintColor),
          AppSizes.w8,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: theme.hintColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radius14),
          color: color.withValues(alpha: 0.15)),
      child: Icon(icon, color: color, size: 20),
    );
  }

}
