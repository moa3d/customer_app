import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/app_sizes.dart';

class OrderConfirmedScreen extends StatelessWidget {
  final Map<String, dynamic> lastOrder;

  const OrderConfirmedScreen({super.key, required this.lastOrder});

  String get _orderNumber {
    final raw = lastOrder['orderNumber'];
    if (raw != null && raw.toString().isNotEmpty) return raw.toString();
    final id = lastOrder['_id']?.toString() ?? '';
    return id.length > 6 ? id.substring(id.length - 6) : id;
  }

  double get _totalAmount =>
      (lastOrder['totalPrice'] as num?)?.toDouble() ?? 0.0;
  String get _currency => lastOrder['currency']?.toString() ?? '';
  String? get _estimatedTime => lastOrder['estimatedTime']?.toString();

  /// كوبون الكوبون عند وجوده — يعرضه كما عاد من الباك (قد يكون null بصمت).
  String? get _couponCode {
    final raw = lastOrder['couponCode'];
    final s = raw?.toString();
    return (s == null || s.isEmpty) ? null : s;
  }

  double get _couponDiscount =>
      (lastOrder['couponDiscount'] as num?)?.toDouble() ?? 0.0;

  String _formatPrice(double price) {
    if (_currency == "EUR" || _currency == "€") {
      return "${price.toStringAsFixed(2)} €";
    }
    return "${price.toInt()} ${_currency.isEmpty ? "ل.س" : _currency}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Icon(Icons.check_circle,
                    size: 96, color: theme.colorScheme.primary),
                const SizedBox(height: AppSizes.space24),
                Text('order_received_success'.tr(),
                    style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                const SizedBox(height: AppSizes.space32),
                _InfoRow(
                    label: 'order_number'.tr(), value: '#$_orderNumber'),
                const SizedBox(height: AppSizes.space12),
                _InfoRow(
                    label: 'required_amount'.tr(),
                    value: _formatPrice(_totalAmount)),
                const SizedBox(height: AppSizes.space12),
                _InfoRow(
                    label: 'payment_method'.tr(),
                    value: 'cash'.tr()),
                if (_couponCode != null) ...[
                  const SizedBox(height: AppSizes.space12),
                  _InfoRow(
                      label: 'coupons.applied_code'.tr(),
                      value: _couponCode!),
                  if (_couponDiscount > 0) ...[
                    const SizedBox(height: AppSizes.space12),
                    _InfoRow(
                        label: 'coupons.coupon_discount'.tr(),
                        value: '-${_formatPrice(_couponDiscount)}'),
                  ],
                ],
                if (_estimatedTime != null) ...[
                  const SizedBox(height: AppSizes.space12),
                  _InfoRow(
                      label: 'estimated_time'.tr(),
                      value: _estimatedTime!),
                ],
                const Spacer(flex: 3),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () =>
                        context.go('/order-tracking', extra: lastOrder),
                    icon: const Icon(Icons.map_outlined),
                    label: Text('track_order'.tr()),
                  ),
                ),
                const SizedBox(height: AppSizes.space12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.go('/home'),
                    child: Text('back_to_home'.tr()),
                  ),
                ),
                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p16, vertical: AppSizes.p14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radius12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.hintColor)),
          Text(value,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
