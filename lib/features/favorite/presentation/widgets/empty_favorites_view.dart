import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class EmptyFavoritesView extends StatelessWidget {
  const EmptyFavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    double scale = MediaQuery
        .of(context)
        .size
        .width / 375;
    scale = scale.clamp(0.8, 1.2);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 140 * scale,
          height: 140 * scale,
          decoration: BoxDecoration(
            color: theme.cardColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.favorite_border_rounded,
            size: 70 * scale,
            color: theme.hintColor.withValues(alpha: 0.5),
          ),
        ),
        SizedBox(height: 32 * scale),
        Text(
          'empty_fav_title'.tr(),
          style: theme.textTheme.titleLarge?.copyWith(fontSize: 22 * scale),
        ),
        SizedBox(height: 12 * scale),
        Text(
          'empty_fav_subtitle'.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16 * scale,
            color: theme.hintColor,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}