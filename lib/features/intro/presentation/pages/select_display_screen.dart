import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// [تعديل المسار] استيراد الشاشة التالية من مكانها الجديد
import 'package:nomnow_app/features/intro/presentation/pages/select_language_screen.dart';

import '../../../../core/bloc/settings/settings_cubit.dart';
import '../../../../core/bloc/settings/settings_state.dart';
import '../../../../core/utils/app_sizes.dart';

class SelectDisplayScreen extends StatelessWidget {
  const SelectDisplayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          final bool isSelectionMade = state.themeMode != ThemeMode.system;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Image(
                    image: AssetImage("assets/images/LogoSelectionScreen.png"),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: -0.2, end: 0),
                  Text(
                    "select_display_title".tr(),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSizes.space8),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.p24),
                    child: Text(
                      "select_display_subtitle".tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.hintColor,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.space32),

                  _buildThemeOption(
                    context: context,
                    state: state,
                    mode: ThemeMode.light,
                    title: "light_mode_title".tr(),
                    description: "light_mode_desc".tr(),
                    imagePath: "assets/images/Light.png",
                  ).animate().slideX(begin: -1,
                      end: 0,
                      duration: 500.ms,
                      curve: Curves.easeOut),

                  const SizedBox(height: AppSizes.space16),

                  _buildThemeOption(
                    context: context,
                    state: state,
                    mode: ThemeMode.dark,
                    title: "dark_mode_title".tr(),
                    description: "dark_mode_desc".tr(),
                    imagePath: "assets/images/Dark.png",
                  ).animate().slideX(begin: 1,
                      end: 0,
                      duration: 500.ms,
                      curve: Curves.easeOut),

                  const SizedBox(height: AppSizes.space24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lightbulb, size: 15, color: Colors.yellow
                          .shade700),
                      const SizedBox(width: AppSizes.space8),
                      Expanded(
                        child: Text(
                          "theme_change_tip".tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12, color: theme.hintColor),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 800.ms),

                  const SizedBox(height: AppSizes.space24),

                  ElevatedButton(
                    onPressed: isSelectionMade
                        ? () =>
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            // [تعديل الاسم] استخدام اسم الكلاس الجديد
                            builder: (context) => const SelectLanguageScreen(),
                          ),
                        )
                        : null,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      minimumSize: const Size(double.infinity, AppSizes
                          .buttonHeight),
                      backgroundColor: theme.primaryColor,
                      disabledBackgroundColor: theme.cardColor.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radius16),
                      ),
                    ),
                    child: Text(
                      "continue".tr(),
                      style: TextStyle(
                        color: isSelectionMade ? Colors.white : theme.hintColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ).animate(target: isSelectionMade ? 1 : 0).scale(
                      duration: 200.ms),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required SettingsState state,
    required ThemeMode mode,
    required String title,
    required String description,
    required String imagePath,
  }) {
    final theme = Theme.of(context);
    final bool isSelected = state.themeMode == mode;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p4),
      child: AnimatedContainer(
        duration: 300.ms,
        curve: Curves.easeInOut,
        height: 140,
        decoration: BoxDecoration(
          color: isSelected ? theme.cardColor : theme.cardColor.withValues(alpha: 
              0.8),
          borderRadius: BorderRadius.circular(AppSizes.radius24),
          border: Border.all(
            color: isSelected ? theme.primaryColor : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(color: theme.primaryColor.withValues(alpha: 0.15),
                blurRadius: 15,
                offset: const Offset(0, 8))
          ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.read<SettingsCubit>().changeTheme(mode),
            borderRadius: BorderRadius.circular(AppSizes.radius24),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSizes.p12),
                  child: Image(image: AssetImage(imagePath), height: 100)
                      .animate(target: isSelected ? 1 : 0)
                      .scale(
                      begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? theme.primaryColor : null,
                        ),
                      ),
                      const SizedBox(height: AppSizes.space8),
                      Text(description, style: TextStyle(
                          color: theme.hintColor, fontSize: 12)),
                    ],
                  ),
                ),
                if (isSelected)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.p16),
                    child: Icon(
                        Icons.check_circle, color: theme.primaryColor, size: 28)
                        .animate()
                        .scale(duration: 200.ms),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}