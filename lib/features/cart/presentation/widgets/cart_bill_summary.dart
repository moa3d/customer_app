import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/utils/app_sizes.dart';
import '../../../location/presentation/bloc/location_bloc.dart';
import '../../../location/presentation/bloc/location_state.dart';
import '../../../location/presentation/pages/add_location_page.dart';
import '../bloc/mail_bloc.dart';
import '../bloc/mail_event.dart';
import '../bloc/mail_state.dart';
import '../../domain/models/mail_item.dart';

import 'cart_summary_row.dart';
import 'coupon_section.dart';

class CartBillSummary extends StatelessWidget {
  final MailState state;
  final bool isDelivery;
  final TextEditingController notesController;
  final TextEditingController? couponController;
  final bool showCouponUI;

  const CartBillSummary({
    super.key,
    required this.state,
    required this.isDelivery,
    required this.notesController,
    this.couponController,
    this.showCouponUI = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // state.totalAmount = سعر الأصناف فقط، فالمعادلة هون مطابقة لحساب الباك:
    // totalPrice = itemsPrice - couponDiscount + deliveryFee + taxPrice
    final double fee = isDelivery ? state.deliveryFee : 0;
    final double tax = state.taxBreakdown?['totalTax']?.toDouble() ?? 0.0;
    final double total =
        state.totalAmount - state.couponDiscount + fee + tax;

    return Container(
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(color: theme.cardColor),
      child: Column(
        children: [
          if (couponController != null)
            CouponSection(
              state: state,
              controller: couponController!,
              showCouponUI: showCouponUI,
            ),
          if (couponController != null) const SizedBox(height: 12),
          CartSummaryRow(
              label: 'subtotal'.tr(), value: _formatPrice(state.totalAmount)),
          if (isDelivery)
            state.hasFreeDelivery
                ? CartSummaryRow(
                    label: 'delivery_fee'.tr(),
                    value: '',
                    strikethroughValue:
                        _formatPrice(state.originalDeliveryFee),
                    badge: 'free_delivery'.tr(),
                  )
                : CartSummaryRow(
                    label: 'delivery_fee'.tr(), value: _formatPrice(fee)),
          if (state.hasCoupon && state.couponDiscount > 0)
            CartSummaryRow(
                label: 'coupons.coupon_discount'.tr(),
                value: '-${_formatPrice(state.couponDiscount)}'),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('total'.tr(), style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold)),
              Text(
                _formatPrice(total),
                style: TextStyle(color: theme.primaryColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          AppSizes.h20,
          _buildCompleteOrderBtn(context, theme),
        ],
      ),
    );
  }

  Widget _buildCompleteOrderBtn(BuildContext context, ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primaryColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: (state.status == CartStatus.loading ||
                state.status == CartStatus.orderConfirmed)
            ? null
            : () => _showOrderDetailsSheet(context),
        child: state.status == CartStatus.loading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text('complete_order'.tr(), style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showOrderDetailsSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: theme.cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.0), topRight: Radius.circular(24.0)),
      ),
      builder: (modalCtx) =>
          BlocListener<MailBloc, MailState>(
            listenWhen: (prev, curr) =>
                prev.status != CartStatus.orderConfirmed &&
                curr.status == CartStatus.orderConfirmed,
            listener: (_, _) {
              if (Navigator.of(modalCtx).canPop()) {
                Navigator.of(modalCtx).pop();
              }
            },
            child: BlocBuilder<MailBloc, MailState>(
              builder: (context, mailState) {
                return Padding(
                  padding: EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 24,
                      bottom: MediaQuery
                          .of(context)
                          .viewInsets
                          .bottom + 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('order_summary'.tr(),
                          style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold)),
                      AppSizes.h24,
                      ...mailState.items.map((item) =>
                          _buildSheetItemRow(theme, item)),
                      const Divider(height: 32),
                      _buildFinalConfirmBtn(modalCtx, mailState),
                    ],
                  ),
                );
              },
            ),
          ),
    );
  }

  Widget _buildFinalConfirmBtn(BuildContext modalCtx, MailState mailState) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme
              .of(modalCtx)
              .primaryColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: (mailState.status == CartStatus.loading ||
                mailState.status == CartStatus.orderConfirmed)
            ? null
            : () => _onConfirmPressed(modalCtx),
        child: Text('confirm_order'.tr(),
            style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
      ),
    );
  }

  /// تأكيد الطلب بعد التيقّن من صلاحية عنوان التوصيل.
  ///
  /// العنوان بلا إحداثيات يرفضه الباك بـ400 `invalidDeliveryAddress`. كنا
  /// نداري ذلك بإرسال إحداثيات دمشق بديلاً، فيمرّ الطلب بوجهة خاطئة. الآن
  /// نوقفه هنا ونأخذ المستخدم إلى شاشة الموقع بدل أن نتركه أمام رسالة رفض
  /// لا يعرف ما يفعل بها.
  void _onConfirmPressed(BuildContext modalCtx) {
    final loc = modalCtx.read<LocationBloc>().state;
    final address = loc is LocationSuccess ? loc.selectedAddress : null;

    if (address == null) {
      ScaffoldMessenger.of(modalCtx).showSnackBar(
          SnackBar(content: Text('please_select_address'.tr())));
      return;
    }

    if (!address.hasCoordinates) {
      // يُلتقطان قبل إغلاق الورقة: `modalCtx` يفقد صلاحيته بعد الإغلاق.
      final navigator = Navigator.of(modalCtx);
      final messenger = ScaffoldMessenger.of(modalCtx);

      navigator.pop();
      messenger.showSnackBar(
          SnackBar(content: Text('address_missing_location'.tr())));
      navigator.push(
        MaterialPageRoute(builder: (_) => const AddLocationPage()),
      );
      return;
    }

    modalCtx.read<MailBloc>().add(ConfirmOrderEvent(
        deliveryAddress: address, notes: notesController.text));
  }

  Widget _buildSheetItemRow(ThemeData theme, MailItem item) {
    final bool hasDiscount =
        item.originalPrice != null && item.originalPrice! > item.price;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('${item.title} x ${item.quantity}',
              style: TextStyle(color: theme.hintColor, fontSize: 16)),
          if (hasDiscount)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatPrice(item.originalPrice! * item.quantity),
                  style: TextStyle(
                    color: theme.hintColor,
                    fontSize: 14,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: theme.hintColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(_formatPrice(item.price * item.quantity),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            )
          else
            Text(_formatPrice(item.price * item.quantity),
                style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    if (state.currency == "EUR" || state.currency == "€") {
      return "${price.toStringAsFixed(2)} €";
    }
    return "${price.toInt()} ${state.currency.isEmpty ? "ل.س" : state.currency}";
  }
}