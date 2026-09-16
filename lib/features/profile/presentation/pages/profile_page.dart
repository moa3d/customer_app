import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart'; //
import '../../../../core/services/auth_service.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';

import 'package:nomnow_app/core/routing/routes.dart';
import '../../../../core/bloc/settings/settings_cubit.dart';
import '../../../../core/bloc/settings/settings_state.dart';

class ProfilePage extends StatefulWidget {
  final Function(int) changePage;

  const ProfilePage({super.key, required this.changePage});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRtl = Directionality.of(context) == ui.TextDirection.rtl;

    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        String userName = "loading...".tr();
        String userPhone = "...";
        String? userImageUrl;
        String memberSince = "";

        if (state is ProfileLoaded) {
          userName = state.user.name;
          userPhone = state.user.phone;
          userImageUrl = state.user.imgUrl;

          if (state.user.createdAt != null) {
            try {
              DateTime date = DateTime.parse(state.user.createdAt!);
              String formattedDate = DateFormat(
                  'MMMM yyyy', context.locale.languageCode).format(date);
              memberSince = "${"member_since_label".tr()} $formattedDate";
            } catch (e) {
              memberSince = "member_since_label".tr();
            }
          }
        }

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.cardColor,
            actions: [
              Row(
                children: [
                  Text(
                    "profile_title".tr(),
                    style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => widget.changePage(0),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: const BorderRadius.all(Radius.circular(
                            12)),
                      ),
                      child: const Icon(Icons.arrow_forward),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ],
            automaticallyImplyLeading: false,
            bottom: PreferredSize(
              preferredSize: Size(MediaQuery
                  .of(context)
                  .size
                  .width, 100),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildProfileCard(
                    theme, userName, userPhone, userImageUrl, () =>
                    widget.changePage(1)),
              ),
            ),
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20))),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      _buildMenuItem(theme, isRtl, icon: Icons.person_outline,
                          titleKey: "personal_information_title",
                          subtitleKey: "personal_information_subtitle",
                          onPressed: () => widget.changePage(1)),
                      _buildMenuItem(
                          theme, isRtl, icon: Icons.location_on_outlined,
                          titleKey: "addresses_title",
                          subtitleKey: "addresses_subtitle",
                          onPressed: () => widget.changePage(2)),
                      _buildMenuItem(
                          theme, isRtl, icon: Icons.notifications_none,
                          titleKey: "notifications_title",
                          subtitleKey: "notifications_subtitle",
                           onPressed: () => widget.changePage(3)),
                      _buildMenuItem(theme, isRtl, icon: Icons.language,
                          titleKey: "language_title",
                          subtitle: context.locale.languageCode.toUpperCase(),
                          onPressed: () => widget.changePage(4)),
                      if (state is ProfileLoaded
                          ? state.user.country != 'DE'
                          : true)
                        _buildMenuItem(
                            theme, isRtl,
                            icon: Icons.confirmation_number_outlined,
                            titleKey: "my_coupons_title",
                            subtitleKey: "my_coupons_subtitle",
                            onPressed: () => widget.changePage(6)),
                      _buildThemeMenuItem(theme, isRtl),
                      _buildMenuItem(
                          theme, isRtl, icon: Icons.headset_mic_outlined,
                          titleKey: "support_title",
                          subtitleKey: "support_subtitle",
                          onPressed: () => widget.changePage(5)),
                      const SizedBox(height: 10),
                      _buildLogoutButton(theme),
                      const SizedBox(height: 30),
                      if (memberSince.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(memberSince, style: theme.textTheme
                              .bodyMedium?.copyWith(
                              fontSize: 13, color: theme.hintColor)),
                        ),
                      Text("NOMNOW v1.0.0",
                          style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 12)),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileCard(ThemeData theme, String name, String phone,
      String? imageUrl, Function() onPressed) {
    return Material(
      color: theme.scaffoldBackgroundColor,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  color: theme.primaryColor,
                  image: imageUrl != null ? DecorationImage(
                      image: CachedNetworkImageProvider(imageUrl), fit: BoxFit.cover) : null,
                ),
                child: imageUrl == null ? Icon(
                    Icons.person, color: Colors.white.withValues(alpha: 0.8),
                    size: 35) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text(phone, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Text("edit_profile_button".tr(), style: TextStyle(
                  color: theme.primaryColor, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(ThemeData theme, bool isRtl,
      {required IconData icon, required String titleKey, String? subtitleKey, String? subtitle, required Function() onPressed}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titleKey.tr(),
                          style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      if (subtitle != null || subtitleKey != null)
                        Text(subtitle ?? subtitleKey!.tr(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 11)),
                    ],
                  ),
                ),
                Icon(isRtl ? Icons.arrow_back_ios_new : Icons.arrow_forward_ios,
                    size: 16, color: theme.hintColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeMenuItem(ThemeData theme, bool isRtl) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settings) {
        final currentMode = settings.themeMode;
        final String modeLabel;
        final IconData modeIcon;
        switch (currentMode) {
          case ThemeMode.dark:
            modeLabel = 'dark_mode'.tr();
            modeIcon = Icons.dark_mode_outlined;
            break;
          case ThemeMode.light:
            modeLabel = 'light_mode'.tr();
            modeIcon = Icons.light_mode_outlined;
            break;
          default:
            modeLabel = 'system_mode'.tr();
            modeIcon = Icons.brightness_auto_outlined;
        }
        return _buildMenuItem(
          theme, isRtl,
          icon: modeIcon,
          titleKey: "theme_title",
          subtitle: modeLabel,
          onPressed: () => _showThemePicker(context),
        );
      },
    );
  }

  void _showThemePicker(BuildContext context) {
    final theme = Theme.of(context);
    final currentMode = context.read<SettingsCubit>().state.themeMode;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('theme_title'.tr(),
                style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildThemeOption(ctx, 'light_mode'.tr(),
                Icons.light_mode_outlined, ThemeMode.light, currentMode),
            _buildThemeOption(ctx, 'dark_mode'.tr(),
                Icons.dark_mode_outlined, ThemeMode.dark, currentMode),
            _buildThemeOption(ctx, 'system_mode'.tr(),
                Icons.brightness_auto_outlined, ThemeMode.system, currentMode),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(BuildContext ctx, String label, IconData icon,
      ThemeMode mode, ThemeMode currentMode) {
    final theme = Theme.of(ctx);
    final isSelected = currentMode == mode;
    return ListTile(
      leading: Icon(icon, color: isSelected ? theme.primaryColor : theme.hintColor),
      title: Text(label, style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? theme.primaryColor : null)),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: theme.primaryColor)
          : null,
      onTap: () {
        ctx.read<SettingsCubit>().changeTheme(mode);
        Navigator.pop(ctx);
      },
    );
  }

  Widget _buildLogoutButton(ThemeData theme) {
    return OutlinedButton(
      onPressed: () async {

        bool? confirm = await showModalBottomSheet<bool>(
          context: context,
          useRootNavigator: true,
          backgroundColor: theme.cardColor,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          builder: (context) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("logout_confirmation_title".tr(),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15))),
                          child: Text("yes_button".tr(), style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15))),
                          child: Text("cancel_button".tr(),
                              style: const TextStyle(color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );

        if (confirm == true) {
          // التنظيف كاملاً (السوكيت، سجلّ الإشعارات، الكاش) داخل logout نفسها
          await AuthService().logout();
          if (mounted) {
            // ✅ استخدام context.go لكسر الـ Shell تماماً والعودة لشاشة الدخول بدون بار سفلي
            context.go(Routes.authSelection);
          }
        }
      },
      style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 55),
          foregroundColor: Colors.red,
          side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.logout),
          const SizedBox(width: 10),
          Text("logout_button".tr(), style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
