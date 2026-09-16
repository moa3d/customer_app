import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nomnow_app/core/routing/routes.dart';
import 'package:nomnow_app/features/profile/presentation/pages/profile_page.dart';

class ProfileNavigator extends StatelessWidget {
  const ProfileNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    // نستخدم الـ ProfilePage المنظمة التي تملك قائمة الخيارات
    return ProfilePage(
      changePage: (index) {
        if (index == 0) {
          // العودة لتبويب الرئيسية
          StatefulNavigationShell.of(context).goBranch(0);
        } else {
          // التنقل للمسارات الفرعية المنظمة
          _handleNavigation(context, index);
        }
      },
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    final routesMap = {
      1: '${Routes.account}/${Routes.editProfile}',
      2: '${Routes.account}/${Routes.addresses}',
      3: '${Routes.account}/${Routes.notifications}',
      4: '${Routes.account}/${Routes.language}',
      5: '${Routes.account}/${Routes.support}',
      6: '${Routes.account}/${Routes.coupons}',
    };

    if (routesMap.containsKey(index)) {
      context.push(routesMap[index]!); // دفع الصفحة فوق قائمة الحساب
    }
  }
}