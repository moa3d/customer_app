import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nomnow_app/features/meal_selection/presentation/widgets/header.dart';
import '../../../../core/utils/app_sizes.dart';
import '../../../../features/cart/presentation/bloc/mail_bloc.dart';
import '../../../../features/cart/presentation/bloc/mail_state.dart';
import '../../../../features/cart/presentation/bloc/mail_event.dart';
import '../../../../features/cart/domain/models/mail_item.dart';

import '../../../restaurant/data/models/meal.dart';
import '../../../restaurant/data/services/restaurant_service.dart';
import '../widgets/meal_size_selector.dart';
import '../widgets/meal_quantity_step.dart';
import '../widgets/meal_customization_step.dart';
import '../widgets/meal_review_step.dart';
import '../widgets/add_to_cart_button.dart';
import '../widgets/price_summary_card.dart';

class MealDetailsPage extends StatefulWidget {
  final Function(int, {dynamic data}) movePage;
  final Meal? food;

  const MealDetailsPage({super.key, required this.movePage, this.food});

  @override
  State<MealDetailsPage> createState() => _MealDetailsPageState();
}

class _MealDetailsPageState extends State<MealDetailsPage> {
  late String mealImage;
  late double basePrice;
  late double time;
  int localQuantity = 1;
  Map<String, dynamic>? selectedSizeData;
  int currentStep = 0;
  List<Map<String, dynamic>> selectedAdditions = [];
  double additionsTotal = 0.0;

  // بيانات محدَّثة تصل بالخلفية من GET /api/user/food/:id — سعر وعروض حالية
  final RestaurantService _restaurantService = RestaurantService();
  int? _activeDiscountPercent;

  /// وجهة الانتقال بعد نجاح الإضافة (1 = السلة، 0 = رجوع للمطعم)، أو null
  /// إن لم يكن هناك نداء إضافة جارٍ.
  ///
  /// كان الانتقال يقع فور إطلاق الحدث قبل ردّ الخادم، فإن رُفضت الإضافة
  /// (وجبة نفدت، حجم غير صالح، كمية غير صالحة) يجد المستخدم نفسه في السلة
  /// بلا وجبته وبلا سبب ظاهر — ورسالة الرفض تُعرض على شاشة غادرها.
  int? _pendingNavTarget;

  /// سعر الوحدة قبل الخصم — من الحجم المختار أو السعر الأساسي.
  double get _unitPrice => selectedSizeData != null
      ? (selectedSizeData!['price'] as num).toDouble()
      : basePrice;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _refreshFoodDetails();
  }

  void _initializeData() {
    mealImage = widget.food?.image ?? 'assets/images/meals/burger.png';
    time = widget.food?.time ?? 0;
    _activeDiscountPercent = widget.food?.activeDiscountPercent;

    if (widget.food?.sizes != null && widget.food!.sizes.isNotEmpty) {
      selectedSizeData = widget.food!.sizes[0];
      basePrice = (selectedSizeData!['price'] as num).toDouble();
    } else {
      basePrice = (widget.food?.price ?? 0.0).toDouble();
    }
  }

  // تحديث صامت بالخلفية لأحدث سعر وعروض للصنف من السيرفر (لا يوقف عرض الشاشة
  // أثناء التحميل، ويحدّث القيم فقط إن نجح الطلب).
  Future<void> _refreshFoodDetails() async {
    final foodId = widget.food?.id;
    if (foodId == null || foodId.isEmpty) return;
    try {
      final response = await _restaurantService.getFoodById(foodId);
      if (!mounted) return;
      final freshFood = Meal.fromJson(response.data['food']);
      setState(() {
        _activeDiscountPercent = freshFood.activeDiscountPercent;
        // نحدّث السعر الأساسي فقط للأصناف بلا أحجام (تفادياً لتعارض فهرسة
        // الأحجام إن تغيّر ترتيبها بالسيرفر بين الطلبين).
        if (selectedSizeData == null) {
          basePrice = freshFood.price;
        }
      });
    } catch (_) {
      // فشل التحديث الصامت ليس خطأً حرجاً — تبقى البيانات الأصلية المعروضة سليمة
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.food == null) {
      return Scaffold(
        body: Center(
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      );
    }

    final double unitPrice = _unitPrice;

    // السعر الأصلي (قبل الحسم) والمخفّض (بعد الحسم) بناءً على نسبة الخصم
    // النشطة على هذا الصنف. يُعرض الأصل بخط وسطي بجانب المخفّض في مكونات
    // التخصيص (الكمية/المراجعة/ملخص السعر).
    final bool hasDiscount = _activeDiscountPercent != null;
    final double originalPrice = unitPrice;
    final double displayUnitPrice = hasDiscount
        ? unitPrice * (1 - _activeDiscountPercent! / 100)
        : unitPrice;

    return BlocListener<MailBloc, MailState>(
      listenWhen: (_, _) => _pendingNavTarget != null,
      listener: _onAddToCartResult,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              buildFeaturedItem(
                context: context,
                imagePath: mealImage,
                isNetwork: widget.food != null,
                meal: widget.food!,
                time: "${time.toInt()} ${'minute'.tr()}",
                onBack: () {
                  setState(() {
                    if (currentStep == 0) {
                      widget.movePage(0);
                    } else if (currentStep == 4 || currentStep == 3) {
                      currentStep = 2;
                    } else {
                      currentStep--;
                    }
                  });
                },
              ),
              AppSizes.h10,
              _buildMealInfoWidget(),
              AppSizes.h10,

              // 1. محتوى الخطوات
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Container(
                  key: ValueKey<int>(currentStep),
                  child: _getStepWidget(displayUnitPrice,
                      originalPrice: originalPrice),
                ),
              ),

              // 2. ملخص السعر (يظهر دائماً بعد الخطوة 0)
              if (currentStep > 0) ...[
                const SizedBox(height: 24),
                PriceSummaryCard(
                  basePrice: displayUnitPrice,
                  originalPrice: originalPrice,
                  extrasTotal: additionsTotal,
                  quantity: localQuantity,
                  currency: "units.currency".tr(),
                ),
                const SizedBox(height: 20),
              ],

              // 3. الزر التفاعلي الموحد (تم، أو إضافة للسلة)
              if (currentStep == 2 || currentStep == 3 || currentStep == 4)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSizes.p16),
                  child: _buildMainActionButton(),
                ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  /// نتيجة نداء الإضافة: ننتقل عند النجاح فقط، ونُبقي المستخدم مكانه مع
  /// رسالة الخادم عند الرفض.
  void _onAddToCartResult(BuildContext context, MailState state) {
    final target = _pendingNavTarget;
    if (target == null) return;

    if (state.status == CartStatus.success) {
      _pendingNavTarget = null;
      widget.movePage(target);
    } else if (state.status == CartStatus.error) {
      _pendingNavTarget = null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage ?? 'errors.unknown_msg'.tr()),
        ),
      );
    }
  }

  Widget _buildMainActionButton() {
    final theme = Theme.of(context);
    // إذا كنا في خطوة التخصيص (Step 3) النص يكون "تم"
    final bool isCustomizing = currentStep == 3;

    return BlocBuilder<MailBloc, MailState>(
      builder: (context, state) {
        final bool isLoading = state.status == CartStatus.loading;

        return ElevatedButton(
          onPressed: isLoading ? null : () {
            if (isCustomizing) {
              // عند الضغط على "تم" ننتقل لخطوة المراجعة
              setState(() => currentStep = 4);
            } else {
              // عند الضغط على "إضافة للسلة" ننفذ منطق الإضافة، والانتقال
              // للسلة يتم بعد نجاح الإضافة لا قبلها
              _handleAddToCart();
            }
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 55),
            backgroundColor: theme.primaryColor,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
            isCustomizing ? "offers.done".tr() : "order.add_to_cart".tr(),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        );
      },
    );
  }

  /// [navTarget] وجهة الانتقال بعد نجاح الإضافة: 1 السلة، 0 رجوع للمطعم
  /// لاختيار وجبة أخرى.
  void _handleAddToCart({int navTarget = 1}) {
    final currentState = context.read<MailBloc>().state;
    final newRestaurantId = widget.food?.restaurantId ?? '';

    // فحص تعارض المطاعم: هل السلة بها عناصر من مطعم مختلف؟
    if (currentState.items.isNotEmpty && newRestaurantId.isNotEmpty) {
      final cartRestaurantId = currentState.items.first.restaurantId;
      if (cartRestaurantId.isNotEmpty && cartRestaurantId != newRestaurantId) {
        _showConflictDialog(navTarget);
        return;
      }
    }

    // لا يوجد تعارض — إضافة عادية
    _doAddToCart(navTarget);
  }

  /// الوجبة كما يراها المستخدم الآن — تُبنى مرة واحدة ويستعملها المساران.
  MailItem _buildItem() => MailItem(
        id: '',
        foodId: widget.food?.id ?? '',
        restaurantId: widget.food?.restaurantId ?? '',
        title: widget.food?.name ?? "",
        price: _unitPrice,
        size: selectedSizeData?['name'],
        sizePrice: (selectedSizeData?['price'] as num?)?.toDouble(),
        quantity: localQuantity,
        imagePath: mealImage,
        extras: selectedAdditions,
        notes: "",
      );

  void _doAddToCart(int navTarget) {
    _pendingNavTarget = navTarget;
    context.read<MailBloc>().add(AddToCartEvent(_buildItem()));
  }

  void _showConflictDialog(int navTarget) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'cart_conflict_title'.tr(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'cart_conflict_message'.tr(),
          style: const TextStyle(fontSize: 15, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('cancel'.tr(), style: const TextStyle(fontSize: 16)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // استبدال سلة المطعم الآخر بهذه الوجبة في نداء واحد
              _pendingNavTarget = navTarget;
              context
                  .read<MailBloc>()
                  .add(ClearAndAddToCartEvent(_buildItem()));
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: Text('clear_and_add'.tr(), style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _getStepWidget(double unitPrice, {double? originalPrice}) {
    switch (currentStep) {
      case 0:
        return Padding(
          padding: EdgeInsets.all(AppSizes.p18),
          child: AddToCartButton(
            onTap: () {
              if (widget.food?.sizes == null || widget.food!.sizes.isEmpty) {
                setState(() => currentStep = 2);
              } else {
                setState(() => currentStep = 1);
              }
            },
          ),
        );
      case 1:
        return MealSizeSelector(
          sizes: widget.food?.sizes ?? [],
          selectedSizeData: selectedSizeData,
          onSizeSelected: (size) =>
              setState(() {
                selectedSizeData = size;
                currentStep = 2;
              }),
        );
      case 2:
        return MealQuantityStep(
          basePrice: unitPrice,
          originalPrice: originalPrice ?? unitPrice,
          selectedSize: selectedSizeData != null
              ? "units.size_${selectedSizeData!['name']}".tr()
              : "order.standard_size".tr(),
          sizeIncrement: 0,
          onQuantityChanged: (newQty) => setState(() => localQuantity = newQty),
          onCustomizeTap: () => setState(() => currentStep = 3),
          onChangeSize: selectedSizeData != null
              ? () => setState(() => currentStep = 1)
              : null,
        );
      case 3:
        return MealCustomizationStep(
          unitPrice: unitPrice,
          originalPrice: originalPrice ?? unitPrice,
          currentQuantity: localQuantity,
          availableExtras: widget.food?.extras ?? [],
          ingredients: widget.food?.ingredients ?? [],
          onQuantityChanged: (newQty) => setState(() => localQuantity = newQty),
          onChanged: (extras, price) {
            setState(() {
              selectedAdditions = extras;
              additionsTotal = price;
            });
          },
        );
      case 4:
        return MealReviewStep(
          unitPrice: unitPrice,
          originalPrice: originalPrice ?? unitPrice,
          quantity: localQuantity,
          extras: selectedAdditions,
          extrasTotal: additionsTotal,
          selectedSizeName: selectedSizeData?['name']?.toString(),
          sizePrice: (selectedSizeData?['price'] as num?)?.toDouble(),
          onQuantityChanged: (newQty) => setState(() => localQuantity = newQty),
          onEdit: () => setState(() => currentStep = 3),
          // يضيف الوجبة ثم يرجع لقائمة المطعم (movePage(0)) بدل السلة
          onAddAnother: () => _handleAddToCart(navTarget: 0),
          onDelete: () =>
              setState(() {
                selectedAdditions = [];
                additionsTotal = 0.0;
                currentStep = 2;
              }),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMealInfoWidget() {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(
          horizontal: AppSizes.p16, vertical: AppSizes.p8),
      padding: EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.food?.restaurantName ?? "order.restaurant_name".tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  )),
              _ratingBadge(widget.food?.rating.toString() ?? "0.0", theme),
            ],
          ),
          AppSizes.h12,
          Text(widget.food?.name ?? "",
              style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold)),
          AppSizes.h8,
          Text(widget.food?.description ?? "",
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor)),
          if (_activeDiscountPercent != null) ...[
            AppSizes.h8,
            _discountBadge(_activeDiscountPercent!, theme),
          ],
        ],
      ),
    );
  }

  // شارة خصم نشط — تُعرض فقط إن كان الصنف مشمولاً بعرض discount فعّال حالياً
  Widget _discountBadge(int percent, ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: AppSizes.p8, vertical: AppSizes.p4),
      decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizes.radius8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department, color: Colors.red, size: 14),
          AppSizes.w4,
          Text(
            "offers.discount_badge".tr(args: ["$percent"]),
            style: const TextStyle(
                color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _ratingBadge(String rating, ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: AppSizes.p8, vertical: AppSizes.p4),
      decoration: BoxDecoration(
          color: theme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizes.radius12)),
      child: Row(
        children: [
          Icon(
              Icons.star, color: theme.primaryColor, size: AppSizes.iconSize14),
          AppSizes.w4,
          Text(rating, style: TextStyle(
              color: theme.primaryColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}