import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/app_sizes.dart';
import '../../../../core/widgets/arrowforward.dart';

AppBar appBarLocationOrder({required ThemeData theme, required BuildContext context})  {
  return AppBar(
    backgroundColor: theme.cardColor,
    automaticallyImplyLeading: false,
    flexibleSpace: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ActionButton(onPressed: () => Navigator.pop(context)),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: theme.primaryColor.withValues(alpha: 0.5),
                    shape: const CircleBorder(),
                  ),
                  onPressed: () {},
                  icon: const Icon(
                    Icons.location_on_outlined,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            AppSizes.h12,
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8),
              child: Text(
                "add_location_title".tr(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "add_location_subtitle".tr(),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    ),
    toolbarHeight: 170,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppSizes.radius24)),
    ),
  );
}
