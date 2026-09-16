import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../domain/models/offer_model.dart';

class OfferCard extends StatelessWidget {
  final Offer offer;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const OfferCard({
    super.key,
    required this.offer,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isActive = offer.isActive;

    return GestureDetector(
      onTap: isActive ? onTap : null,
      child: Opacity(
        opacity: isActive ? 1.0 : 0.6,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:
                    theme.brightness == Brightness.dark ? 0.3 : 0.05),
                blurRadius: 10,
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildImageHeader(theme),
              _buildOfferDetails(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageHeader(ThemeData theme) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Image.network(
            offer.foodImage,
            width: double.infinity,
            height: 180,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 180,
              width: double.infinity,
              color: theme.scaffoldBackgroundColor,
              child: Icon(Icons.fastfood_outlined,
                  size: 60, color: theme.hintColor),
            ),
          ),
        ),
        Positioned(
          top: 12,
          left: 12,
          child: GestureDetector(
            onTap: onFavoriteToggle,
            child: CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.6),
              radius: 18,
              child: Icon(
                Icons.favorite_border,
                color: theme.hintColor,
                size: 20,
              ),
            ),
          ),
        ),
        if (offer.discountTag.isNotEmpty)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: offer.isActive ? theme.primaryColor : Colors.grey,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                offer.discountTag,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  Color _freeDeliveryColor(ThemeData theme) {
    return theme.brightness == Brightness.dark
        ? Colors.green.shade400
        : Colors.green.shade700;
  }

  Widget _buildOfferDetails(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(offer.restaurantName,
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold)),
              ),
              if (offer.foodRating != null) ...[
                const Icon(Icons.star, color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text(offer.foodRating!.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(offer.foodName,
              style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.primaryColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(
            '${offer.effectivePrice.toStringAsFixed(0)} ${'currency'.tr()}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          if (offer.type == 'free_delivery')
            Row(
              children: [
                Icon(
                  Icons.delivery_dining,
                  size: 16,
                  color: _freeDeliveryColor(theme),
                ),
                const SizedBox(width: 4),
                Text(
                  "offers.free_delivery".tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: _freeDeliveryColor(theme),
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
