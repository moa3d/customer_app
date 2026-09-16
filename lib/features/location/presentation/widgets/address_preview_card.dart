import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/utils/app_sizes.dart';

class AddressPreviewCard extends StatelessWidget {
  final String fullAddress;

  const AddressPreviewCard({super.key, required this.fullAddress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSizes.p20),
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSizes.radius14),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 45,
              height: 45,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.radius12),
                  color: theme.primaryColor),
              child: const Icon(
                  Icons.location_on_outlined, color: Colors.white)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("full_address_title".tr(),
                  style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(fullAddress, style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7))),
            ]),
          ),
        ],
      ),
    ).animate().fadeIn().scale(delay: 200.ms);
  }
}