import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import 'package:nomnow_app/core/widgets/animated_page_indicator.dart';
import 'package:nomnow_app/core/routing/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_sizes.dart';
import '../../../orders/data/repositories/order_repository.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            gradient: isDarkTheme ? AppTheme.myBackgroundGradient : null,
          ),
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLogoSection(context, isDarkTheme),
            ],
          ),
        ).animate(
          onComplete: (controller) async {
            // تنفيذ منطق فحص الجلسة عند انتهاء الأنميشن
            await _handleNavigation();
          },
        )
            .fadeIn(duration: 1.seconds)
            .fadeOut(delay: const Duration(seconds: 3)),
      ),
    );
  }

  /// بناء قسم الشعار والنصوص لضمان خفة الكود في دالة البناء الرئيسية
  Widget _buildLogoSection(BuildContext context, bool isDarkTheme) {
    final size = MediaQuery
        .of(context)
        .size;

    return Container(
      width: size.width,
      height: size.height / 2,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/logosplash.png"),
          fit: BoxFit.fill,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: AppSizes.space32 * 2.5,
            left: 0,
            right: 0,
            child: Text(
              "splash_subtitle".tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDarkTheme ? Colors.white : Colors.black,
                fontSize: AppSizes.space20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedPageIndicator(),
          ),
        ],
      ),
    );
  }

  /// منطق التنقل باستخدام GoRouter لضمان تجربة مستخدم احترافية
  Future<void> _handleNavigation() async {
    final authService = AuthService();
    final token = await authService.getToken();

    final prefs = await SharedPreferences.getInstance();
    final bool isFirstTime = prefs.getBool('is_first_time') ?? true;

    if (!mounted) return;

    if (token == null || token.isEmpty) {
      context.go(isFirstTime ? Routes.welcome : Routes.authSelection);
      return;
    }

    context.go(Routes.home);

    // استعادة الطلب الجاري إن وُجد
    final activeOrder = await OrderRepository().getActiveOrder();
    if (!mounted || activeOrder == null) return;
    context.push(Routes.orderTracking, extra: activeOrder);
  }
}