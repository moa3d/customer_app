import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/services/app_service.dart';
import '../../../../core/utils/app_sizes.dart';


class OrderRatingSheet extends StatefulWidget {
  final Map<String, dynamic> orderData;
  final VoidCallback? onRatingFinished;

  const OrderRatingSheet({
    super.key,
    required this.orderData,
    this.onRatingFinished,
  });

  @override
  State<OrderRatingSheet> createState() => _OrderRatingSheetState();
}

class _OrderRatingSheetState extends State<OrderRatingSheet> {
  // هدول مشان نخزن التقييمات والملاحظات بكل رواق
  double _foodRating = 5;
  double _driverRating = 5;
  final _foodCommentController = TextEditingController();
  final _driverCommentController = TextEditingController();
  bool _isSubmitting = false;

  /// ما لم يصل الخادم بعد. يُبدَّل فور نجاح كل نداء على حدة، فإعادة المحاولة
  /// بعد فشل جزئي لا تُعيد إرسال ما نجح، والشيت يُعيد بناء القسم المتبقّي وحده.
  late bool _foodPending;
  late bool _driverPending;

  @override
  void initState() {
    super.initState();
    _foodPending = widget.orderData['myFoodRating'] == null;
    _driverPending = widget.orderData['driverId'] != null &&
        widget.orderData['myDriverRating'] == null;
  }

  @override
  void dispose() {
    // تنظيف الزاكرة واجب مشان ما يتقل الموبايل
    _foodCommentController.dispose();
    _driverCommentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final restaurantInfo = widget.orderData['restaurantId'] is Map ? widget
        .orderData['restaurantId'] : {};
    final bool needsFoodRating = _foodPending;
    final bool needsDriverRating = _driverPending;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      // مشان نسكر الكيبورد وقت نكبس برا
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery
              .of(context)
              .viewInsets
              .bottom, // مشان يطلع الشيت فوق الكيبورد
        ),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHandle(theme),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  children: [
                    Text('rating_question'.tr(),
                        style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold)),
                    AppSizes.h24,

                    // تقييم الأكل
                    if (needsFoodRating) _buildFoodRatingSection(
                        theme, restaurantInfo['name']),

                    // تقييم السائق
                    if (needsDriverRating) _buildDriverRatingSection(theme),

                    AppSizes.h24,
                    _buildSubmitButton(theme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      width: 40, height: 4,
      decoration: BoxDecoration(
        color: theme.dividerColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildFoodRatingSection(ThemeData theme, String? restName) {
    return Column(
      children: [
        Row(children: [
          Icon(Icons.restaurant, color: theme.primaryColor),
          const SizedBox(width: 12),
          Text(restName ?? 'Restaurant',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
        ]),
        _buildStarPicker((r) => setState(() => _foodRating = r), _foodRating),
        _buildCommentField(theme, _foodCommentController),
        AppSizes.h20,
      ],
    );
  }

  Widget _buildDriverRatingSection(ThemeData theme) {
    return Column(
      children: [
        Row(children: [
          Icon(Icons.delivery_dining, color: theme.primaryColor),
          const SizedBox(width: 12),
          Text('delivery_driver'.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
        ]),
        _buildStarPicker((r) => setState(() => _driverRating = r),
            _driverRating),
        _buildCommentField(theme, _driverCommentController),
        AppSizes.h20,
      ],
    );
  }

  Widget _buildStarPicker(Function(double) onRate, double current) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) =>
          IconButton(
            icon: Icon(i < current ? Icons.star : Icons.star_border,
                color: Colors.amber, size: 35),
            onPressed: () => onRate(i + 1.0),
          )),
    );
  }

  Widget _buildCommentField(ThemeData theme, TextEditingController controller) {
    return TextField(
      controller: controller,
      maxLines: 2,
      decoration: InputDecoration(
        hintText: 'notes_hint'.tr(),
        filled: true,
        fillColor: theme.scaffoldBackgroundColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity, height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primaryColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: _isSubmitting ? null : _submitRatings,
        child: _isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : Text('done'.tr(), style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _submitRatings() async {
    setState(() => _isSubmitting = true);
    final service = AppService();
    final orderId = widget.orderData['_id'];

    // تُلتقط قبل await تفادياً لاستعمال context بعد فجوة غير متزامنة
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // المحوران مستقلان في الباك (`rate/order` و`rate/driver`)، فلكلٍّ محاولته:
    // ربطهما في `try` واحد كان يجعل عطباً في الثاني يُسقط نجاح الأول من حساب
    // الواجهة، فتُقفل البطاقة على تقييم ناقص بلا مدخل للعودة.
    final bool hadFood = _foodPending;
    final bool hadDriver = _driverPending;
    Object? firstError;

    if (_foodPending) {
      try {
        await service.rateOrder(orderId: orderId,
            rating: _foodRating,
            comment: _foodCommentController.text);
        _foodPending = false;
      } catch (e) {
        firstError = e;
      }
    }

    if (_driverPending) {
      try {
        await service.rateDriver(orderId: orderId,
            rating: _driverRating,
            comment: _driverCommentController.text);
        _driverPending = false;
      } catch (e) {
        firstError ??= e;
      }
    }

    final bool anySaved =
        (hadFood && !_foodPending) || (hadDriver && !_driverPending);

    // يُستدعى حتى عند الفشل الجزئي: ما وصل الخادم يجب أن يظهر في السجل فوراً،
    // وإلا بدا للمستخدم أن شيئاً لم يُحفظ.
    if (anySaved) widget.onRatingFinished?.call();

    if (firstError == null) {
      navigator.pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
            content: Text("rating_success".tr()),
            backgroundColor: Colors.green));
      return;
    }

    // الشيت يبقى مفتوحاً على القسم المتبقّي وحده ليعيد المستخدم المحاولة
    if (mounted) setState(() => _isSubmitting = false);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          content: Text(anySaved
              ? "rating_partial_failed".tr()
              : _errorMessage(firstError)),
          backgroundColor: Colors.red));
  }

  /// رسالة الباك المترجمة إن توفّرت (invalidRating / orderNotFound / noDriver)،
  /// وإلا رسالة عامة.
  String _errorMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
    }
    return "rating_failed".tr();
  }
}