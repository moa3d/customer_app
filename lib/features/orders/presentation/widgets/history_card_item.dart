import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/utils/app_sizes.dart';
import 'order_rating_sheet.dart';

class HistoryCardItem extends StatefulWidget {
  final Map<String, dynamic> orderData;
  final bool showRating;
  final VoidCallback? onRefresh;

  // حالة "مُقيَّم" تُشتق من myFoodRating و myDriverRating مباشرة — مصدر واحد
  // للحقيقة. المحوران مستقلان: قد يُقيَّم الأكل دون السائق والعكس.
  const HistoryCardItem(
      {super.key, required this.orderData, this.showRating = true, this.onRefresh});

  @override
  State<HistoryCardItem> createState() => _HistoryCardItemState();
}

class _HistoryCardItemState extends State<HistoryCardItem> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final restaurantName = widget.orderData['restaurantId']?['name'] ??
        'Restaurant';
    final totalPrice = widget.orderData['totalPrice']?.toString() ?? '0';
    final orderNumber = widget.orderData['orderNumber'] ?? 'N/A';

    final DateTime orderedAt = DateTime.parse(
        widget.orderData['createdAt'] ?? DateTime.now().toString());
    final String formattedDate = DateFormat('yyyy/MM/dd').format(orderedAt);

    final foodRating = widget.orderData['myFoodRating'];
    final driverRating = widget.orderData['myDriverRating'];
    final bool isFoodRated = foodRating != null;

    // `myDriverRating` مرتبط بالطلب لا بالسائق، فغيابه يعني أن هذه التوصيلة
    // تحديداً لم تُقيَّم — لا أن السائق لم يُقيَّم قط.
    final bool hasDriver = widget.orderData['driverId'] != null;
    final bool isDriverRated = driverRating != null;

    // البوابة تشمل المحورين. كانت على تقييم الأكل وحده، فبمجرد نجاحه تُقفل
    // البطاقة ويبقى تقييم السائق محبوساً بلا مدخل.
    final bool isFullyRated = isFoodRated && (!hasDriver || isDriverRated);

    return Container(
      padding: const EdgeInsets.all(AppSizes.p20),
      margin: const EdgeInsets.only(bottom: AppSizes.p16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radius24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(restaurantName,
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold)),
                  Text("#$orderNumber", style: TextStyle(
                      color: theme.hintColor.withValues(alpha: 0.5), fontSize: 10)),
                ],
              )),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Text('$totalPrice ${'units.currency'.tr()}',
                    style: TextStyle(color: theme.primaryColor,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          AppSizes.h8,
          Row(children: [
            Icon(Icons.event_available, size: 14, color: theme.hintColor),
            AppSizes.w4,
            Text(formattedDate,
                style: TextStyle(color: theme.hintColor, fontSize: 12)),
          ]),
          const Divider(height: 24),          ...((widget.orderData['items'] as List? ?? []).map((item) =>
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${item['quantity']}x ${item['name']}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    _buildItemSubLine(theme, item),
                  ],
                ),
              ))),
          AppSizes.h16,
          if (widget.showRating) ...[
            if (isFoodRated)
              _buildRatingResult(theme, 'your_rating'.tr(),
                  (foodRating['rating'] as num).toDouble(),
                  foodRating['comment']),
            if (isDriverRated) ...[
              if (isFoodRated) AppSizes.h8,
              _buildRatingResult(theme, 'your_driver_rating'.tr(),
                  (driverRating['rating'] as num).toDouble(),
                  driverRating['comment']),
            ],
            if (!isFullyRated) ...[
              if (isFoodRated) AppSizes.h8,
              // بعد تقييم الأكل يبقى السائق وحده، فالزر يسمّي ما تبقّى
              _buildRateAction(theme, isFoodRated),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildItemSubLine(ThemeData theme, dynamic item) {
    final data = item is Map ? item : const <String, dynamic>{};
    final dynamic sizeRaw = data['size'];
    final String? sizeName =
        sizeRaw is Map ? sizeRaw['name']?.toString() : null;
    final List extras = data['extras'] is List ? data['extras'] : [];

    final String? sizeLabel = sizeName != null && sizeName.isNotEmpty
        ? 'units.size_$sizeName'.tr()
        : null;

    final String extrasLabel = extras.isNotEmpty
        ? extras
            .map((e) => e is Map ? e['name']?.toString() : '')
            .where((s) => s != null && s.isNotEmpty)
            .join(', ')
        : '';

    final List<String> parts = [
      ?sizeLabel,
      if (extrasLabel.isNotEmpty) extrasLabel,
    ];
    if (parts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        parts.join(' • '),
        style: TextStyle(color: theme.hintColor, fontSize: 11),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildRatingResult(
      ThemeData theme, String label, double rate, String? comment) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(label, style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold)),
            const Spacer(),
            ...List.generate(5, (i) =>
                Icon(
                i < rate ? Icons.star : Icons.star_border, color: Colors.amber,
                size: 16)),
          ]),
          if (comment != null && comment.isNotEmpty) Text('"$comment"',
              style: TextStyle(fontSize: 11,
                  color: theme.hintColor,
                  fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildRateAction(ThemeData theme, bool driverOnly) {
    return InkWell(
      onTap: () => _showRatingSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3))),
        child: Row(children: [
          Expanded(child: Text(
              driverOnly ? 'rate_driver'.tr() : 'rate_order'.tr(),
              style: const TextStyle(fontSize: 13))),
          ...List.generate(5, (i) =>
          const Icon(
              Icons.star_border, color: Colors.orange, size: 18)),
        ]),
      ),
    );
  }

  void _showRatingSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: theme.cardColor,
      // الشيت يحوي حقول نص — يجب أن يرتفع فوق الكيبورد
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.0), topRight: Radius.circular(24.0)),
      ),
      builder: (_) => OrderRatingSheet(
        orderData: widget.orderData,
        // إعادة الجلب بعد التقييم — يُستدعى أيضاً عند النجاح الجزئي لتعكس
        // البطاقة ما وصل الخادم فعلاً
        onRatingFinished: widget.onRefresh,
      ),
    );
  }
}