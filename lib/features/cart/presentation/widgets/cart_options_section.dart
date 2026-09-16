import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:nomnow_app/features/location/presentation/pages/add_location_page.dart';
import '../../../../core/utils/app_sizes.dart';
import '../../../location/data/models/address_model.dart';
import '../../../location/presentation/bloc/location_bloc.dart';
import '../../../location/presentation/bloc/location_state.dart';
import 'private_notes_widget.dart';

class CartOptionsSection extends StatelessWidget {
  final TextEditingController notesController;
  final String currency;

  const CartOptionsSection({
    super.key,
    required this.notesController,
    this.currency = "",
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        _buildDeliveryBox(context, theme),
        AppSizes.h20,
        _buildPaymentBox(theme),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: PrivateNotesWidget(controller: notesController),
        ),
      ],
    );
  }

  Widget _buildDeliveryBox(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.p16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(AppSizes.radius16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: theme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'delivery_method'.tr(),
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            AppSizes.h16,
            _buildAddressPart(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentBox(ThemeData theme) {
    // ألمانيا (يورو) → الدفع إلزامي بالبطاقة عبر Stripe (يفرضه الباك تلقائياً).
    // أي عملة أخرى (سوريا) → الدفع نقداً كما هو معمول به حالياً.
    final bool isCardPayment = currency == "EUR" || currency == "€";
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.p16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(AppSizes.radius16),
        ),
        child: Row(
          children: [
            Icon(Icons.wallet, color: theme.primaryColor, size: 20),
            const SizedBox(width: 8),
            Text('payment_method'.tr(), style: theme.textTheme.titleMedium),
            const Spacer(),
            Row(
              children: [
                Icon(
                  isCardPayment ? Icons.credit_card : Icons.check_circle,
                  color: isCardPayment ? theme.primaryColor : Colors.green,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  isCardPayment ? 'card_payment'.tr() : 'cash'.tr(),
                  style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressPart(BuildContext context, ThemeData theme) {
    return BlocBuilder<LocationBloc, LocationState>(
      builder: (context, state) {
        AddressModel? addr;
        if (state is LocationSuccess) addr = state.selectedAddress;
        return Column(
          children: [
            AppSizes.h12,
            addr != null
                ? _buildAddressCard(context, theme, addr)
                : _buildNoAddressBtn(context, theme),
          ],
        );
      },
    );
  }

  Widget _buildAddressCard(
    BuildContext context,
    ThemeData theme,
    AddressModel address,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.p8),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radius16),
        border: Border.all(color: theme.primaryColor, width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.p12),
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  borderRadius: BorderRadius.circular(AppSizes.radius12),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address.addressName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${address.city}، ${address.area}",
                      style: TextStyle(color: theme.hintColor, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddLocationPage(),
                  ),
                ),
                child: Text(
                  'edit_button'.tr(),
                  style: TextStyle(color: theme.primaryColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoAddressBtn(BuildContext context, ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.p45,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: theme.scaffoldBackgroundColor,
          side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radius12),
          ),
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddLocationPage()),
        ),
        child: Text(
          'set_location'.tr(),
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
        ),
      ),
    );
  }
}
