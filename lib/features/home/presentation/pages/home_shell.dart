import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../cart/presentation/bloc/mail_bloc.dart';
import '../../../cart/presentation/bloc/mail_event.dart';
import '../widgets/custom_bottom_nav_bar.dart';

class HomeShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const HomeShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (navigationShell.currentIndex != 0) {
          navigationShell.goBranch(0);
        } else {
          _showExitDialog(context);
        }
      },
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: navigationShell.currentIndex,
          onTap: (index) {
            // إعادة جلب الطلبات عند فتح تبويب "طلباتي" (index 2)
            // حتى يظهر أي طلب جديد دون الحاجة لإعادة تشغيل التطبيق
            if (index == 2) {
              context.read<MailBloc>().add(FetchUserOrdersEvent());
            }
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
        ),
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('exit_title'.tr()),
        content: Text('exit_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('exit_no'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              exit(0);
            },
            child: Text('exit_yes'.tr()),
          ),
        ],
      ),
    );
  }
}