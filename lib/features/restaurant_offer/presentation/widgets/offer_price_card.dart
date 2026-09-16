import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/utils/app_sizes.dart';

class OfferPriceCard extends StatelessWidget {
  final double originalPrice;
  final double discountPercent;

  const OfferPriceCard({
    super.key,
    required this.originalPrice,
    required this.discountPercent,
  });

  @override
  Widget build(BuildContext context) {
    double savings = originalPrice * (discountPercent / 100);
    double finalPrice = originalPrice - savings;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE95433), Color(0xFFFB603D)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radius20),
        boxShadow: [
          BoxShadow(color: const Color(0xFFE95433).withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("offers.price_after_discount".tr(),
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Text("${finalPrice.toInt()} ${"units.currency".tr()}",
                        style: const TextStyle(color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    Text("${originalPrice.toInt()} ${"units.currency".tr()}",
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13,
                            decoration: TextDecoration.lineThrough)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSizes.radius12)),
            child: Column(
              children: [
                Text("offers.you_saved".tr(),
                    style: const TextStyle(color: Colors.white, fontSize: 10)),
                Text("${savings.toInt()} ${"units.currency".tr()}",
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}