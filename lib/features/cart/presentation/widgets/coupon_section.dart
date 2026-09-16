import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_sizes.dart';
import '../bloc/mail_bloc.dart';
import '../bloc/mail_event.dart';
import '../bloc/mail_state.dart';

/// قسم الكوبون في شاشة السلة:
/// - بلا كوبون: حقل إدخال + زر "تطبيق".
/// - بكوبون مطبّق: شريط يعرض الكود + قيمة الخصم + زر إزالة.
/// مخفي تماماً لمستخدمي ألمانيا (showCouponUI=false) — الباك يرفض الكوبون هناك أيضاً.
class CouponSection extends StatelessWidget {
  final MailState state;
  final TextEditingController controller;
  final bool showCouponUI;

  const CouponSection({
    super.key,
    required this.state,
    required this.controller,
    required this.showCouponUI,
  });

  @override
  Widget build(BuildContext context) {
    if (!showCouponUI) return const SizedBox.shrink();

    final theme = Theme.of(context);

    if (state.hasCoupon) {
      return _buildAppliedBar(context, theme);
    }
    return _buildInput(context, theme);
  }

  Widget _buildInput(BuildContext context, ThemeData theme) {
    final bool isBusy = state.status == CartStatus.loading;
    return Container(
      padding: const EdgeInsets.all(AppSizes.p12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radius12),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              enabled: !isBusy,
              decoration: InputDecoration(
                hintText: 'coupons.apply_hint'.tr(),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: isBusy
                ? null
                : () {
                    final code = controller.text.trim();
                    if (code.isEmpty) return;
                    controller.clear();
                    context
                        .read<MailBloc>()
                        .add(ApplyCouponEvent(code: code));
                  },
            child: Text('coupons.apply_button'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildAppliedBar(BuildContext context, ThemeData theme) {
    final bool isBusy = state.status == CartStatus.loading;
    return Container(
      padding: const EdgeInsets.all(AppSizes.p12),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.local_offer_outlined,
              color: theme.primaryColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.couponCode ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor),
                ),
                if (state.couponDiscount > 0)
                  Text(
                    '-${_fmt(state.couponDiscount, state.currency)} '
                    '${'coupons.coupon_discount'.tr()}',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: isBusy
                ? null
                : () => context.read<MailBloc>().add(RemoveCouponEvent()),
            tooltip: 'coupons.remove_coupon'.tr(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  String _fmt(double v, String currency) {
    if (currency == 'EUR' || currency == '€') {
      return '${v.toStringAsFixed(2)} €';
    }
    return '${v.toInt()} ${currency.isEmpty ? 'ل.س' : currency}';
  }
}
