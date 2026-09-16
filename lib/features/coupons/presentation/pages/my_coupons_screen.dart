import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/routes.dart';
import '../../../../core/utils/app_sizes.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../cart/presentation/bloc/mail_bloc.dart';
import '../../../cart/presentation/bloc/mail_event.dart';
import '../../data/services/coupon_service.dart';
import '../../domain/models/coupon.dart';

class MyCouponsScreen extends StatefulWidget {
  const MyCouponsScreen({super.key});

  @override
  State<MyCouponsScreen> createState() => _MyCouponsScreenState();
}

class _MyCouponsScreenState extends State<MyCouponsScreen> {
  final CouponService _service = CouponService();
  List<Coupon> _coupons = [];
  bool _isLoading = true;
  Object? _error;
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    _fetchCoupons();
  }

  Future<void> _fetchCoupons() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final coupons = await _service.getCoupons();
      // القابل للاستخدام أولاً ثم غير القابل — بغض النظر عن ترتيب الوصول
      coupons.sort((a, b) {
        if (a.isUsable == b.isUsable) return 0;
        return a.isUsable ? -1 : 1;
      });
      setState(() {
        _coupons = coupons;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e;
      });
    }
  }

  Future<void> _applyCoupon(Coupon coupon) async {
    if (_applying) return;
    setState(() => _applying = true);

    try {
      // مسار واحد للتطبيق عبر الـ Bloc — الشاشة تتبع السلة في إعادة الجلب
      context.read<MailBloc>().add(ApplyCouponEvent(code: coupon.code));
      context.go(Routes.cart);
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(theme),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? AppErrorView.fromError(_error, onRetry: _fetchCoupons)
              : _coupons.isEmpty
                  ? _buildEmpty()
                  : _buildList(),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      scrolledUnderElevation: 0,
      backgroundColor: theme.cardColor,
      automaticallyImplyLeading: false,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: Material(
          color: theme.primaryColor.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.pop(),
            child: Icon(Icons.adaptive.arrow_back),
          ),
        ),
      ),
      title: Text('coupons.screen_title'.tr(),
          style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold)),
      centerTitle: true,
    );
  }

  Widget _buildEmpty() {
    return AppErrorView.empty(
      icon: Icons.confirmation_number_outlined,
      title: 'coupons.no_coupons'.tr(),
      message: 'coupons.no_coupons_subtitle'.tr(),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _fetchCoupons,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSizes.p16),
        itemCount: _coupons.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final coupon = _coupons[index];
          return _CouponCard(
            coupon: coupon,
            enabled: coupon.isUsable && !coupon.isExpired,
            onTap: coupon.isUsable && !coupon.isExpired
                ? () => _applyCoupon(coupon)
                : null,
          );
        },
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  final Coupon coupon;
  final bool enabled;
  final VoidCallback? onTap;

  const _CouponCard({
    required this.coupon,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool disabled = !enabled;

    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        coupon.code,
                        style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: disabled
                                ? theme.hintColor
                                : theme.primaryColor),
                      ),
                    ),
                    if (disabled) _badge(theme, 'coupons.unavailable_badge'.tr()),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  coupon.formatValue(),
                  style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600),
                ),
                if (coupon.minOrderValue != null &&
                    coupon.minOrderValue! > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    'coupons.min_order'.tr(
                        namedArgs: {'value': coupon.minOrderValue!.toString()}),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        coupon.expiryLabel(),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.hintColor),
                      ),
                    ),
                    Text(
                      _usageLabel(),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(ThemeData theme, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.hintColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.hintColor, fontWeight: FontWeight.w600)),
    );
  }

  String _usageLabel() {
    final remaining = coupon.remainingUses;
    if (remaining == null) return 'coupons.usage_unlimited'.tr();
    if (remaining <= 0) return 'coupons.used_badge'.tr();
    return 'coupons.usage_remaining'.tr(namedArgs: {'n': remaining.toString()});
  }
}
