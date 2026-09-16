import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nomnow_app/features/location/presentation/pages/set_location_screen.dart';
import '../../../../core/services/token_storage.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/services/notification_permission_service.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/theme/app_theme.dart';

class PhoneVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String? receivedOtp;

  const PhoneVerificationScreen(
      {super.key, required this.phoneNumber, this.receivedOtp});

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
      6, (index) => TextEditingController());
  bool _isButtonEnabled = false;
  bool _isLoading = false;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _checkIfAllFieldsAreFilled() {
    setState(() {
      _isButtonEnabled =
          _controllers.every((controller) => controller.text.length == 1);
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.receivedOtp != null && widget.receivedOtp!.length == 6) {
      for (int i = 0; i < 6; i++) {
        _controllers[i].text = widget.receivedOtp![i];
      }
      _isButtonEnabled = true;
    }
  }

  Future<void> _verifyOtp() async {
    setState(() => _isLoading = true);
    String code = _controllers.map((c) => c.text).join();

    try {
      final response = await AuthService().verifyPhoneOtp(
          widget.phoneNumber, code);
      if (response.statusCode == 200) {
        String token = response.data['token'];
        await TokenStorage().saveToken(token);

        // v3.5 — يُربط الجهاز بهذا الحساب لتصله إشعارات تحديث الطلب
        PushNotificationService().registerToken();

        // صلاحية الإشعارات تُطلب هنا لا على السبلاش: قبل الدخول لا معنى
        // لتوكن غير مرتبط بحساب. ويسبق الانتقال لشاشة الموقع حتى لا يتكدّس
        // حوارها فوق حوار صلاحية الـ GPS الذي تطلبه تلك الشاشة فوراً.
        if (!mounted) return;
        await NotificationPermissionService().maybeAskAfterLogin(context);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SetLocationScreen()),
        );
      }
    } on DioException catch (e) {
      _showErrorSnackBar(
          e.response?.data['message'] ?? "invalid_otp_error".tr());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
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
            gradient: isDarkTheme ? AppTheme.myBackgroundGradient : null),
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                  color: theme.cardColor),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(color: theme
                              .scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(14)),
                          child: Icon(Icons.arrow_forward,
                              color: isDarkTheme ? Colors.white : Colors.black),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  CircleAvatar(backgroundColor: theme.primaryColor,
                      radius: 30,
                      child: const Icon(
                          Icons.local_phone_outlined, color: Colors.white,
                          size: 30)),
                  const SizedBox(height: 20),
                  Text("enter_verification_code".tr(), style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text("verification_sent_to".tr(args: [widget.phoneNumber]),
                      style: TextStyle(color: theme.hintColor, fontSize: 16)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (i) =>
                        SizedBox(
                          width: 45,
                          child: TextFormField(
                            controller: _controllers[i],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(1),
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            onChanged: (v) {
                              if (v.length == 1 && i < 5) {
                                FocusScope
                                    .of(context)
                                    .nextFocus();
                              }
                              if (v.isEmpty && i > 0) {
                                FocusScope
                                    .of(context)
                                    .previousFocus();
                              }
                              _checkIfAllFieldsAreFilled();
                            },
                            decoration: InputDecoration(filled: true,
                                fillColor: theme.scaffoldBackgroundColor,
                                // border: BorderSide.none
                            ),
                          ),
                        )),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        minimumSize: const Size(double.infinity, 45)),
                    onPressed: _isButtonEnabled && !_isLoading
                        ? _verifyOtp
                        : null,
                    child: _isLoading ? const CircularProgressIndicator(
                        color: Colors.white) : Text("verify_button".tr(),
                        style: const TextStyle(color: Colors.white)),
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
