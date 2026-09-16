import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/app_sizes.dart';

class FavoriteListItem extends StatelessWidget {
  final dynamic item;
  final bool isMeal;
  final String imageUrl;
  final String title;
  final String subtitle;
  final String time;
  final String? distance;
  final String rating;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onTap; // ✅ إضافة حقل النقر

  const FavoriteListItem({
    super.key,
    required this.item,
    required this.isMeal,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.time,
    this.distance,
    required this.rating,
    required this.onToggleFavorite,
    this.onTap, // ✅ تحديث الـ constructor
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: GestureDetector(
        onTap: onTap, // ✅ تفعيل النقر على كامل العنصر
        child: Container(
          height: 130,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(24)),
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 110,
                  height: 130,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) =>
                      _buildErrorPlaceholder(theme),
                )
                    : _buildErrorPlaceholder(theme),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text(subtitle,
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(color: theme.hintColor),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: onToggleFavorite,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                  color: theme.scaffoldBackgroundColor,
                                  shape: BoxShape.circle),
                              child: Icon(Icons.favorite,
                                  color: theme.primaryColor, size: 18),
                            ),
                          ),
                        ],
                      ),
                      AppSizes.h12,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoRow(
                              Icons.access_time_sharp, "$time دقيقة", theme),
                          _buildInfoRow(
                              Icons.location_on_outlined, distance ?? "--", theme),
                          _buildRatingBadge(rating, theme),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder(ThemeData theme) {
    return Container(
      width: 110,
      height: 130,
      color: theme.dividerColor,
      child: const Icon(Icons.fastfood),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 14, color: theme.hintColor),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 11, color: theme.hintColor)),
      ],
    );
  }

  Widget _buildRatingBadge(String rating, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: theme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Text(rating,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor)),
          const SizedBox(width: 2),
          const Icon(Icons.star, color: Colors.orange, size: 12),
        ],
      ),
    );
  }
}