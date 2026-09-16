import 'package:flutter/material.dart';

/// A central class for managing consistent spacing, padding, corner radii, and other layout values.
/// This helps in maintaining a uniform design system across the app.
class AppSizes {
  // --- Paddings & Margins --- //
  static const double p4 = 4.0;
  static const double p6 = 6.0;
  static const double p8 = 8.0;
  static const double p10 = 10.0;
  static const double p12 = 12.0;
  static const double p14 = 14.0;
  static const double p16 = 16.0;
  static const double p18 = 18.0;
  static const double p20 = 20.0;
  static const double p24 = 24.0;
  static const double p30 = 30.0;
  static const double p32 = 32.0;
  static const double p40 = 40.0;
  static const double p45 = 45.0;
  static const double p48 = 48.0;
  static const double p50 = 50.0;
  static const double p55 = 55.0;
  static const double p80 = 80.0;
  static const double p100 = 100.0;
  static const double p140 = 140.0;

  // --- Spacing between widgets --- //
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space10 = 10.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space30 = 30.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space50 = 50.0; // As used in select_language.dart
  static const double space100 = 100.0; // As used in select_language.dart

  // --- Corner Radii --- //
  static const double radius8 = 8.0;
  static const double radius10 = 10.0;
  static const double radius12 = 12.0;
  static const double radius14 = 14.0;
  static const double radius15 = 15.0;
  static const double radius16 = 16.0;
  static const double radius18 = 18.0;
  static const double radius20 = 20.0;
  static const double radius24 = 24.0;
  static const double radius30 = 30.0;
  static const double radius32 = 32.0;
  static const double radius40 = 40.0; // For bottom sheet

  // --- Icon Sizes --- //
  static const double iconSize14 = 14.0;
  static const double iconSize15 = 15.0;
  static const double iconSize16 = 16.0;
  static const double iconSize18 = 18.0;
  static const double iconSize20 = 20.0;
  static const double iconSize22 = 22.0;
  static const double iconSize24 = 24.0;
  static const double iconSize28 = 28.0;
  static const double iconSize30 = 30.0;
  static const double iconSize48 = 48.0;
  static const double iconSize50 = 50.0;
  static const double iconSize70 = 70.0;

  // --- Widget Heights & Widths (Use with caution, prefer dynamic sizes) --- //
  static const double buttonHeight = 48.0;
  static const double buttonHeightSmall = 40.0;
  static const double inputFieldHeight = 48.0;
  static const double languageSelectItemHeight = 75.0;

  // --- Specific Component Sizes --- //
  static const double avatarRadius = 15.0; // e.g., AppBar user avatar
  static const double supportAvatarRadius = 30.0;
  static const double offerCardImageHeight = 160.0;
  static const double favoriteItemImageWidth = 110.0;
  static const double favoriteItemHeight = 120.0;
  static const double emptyFavoriteIconContainer = 140.0;

  // --- SizedBox Widgets for consistent spacing --- //
  static const SizedBox h4 = SizedBox(height: space4);
  static const SizedBox h8 = SizedBox(height: space8);
  static const SizedBox h10 = SizedBox(height: space10);
  static const SizedBox h12 = SizedBox(height: space12);
  static const SizedBox h16 = SizedBox(height: space16);
  static const SizedBox h20 = SizedBox(height: space20);
  static const SizedBox h24 = SizedBox(height: space24);
  static const SizedBox h30 = SizedBox(height: space30);
  static const SizedBox h40 = SizedBox(height: space40);
  static const SizedBox h32 = SizedBox(height: space32);
  static const SizedBox h100 = SizedBox(height: space32);

  static const SizedBox w4 = SizedBox(width: space4);
  static const SizedBox w8 = SizedBox(width: space8);
  static const SizedBox w12 = SizedBox(width: space12);
  static const SizedBox w16 = SizedBox(width: space16);
  static const SizedBox w10 = SizedBox(width: space10);
}