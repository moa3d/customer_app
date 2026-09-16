import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nomnow_app/features/orders/presentation/pages/order_confirmed_screen.dart';
import 'package:nomnow_app/features/orders/presentation/pages/order_tracking_screen.dart';
import 'package:nomnow_app/features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/intro/presentation/pages/select_display_screen.dart';
import '../../features/intro/presentation/pages/select_language_screen.dart';
import '../../features/intro/presentation/pages/welcome_screen.dart';
import '../../features/restaurant/data/models/meal.dart';
import '../../features/restaurant/data/models/restaurant.dart';
import 'routes.dart';

import 'package:nomnow_app/features/home/data/models/catalog_args.dart';
import 'package:nomnow_app/features/home/presentation/pages/all_meals_page.dart';
import 'package:nomnow_app/features/home/presentation/pages/all_restaurants_page.dart';
import 'package:nomnow_app/features/home/presentation/pages/search_page.dart';
import 'package:nomnow_app/features/home/presentation/pages/home_shell.dart';
import 'package:nomnow_app/features/home/presentation/pages/home_page.dart';
import 'package:nomnow_app/features/cart/presentation/pages/cart_screen.dart';
import 'package:nomnow_app/features/orders/presentation/pages/orders_screen.dart';
import 'package:nomnow_app/features/favorite/presentation/pages/favorite_screen.dart';
import 'package:nomnow_app/features/profile/presentation/pages/profile_navigator.dart';
import 'package:nomnow_app/features/intro/presentation/pages/splash_screen.dart';
import 'package:nomnow_app/features/auth/presentation/pages/banned_account_screen.dart';
import 'package:nomnow_app/features/auth/presentation/pages/login_phone_screen.dart';
import 'package:nomnow_app/features/restaurant/presentation/pages/restaurant_page.dart';
import 'package:nomnow_app/features/meal_selection/presentation/pages/meal_details_page.dart';

import 'package:nomnow_app/features/notifications/presentation/pages/notifications_page.dart';
import 'package:nomnow_app/features/notifications/presentation/pages/notification_settings_page.dart';
import 'package:nomnow_app/features/offers/presentation/pages/offers_screen.dart';
import 'package:nomnow_app/features/location/presentation/pages/add_location_page.dart';
import 'package:nomnow_app/features/coupons/presentation/pages/my_coupons_screen.dart';
import 'package:nomnow_app/features/settings/presentation/pages/language_page.dart';
import 'package:nomnow_app/core/widgets/placeholder_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: Routes.welcome,
          builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: Routes.selectDisplay,
          builder: (context, state) => const SelectDisplayScreen()),
      GoRoute(path: Routes.selectLanguage,
          builder: (context, state) => const SelectLanguageScreen()),
      GoRoute(
        path: Routes.authSelection,
        builder: (context, state) => const LoginPhoneScreen(),
      ),
      GoRoute(
        path: Routes.banned,
        builder: (context, state) => BannedAccountScreen(
          isRejected: state.extra as bool? ?? false,
        ),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeShell(navigationShell: navigationShell);
        },
        branches: [
          // 1. فرع الصفحة الرئيسية
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (context, state) =>
                    HomBody(
                      userAuthToken: '',
                      triggerPageChange: (idx, {data}) =>
                          _handleGlobalNavigation(context, idx, data),
                    ),
                routes: [
                  GoRoute(
                    path: 'restaurant-details',
                    builder: (context, state) {
                      final extra = state.extra;
                      if (extra is! Restaurant) {
                        return Scaffold(
                          appBar: AppBar(title: Text('page_not_found'.tr())),
                          body: const Center(child: Text('Invalid data')),
                        );
                      }
                      return ResturantPage(
                        restaurant: extra,
                        token: '',
                        movePage: (idx, {data}) =>
                            _handleGlobalNavigation(context, idx, data),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'meal-details',
                    builder: (context, state) {
                      final extra = state.extra;
                      if (extra is! Meal) {
                        return Scaffold(
                          appBar: AppBar(title: Text('page_not_found'.tr())),
                          body: const Center(child: Text('Invalid data')),
                        );
                      }
                      return MealDetailsPage(
                        food: extra,
                        movePage: (idx, {data}) {
                          if (idx == 0) {
                            context.pop();
                          } else {
                            _handleGlobalNavigation(context, idx, data);
                          }
                        },
                      );
                    },
                  ),
                  GoRoute(
                    path: 'notifications',
                    builder: (context, state) =>
                        NotificationsPage(movePage: (_) => context.pop()),
                  ),
                  GoRoute(
                    path: 'offers',
                    builder: (context, state) =>
                        OffersScreen(
                          movePage: (idx, {data}) =>
                              _handleGlobalNavigation(context, idx, data),
                        ),
                  ),
                  GoRoute(
                    path: 'all-restaurants',
                    builder: (context, state) {
                      final extra = state.extra;
                      if (extra is! CatalogArgs<Restaurant>) {
                        return Scaffold(
                          appBar: AppBar(title: Text('page_not_found'.tr())),
                          body: const Center(child: Text('Invalid data')),
                        );
                      }
                      return AllRestaurantsPage(args: extra);
                    },
                  ),
                  GoRoute(
                    path: 'all-meals',
                    builder: (context, state) {
                      final extra = state.extra;
                      if (extra is! CatalogArgs<Meal>) {
                        return Scaffold(
                          appBar: AppBar(title: Text('page_not_found'.tr())),
                          body: const Center(child: Text('Invalid data')),
                        );
                      }
                      return AllMealsPage(args: extra);
                    },
                  ),
                  GoRoute(
                    path: 'search',
                    builder: (context, state) => const SearchPage(),
                  ),
                ],
              ),
            ],
          ),

          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.cart,
                builder: (context, state) =>
                    CartScreen(
                      isSelectLocation: false,
                      onBackToHome: (idx) =>
                          _handleGlobalNavigation(context, idx, null),
                    ),
              ),
            ],
          ),

          // 3. فرع الطلبات
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.orders,
                builder: (context, state) => const OrdersScreen(isFull: false),
              ),
            ],
          ),

          // 4. فرع المفضلة
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.favorites,
                builder: (context, state) =>
                    FavoritesScreen(
                      token: '',
                      movePage: (idx, {data}) =>
                          _handleGlobalNavigation(context, idx, data),
                    ),
              ),
            ],
          ),

          // 5. فرع الحساب الشخصي
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.account,
                builder: (context, state) => const ProfileNavigator(),
                routes: [
                  GoRoute(
                    path: Routes.editProfile,
                    builder: (context, state) => const EditProfilePage(),
                  ),
                  GoRoute(
                    path: Routes.addresses,
                    builder: (context, state) => const AddLocationPage(),
                  ),
                  GoRoute(
                    path: Routes.notifications,
                    builder: (context, state) =>
                        const NotificationSettingsPage(),
                  ),
                  GoRoute(
                    path: Routes.language,
                    builder: (context, state) => const LanguegeScreen(),
                  ),
                  GoRoute(
                    path: Routes.support,
                    builder: (context, state) => const PlaceholderPage(
                      title: 'support_title',
                    ),
                  ),
                  GoRoute(
                    path: Routes.coupons,
                    builder: (context, state) => const MyCouponsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.orderConfirmed,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          if (data == null) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => context.go('/home'),
                  child: Text('back_to_home'.tr()),
                ),
              ),
            );
          }
          return OrderConfirmedScreen(lastOrder: data);
        },
      ),
      GoRoute(
        path: Routes.orderTracking,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          if (data == null) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => context.go('/home'),
                  child: Text('back_to_home'.tr()),
                ),
              ),
            );
          }
          return OrderTrackingScreen(orderData: data);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: Text('page_not_found'.tr()),
      ),
      body: Center(
        child: Text('page_not_found_message'.tr()),
      ),
    ),
  );

  static void _handleGlobalNavigation(BuildContext context, int index,
      dynamic data) {
    if (index >= 0 && index <= 4) {
      // تبديل التبويب السفلي مباشرة
      StatefulNavigationShell.of(context).goBranch(index);
    } else {
      switch (index) {
        case 5: // العروض
          context.push('/home/offers');
          break;
        case 6: // الإشعارات
          context.push('/home/notifications');
          break;
        case 7: // تفاصيل المطعم
          context.push('/home/restaurant-details', extra: data);
          break;
        case 8: // تفاصيل الوجبة
          context.push('/home/meal-details', extra: data);
          break;
        case 9: // شاشة العناوين (تحديد الموقع)
          context.push('/account/addresses');
          break;
      }
    }
  }
}