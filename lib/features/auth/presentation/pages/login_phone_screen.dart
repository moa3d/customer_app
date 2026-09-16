import 'package:dio/dio.dart';
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nomnow_app/features/auth/presentation/pages/phone_verification_screen.dart';
import 'package:nomnow_app/features/auth/presentation/pages/register_screen.dart';
import 'package:nomnow_app/features/auth/presentation/pages/reset_password_screen.dart'; // استيراد شاشة الاستعادة
import 'package:nomnow_app/features/location/presentation/pages/set_location_screen.dart';
import '../../../../core/services/token_storage.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/services/notification_permission_service.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_sizes.dart';

class LoginPhoneScreen extends StatefulWidget {
  const LoginPhoneScreen({super.key});

  @override
  State<LoginPhoneScreen> createState() => _LoginPhoneScreenState();
}

class _LoginPhoneScreenState extends State<LoginPhoneScreen> {
  // تعريف متحكمات النصوص لحقل الهاتف وكلمة المرور
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  // متغيرات منطقية للتحكم في حالة الواجهة
  bool _isButtonEnabled = false;
  bool _isLoading = false;
  bool _phoneError = false;
  bool _isPasswordVisible = false;

  // دالة للتحقق من إكمال الحقول لتفعيل زر تسجيل الدخول
  void _validateFields() {
    if (_phoneError && _phoneController.text.isNotEmpty) {
      setState(() => _phoneError = false);
    }
    setState(() {
      _isButtonEnabled =
          _phoneController.text.isNotEmpty &&
              _passwordController.text.isNotEmpty;
    });
  }

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_validateFields);
    _passwordController.addListener(_validateFields);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // معالجة عملية تسجيل الدخول عبر الهاتف والتحقق من الاستجابة
  Future<void> _handleLogin() async {
    if (!_isButtonEnabled || _isLoading) return;

    setState(() {
      _isLoading = true;
      _phoneError = false;
    });

    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    try {
      final response = await AuthService().loginWithPhone(phone, password);

      if (response.statusCode == 200) {
        bool requiresVerification = response.data['requiresVerification'] ??
            false;

        if (requiresVerification) {
          String serverOtp = response.data['otp'].toString();
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PhoneVerificationScreen(
                    phoneNumber: phone,
                    receivedOtp: serverOtp,
                  ),
            ),
          );
        } else {
          String token = response.data['token'];
          await TokenStorage().saveToken(token);

          SocketService().connect(token);

          // v3.5 — يُربط الجهاز بهذا الحساب لتصله إشعارات تحديث الطلب.
          // بلا انتظار: الفشل لا يجب أن يؤخّر دخول المستخدم.
          PushNotificationService().registerToken();

          // صلاحية الإشعارات تُطلب هنا لا على السبلاش: قبل الدخول لا معنى
          // لتوكن غير مرتبط بحساب. ويسبق الانتقال لشاشة الموقع حتى لا يتكدّس
          // حوارها فوق حوار صلاحية الـ GPS الذي تطلبه تلك الشاشة فوراً.
          if (!mounted) return;
          await NotificationPermissionService().maybeAskAfterLogin(context);

          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SetLocationScreen()),
          );
        }
      }
    } on DioException catch (e) {
      String errorMsg = e.response?.data['message'] ?? "phone_login_error".tr();
      _showSnackBar(errorMsg);
    } catch (e) {
      _showSnackBar("unexpected_error".tr());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool isDarkTheme = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDarkTheme ? AppTheme.myBackgroundGradient : null,
        ),
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(24)),
                color: theme.cardColor,
              ),
              width: MediaQuery
                  .of(context)
                  .size
                  .width,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (Navigator.canPop(context))
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: theme.scaffoldBackgroundColor,
                              borderRadius: const BorderRadius.all(
                                  Radius.circular(14)),
                            ),
                            child: Icon(
                              Icons.arrow_forward,
                              color: isDarkTheme ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18.0),
                    child: Text(
                      "login_phone".tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDarkTheme ? Colors.white : Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // حقل إدخال رقم الهاتف مع حصر الإدخال بالأرقام فقط
                  SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: TextFormField(
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))
                      ],
                      controller: _phoneController,
                      textDirection: ui.TextDirection.ltr,
                      cursorColor: const Color(0xff717182),
                      decoration: InputDecoration(
                        filled: true,
                        hintText: "phone_number_hint".tr(),
                        hintTextDirection: context.locale.languageCode == 'ar'
                            ? ui.TextDirection.rtl
                            : ui.TextDirection.ltr,
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(borderRadius: BorderRadius
                            .circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // حقل إدخال كلمة السر
                  SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      cursorColor: const Color(0xff717182),
                      decoration: InputDecoration(
                        filled: true,
                        hintText: "password".tr(),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                              _isPasswordVisible ? Icons.visibility : Icons
                                  .visibility_off,
                              size: 20),
                          onPressed: () =>
                              setState(() =>
                              _isPasswordVisible = !_isPasswordVisible),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius
                            .circular(12)),
                      ),
                    ),
                  ),

                  // رابط "نسيت كلمة المرور" المضاف
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () =>
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (
                                context) => const ResetPasswordScreen()),
                          ),
                      child: Text(
                        "forgot_password".tr(),
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  // زر تسجيل الدخول الرئيسي
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      disabledBackgroundColor: theme.primaryColor.withValues(alpha: 
                          0.5),
                      minimumSize: const Size(double.infinity, 50),
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(14))),
                    ),
                    onPressed: _isButtonEnabled && !_isLoading
                        ? _handleLogin
                        : null,
                    child: _isLoading
                        ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                        : Text("login_title".tr(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: AppSizes.space12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "no_account_yet".tr(),
                        style: TextStyle(
                          color: isDarkTheme ? const Color(0xff99A1AF) : Colors
                              .black54,
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.push(context, MaterialPageRoute(
                                builder: (
                                    context) => const RegisterScreen())),
                        child: Text(
                          "create_account_action".tr(),
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
