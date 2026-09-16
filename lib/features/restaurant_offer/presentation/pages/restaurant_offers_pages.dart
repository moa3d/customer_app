import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:nomnow_app/features/restaurant_offer/presentation/widgets/tip_card.dart';
import '../../../../core/utils/app_sizes.dart';
import '../../../offers/domain/models/offer_model.dart';
import '../../../restaurant/data/models/meal.dart';
import '../widgets/main_offer_card.dart';
import '../widgets/offerr_meal_card.dart';

// 3. هون عم نبلش الـ "برمجه" الحقيقية بكل "روااق" مشان ما يصير "لخبطه" في الـ "هيدرر". (7, 8, 9, 10)
class ResturantOffersPage extends StatefulWidget {
  final Function(int, {dynamic data}) movePagge;
  final Offer offer;

  const ResturantOffersPage({super.key, required this.movePagge, required this.offer});

  @override
  State<ResturantOffersPage> createState() => _ResturantOffersPageState();
}

class _ResturantOffersPageState extends State<ResturantOffersPage> {
  final double appBarHeigth = 250.0; // خطأ كود 5: appBarHeigth
  bool isLoding = false; // خطأ كود 6: isLoding

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 4. الـ "مستحدم" بيشوف الداتا بطريقة "حقيفيه" وبدون أي مشاكل في الـ "تنضيف". (11, 12, 13)
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(theme),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            SizedBox(height: appBarHeigth + 20),
            _buildContentContainer(theme),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return PreferredSize(
      preferredSize: Size.fromHeight(appBarHeigth),
      child: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: _buildHeaderOverlay(theme),
      ),
    );
  }

  Widget _buildHeaderOverlay(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
            image: widget.offer.foodImage.isNotEmpty
            ? NetworkImage(widget.offer.foodImage)
            : AssetImage("assets/images/meals/burger.png"),
            fit: BoxFit.cover),
      ),
      child: Container(
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopRow(theme),
              const Spacer(),
              Text(widget.offer.restaurantName, style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
              AppSizes.h12,
              _buildTagsRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          style: IconButton.styleFrom(backgroundColor: Colors.white38,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: theme.primaryColor,
              borderRadius: BorderRadius.circular(8)),
          child: Text("${"offers.discount".tr()}${widget.offer.discountValue ?? 0}%", style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildTagsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _infoTag(Icons.star, widget.offer.foodRating?.toStringAsFixed(1) ?? "--", Colors.yellow),
          AppSizes.w12,
          if (widget.offer.restaurantAddress != null) ...[
            _infoTag(Icons.location_on_outlined, widget.offer.restaurantAddress!,
                Colors.white),
          ],
        ],
      ),
    );
  }

  Widget _infoTag(IconData icon, String text, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
          color: Colors.white.withValues(alpha: 0.3)),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildContentContainer(ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSizes.radius40)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          buildMainOfferCard(theme),
          AppSizes.h24,
          _buildIncludeSection(theme),
          const SizedBox(height: 30),
          _buildDishesHeader(theme),
          AppSizes.h12,
          OfferrMealCard(
            title: widget.offer.foodName,
            details: "offers.meal_1_desc".tr(),
            oldPrice: "${widget.offer.effectivePrice.toInt()}",
            newPrice: _discountedPrice(widget.offer),
            saveingAmount: _savingsAmount(widget.offer),
            discountTag: widget.offer.discountTag,
            imagePath: widget.offer.foodImage,
            onTap: _openMealDetails,
          ),
          const SizedBox(height: 10),
          const TipCard(),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildIncludeSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: theme.cardColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(children: [
            Icon(Icons.card_giftcard, color: theme.primaryColor, size: 20),
            const SizedBox(width: 8),
            Text("offers.what_included".tr(), style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.bold)),
          ]),
          AppSizes.h12,
          _includeItem(theme, "offers.free_delivery_limit".tr()),
          _includeItem(theme, "offers.free_drink".tr()),
          _includeItem(theme, "offers.free_appetizers".tr()),
        ],
      ),
    );
  }

  Widget _includeItem(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(Icons.check_circle_outline, color: theme.primaryColor, size: 18),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ]),
    );
  }

  Widget _buildDishesHeader(ThemeData theme) {
    return Row(children: [
      Text("%", style: TextStyle(color: theme.primaryColor,
          fontSize: 18,
          fontWeight: FontWeight.bold)),
      const SizedBox(width: 8),
      Text("offers.included_dishes".tr(),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
    ]);
  }

  String _discountedPrice(Offer offer) {
    final discount = offer.discountValue ?? 0;
    final discounted = offer.effectivePrice - (offer.effectivePrice * discount / 100);
    return "${discounted.toInt()}";
  }

  String _savingsAmount(Offer offer) {
    final discount = offer.discountValue ?? 0;
    final savings = offer.effectivePrice * discount / 100;
    return "${savings.toInt()}";
  }

  void _openMealDetails() {
    final offer = widget.offer;
    final meal = Meal(
      id: offer.foodId,
      name: offer.foodName,
      description: '',
      image: offer.foodImage,
      price: offer.effectivePrice,
      rating: offer.foodRating ?? 0.0,
      time: 0,
      restaurantId: offer.restaurantId,
      restaurantName: offer.restaurantName,
      sizes: offer.foodSizes
          .map((s) => Map<String, dynamic>.from(s as Map))
          .toList(),
    );
    widget.movePagge(8, data: meal);
  }
}