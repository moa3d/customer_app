import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:nomnow_app/features/intro/presentation/pages/select_display_screen.dart';

import '../../../../core/utils/app_sizes.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/welcomebackground.jpg"),
            fit: BoxFit.fill,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 3),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "welcome_title".tr(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: AppSizes.space16,
                  color: isDarkTheme ? const Color(0xffA19EA0) : Colors
                      .grey[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "welcome_subtitle".tr(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: AppSizes.p14,
                  color: isDarkTheme ? const Color(0xffA19EA0) : Colors
                      .grey[600],
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0, left: 10, right: 10),
              child: SizedBox(
                width: double.infinity,
                height: AppSizes.buttonHeight,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SelectDisplayScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radius16),
                    ),
                    backgroundColor: theme.primaryColor,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildCircleIcon(Icons.arrow_back),
                        Text(
                          'welcome_button'.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        _buildCircleIcon(Icons.rocket_launch_outlined),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .slideX(
                  begin: 1,
                  end: 0,
                  duration: 500.ms,
                  curve: Curves.easeOutQuad,
                )
                    .fadeIn(duration: 800.ms),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 1200.ms),
    );
  }

  Widget _buildCircleIcon(IconData icon) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.white.withValues(alpha: 0.2),
      child: Icon(icon, color: Colors.white, size: AppSizes.iconSize18),
    );
  }
}