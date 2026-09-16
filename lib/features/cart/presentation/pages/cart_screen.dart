import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/app_sizes.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../location/presentation/bloc/location_bloc.dart';
import '../../../location/presentation/bloc/location_event.dart';
import '../bloc/mail_bloc.dart';
import '../bloc/mail_state.dart';
import '../bloc/mail_event.dart';


import '../widgets/cart_items_list.dart';
import '../widgets/cart_options_section.dart';
import '../widgets/cart_bill_summary.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../profile/presentation/cubit/profile_state.dart';

class CartScreen extends StatefulWidget {
  final bool isSelectLocation;
  final Function(int)? onBackToHome; // دالة للتحكم في التنقل الخارجي عبر الموجه (Router)

  const CartScreen(
      {super.key, required this.isSelectLocation, this.onBackToHome});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // متغيرات الحالة الخاصة بخيارات الطلب
  final TextEditingController _orderNotesController = TextEditingController();
  final TextEditingController _couponController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<MailBloc>().add(FetchCartEvent());
    context.read<LocationBloc>().add(LoadAddressesEvent());
  }

  @override
  void dispose() {
    _orderNotesController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  /// الكوبون يعمل حالياً على الطلبات السورية فقط — أخفِ واجهته لمستخدمي ألمانيا.
  bool _couponAllowed(BuildContext context) {
    final profileState = context.read<ProfileCubit>().state;
    if (profileState is ProfileLoaded) {
      return profileState.user.country != 'DE';
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(theme),
      body: BlocListener<MailBloc, MailState>(
        listener: (context, state) {
          if (state.status == CartStatus.orderConfirmed) {
            final order = state.lastOrder;
            if (order != null) {
              context.push('/order-confirmed', extra: order);
            }
          }
        },
        child: BlocBuilder<MailBloc, MailState>(
          builder: (context, state) {
            if (state.status == CartStatus.error &&
                state.changedPrices == null) {
              return _buildErrorState(state.errorMessage);
            }
            if (state.items.isEmpty &&
                state.status != CartStatus.success &&
                state.status != CartStatus.orderConfirmed) {
              return _buildLoadingState(theme);
            }
            if (state.items.isEmpty) {
              return _buildEmptyState();
            }

            return SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          if (state.changedPrices != null &&
                              state.changedPrices!.isNotEmpty)
                            _buildPriceWarning(theme, state),
                          AppSizes.h16,
                          // عرض قائمة الوجبات
                          CartItemsList(items: state.items,
                              currency: state.currency,
                              status: state.status),
                          AppSizes.h20,
                          // خيارات التوصيل والدفع والملاحظات
                          CartOptionsSection(
                            notesController: _orderNotesController,
                            currency: state.currency,
                          ),
                          AppSizes.h20,
                          // ملخص الحساب النهائي مع تمرير دالة التنقل لشاشة الدفع
                           CartBillSummary(
                             state: state,
                             isDelivery: true,
                             notesController: _orderNotesController,
                             couponController: _couponController,
                             showCouponUI: _couponAllowed(context),
                           ),
                          AppSizes.h100,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // بناء الهيدر العلوي للسلة
  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      toolbarHeight: 70,
      automaticallyImplyLeading: false,
      flexibleSpace: SafeArea(
        child: BlocBuilder<MailBloc, MailState>(
          builder: (context, state) {
            return Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(AppSizes.radius24)),
              ),
              child: Row(
                children: [
                  _buildBackIcon(theme),
                  _buildHeaderTitle(theme, state.items.length),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBackIcon(ThemeData theme) {
    return InkWell(
      onTap: () => widget.onBackToHome?.call(0),
      child: Container(
        margin: const EdgeInsets.all(8),
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: theme.dividerColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizes.radius12),
        ),
        child: Icon(Icons.adaptive.arrow_back, color: theme.iconTheme.color),
      ),
    );
  }

  Widget _buildHeaderTitle(ThemeData theme, int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('cart_screen_title'.tr(),
            style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('cart_items_count'.tr(args: [count.toString()]),
            style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return AppErrorView.empty(
      icon: Icons.shopping_cart_outlined,
      title: 'cart_empty_title'.tr(),
      message: 'cart_empty_subtitle'.tr(),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.primaryColor),
          const SizedBox(height: 16),
          Text('loading'.tr(),
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor)),
        ],
      ),
    );
  }

  Widget _buildPriceWarning(ThemeData theme, MailState state) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: theme.colorScheme.error, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              state.errorMessage ?? 'prices_changed_msg'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error),
            ),
          ),
          TextButton(
            onPressed: () => context.read<MailBloc>().add(FetchCartEvent()),
            child: Text('update_prices'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String? message) {
    return AppErrorView(
      icon: Icons.error_outline_rounded,
      title: 'error_title'.tr(),
      message: message ?? 'error_fetching_cart'.tr(),
      actionLabel: 'retry'.tr(),
      onAction: () => context.read<MailBloc>().add(FetchCartEvent()),
    );
  }
}