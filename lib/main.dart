import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:nomnow_app/features/cart/presentation/bloc/mail_bloc.dart';
import 'package:nomnow_app/core/routing/app_router.dart'; // ✅ استيراد الراوتر الجديد
import 'core/bloc/settings/settings_cubit.dart';
import 'core/bloc/settings/settings_state.dart';
import 'core/config/payment_config.dart';
import 'core/services/auth_service.dart';
import 'core/services/app_lifecycle_observer.dart';
import 'core/services/notification_background_handler.dart';
import 'core/services/order_notifications_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/socket_service.dart';
import 'core/services/token_storage.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_bloc.dart';
import 'features/cart/data/repositories/cart_repository.dart';
import 'features/favorite/cubit/favorite_cubit.dart';
import 'features/home/presentation/cubit/home_catalog_cubit.dart';
import 'features/location/presentation/bloc/location_bloc.dart';
import 'features/orders/bloc/order_tracker_cubit.dart';
import 'features/orders/data/repositories/order_repository.dart';
import 'features/profile/presentation/cubit/profile_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // تهيئة Stripe (يُستخدم فقط عند إتمام طلبات مطاعم ألمانيا — DE)
  Stripe.publishableKey = PaymentConfig.stripePublishableKey;
  await Stripe.instance.applySettings();

  // // ✅ تفعيل دعم الحواف الممتدة (Edge-to-Edge) لنظام أندرويد الحديث — ملغي لتفادي تداخل أزرار النظام مع التطبيق
  // SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // تسخين التخزين الآمن + ترحيل أي توكن قديم من SharedPreferences
  await TokenStorage().init();

  final authService = AuthService();
  final cartRepository = CartRepository();
  final orderRepository = OrderRepository();

  final String? savedToken = await authService.getToken();

  if (savedToken != null && savedToken.isNotEmpty) {
    debugPrint("[MAIN]: Token found, initializing Socket connection...");
    SocketService().connect(savedToken);
  }

  // سجلّ الإشعارات: يبني نفسه من أحداث السوكيت ويُحفظ على الجهاز.
  // حلّ محل البيانات التجريبية الثابتة في شاشة الإشعارات.
  await OrderNotificationsService().init();

  // معالج إشعارات الخلفية: يجب أن يُسجَّل قبل runApp وفي أعلى مستوى، لأن
  // FCM يستدعيه في عزلة جديدة لا تمرّ بـ runApp إطلاقاً. بلا هذا التسجيل لا
  // يُسجَّل الإشعار الواصل والتطبيق مغلق في سجلّ الإشعارات داخل التطبيق.
  FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

  // v3.5 — إشعارات Push: تُهيَّأ بعد رسم أول إطار لا قبله.
  // السبب نفسه الموثّق في تطبيق السائق: على أجهزة بلا Google Services كاملة
  // قد يعلّق getToken() للأبد، فلو انتظرناه قبل runApp لظهرت شاشة سوداء.
  // الدالة نفسها لا ترمي أبداً، والتطبيق يعمل بالسوكيت وحده إن تعذّرت.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    PushNotificationService().init();
  });

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en'), Locale('de')],
      path: "assets/translations",
      fallbackLocale: const Locale('ar'),
      child: NomNow(
        authService: authService,
        cartRepository: cartRepository,
        orderRepository: orderRepository,
      ),
    ),
  );
}

class NomNow extends StatelessWidget {
  final AuthService authService;
  final CartRepository cartRepository;
  final OrderRepository orderRepository;

  const NomNow({
    super.key,
    required this.authService,
    required this.cartRepository,
    required this.orderRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => FavoriteCubit()),
        BlocProvider(create: (context) => OrderTrackerCubit()),
        BlocProvider(
          create: (context) =>
              MailBloc(
                cartRepository: cartRepository,
                orderRepository: orderRepository,
              ),
        ),
        BlocProvider(create: (context) => ThemeBloc()),
        BlocProvider(create: (context) => SettingsCubit()),
        BlocProvider<LocationBloc>(
          create: (context) => LocationBloc(authService),
        ),
        BlocProvider(
          create: (context) =>
          ProfileCubit(authService)
            ..fetchProfile(),
        ),
        // كتالوج الرئيسية — الترتيب والأقسام والبحث. عام لا محلي بالشاشة حتى
        // تحتفظ الرئيسية بحالتها عند التنقّل بين تبويبات الشريط السفلي.
        BlocProvider(create: (context) => HomeCatalogCubit()),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          final isDark = state.themeMode == ThemeMode.dark;

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: isDark ? Brightness.light : Brightness
                  .dark,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarIconBrightness: isDark
                  ? Brightness.light
                  : Brightness.dark,
              systemNavigationBarContrastEnforced: false,
            ),
            child: AppLifecycleGate(
              child: MaterialApp.router(
                routerConfig: AppRouter.router,
                //  ربط إعدادات GoRouter
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: state.themeMode,
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                locale: context.locale,
              ),
            ),
          );
        },
      ),
    );
  }
}
