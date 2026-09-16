import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nomnow_app/core/routing/routes.dart';

import '../../../../core/bloc/settings/settings_cubit.dart';
import '../../../../core/bloc/settings/settings_state.dart';
import '../../../../core/utils/app_sizes.dart';

class SelectLanguageScreen extends StatelessWidget {
  const SelectLanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: AppSizes.space50),
                  const Image(
                    image: AssetImage("assets/images/logosplash.png"),
                    width: 350,
                    height: 220,
                  ).animate().fadeIn(duration: 600.ms).scale(delay: 200.ms),
                  Text(
                    "select_language".tr(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSizes.p8),
                    child: Text(
                      "choose_preferred".tr(),
                      style: TextStyle(color: theme.hintColor, fontSize: 14),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSizes.p8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: const BorderRadius.all(Radius.circular(
                            AppSizes.radius24)),
                      ),
                      width: MediaQuery
                          .of(context)
                          .size
                          .width,
                      child: Column(
                        children: [
                          const SizedBox(height: AppSizes.p8),
                          LanguageOption(
                            locale: const Locale('ar'),
                            path: "assets/images/arabic.png",
                            text: "arabic",
                            isSelected: context.locale == const Locale('ar'),
                          ),
                          LanguageOption(
                            locale: const Locale('en'),
                            path: "assets/images/english.png",
                            text: "english",
                            isSelected: context.locale == const Locale('en'),
                          ),
                          LanguageOption(
                            locale: const Locale('de'),
                            path: "assets/images/germany.png",
                            text: "german",
                            isSelected: context.locale == const Locale('de'),
                          ),
                          const SizedBox(height: AppSizes.p8),
                        ],
                      ).animate().slideY(begin: 0.2, end: 0, duration: 500.ms),
                    ),
                  ),
                  const SizedBox(height: AppSizes.space20),
                  Padding(
                    padding: const EdgeInsets.all(AppSizes.p12),
                    child: ElevatedButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('is_first_time', false);
                        if (context.mounted) {
                          context.go(Routes.authSelection);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: theme.primaryColor,
                        minimumSize: const Size(
                            double.infinity, AppSizes.buttonHeight),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(
                              Radius.circular(AppSizes.radius16)),
                        ),
                      ),
                      child: Text(
                        "continue".tr(),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16),
                      ),
                    ).animate().fadeIn(delay: 400.ms),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class LanguageOption extends StatefulWidget {
  final Locale locale;
  final String path;
  final String text;
  final bool isSelected;

  const LanguageOption({
    super.key,
    required this.locale,
    required this.path,
    required this.text,
    required this.isSelected,
  });

  @override
  State<LanguageOption> createState() => _LanguageOptionState();
}

class _LanguageOptionState extends State<LanguageOption> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color selectedColor = theme.primaryColor.withValues(alpha: 0.1);
    final Color hoverColor = theme.primaryColor.withValues(alpha: 0.05);
    final Color idleColor = theme.scaffoldBackgroundColor;

    return InkWell(
      onTap: () async {
        final cubit = context.read<SettingsCubit>();
        await context.setLocale(widget.locale);
        if (mounted) {
          cubit.changeLanguage(widget.locale);
        }
      },
      onHover: (hovering) => setState(() => _isHovered = hovering),
      borderRadius: BorderRadius.circular(AppSizes.radius16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.linear,
        margin: const EdgeInsets.symmetric(
            vertical: AppSizes.p8, horizontal: AppSizes.p16),
        height: AppSizes.languageSelectItemHeight,
        decoration: BoxDecoration(
          color: widget.isSelected ? selectedColor : (_isHovered
              ? hoverColor
              : idleColor),
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          border: Border.all(
            color: widget.isSelected ? theme.primaryColor : theme.primaryColor
                .withValues(alpha: 0),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
        child: Row(
          children: [
            if (widget.isSelected)
              Icon(Icons.check_circle, color: theme.primaryColor)
                  .animate()
                  .scale(duration: 200.ms),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.text.tr(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: widget.isSelected ? FontWeight.bold : FontWeight
                        .normal,
                  ),
                ),
                Text(widget.text,
                    style: TextStyle(color: theme.hintColor, fontSize: 12)),
              ],
            ),
            AppSizes.w12,
            AnimatedScale(
              scale: _isHovered ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Image.asset(widget.path, height: 35, width: 45),
            ),
          ],
        ),
      ),
    );
  }
}