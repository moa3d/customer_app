import 'dart:async';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nomnow_app/core/services/auth_service.dart';
import 'package:nomnow_app/core/theme/app_theme.dart';
import 'package:nomnow_app/core/utils/app_sizes.dart';

/// v4.3 — إعادة تعيين كلمة المرور برمز OTP عبر SMS.
///
/// خطوتان على شاشة واحدة: إدخال رقم الهاتف (`POST /forgot-password`)، ثم
/// إدخال الرمز وكلمة المرور الجديدة (`POST /reset-password`). لا يوجد خيار
/// بريد إلكتروني في هذه الميزة — موديل المستخدم في الباك لا يحوي إيميل أصلاً.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  // نفس صيغتَي الهاتف المقبولتين في الباك عند التسجيل — والمطابقة هناك حرفية
  // (`User.findOne({ phone })`)، فأي رقم بصيغة محلية مثل `09...` يُرجع 404.
  static final _syPhone = RegExp(r'^\+963[9][0-9]{8}$');
  static final _dePhone = RegExp(r'^\+49[1-9][0-9]{9,13}$');

  /// مهلة إعادة الإرسال في الباك (throttle) — 60 ثانية من آخر طلب ناجح
  static const _resendCooldown = 60;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  String? _errorText;
  String? _serverMessage;
  bool _isLoading = false;
  bool _codeSent = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  /// الرقم بصيغته المطبَّعة كما أُرسل للباك — يُعاد إرساله حرفياً في الخطوة
  /// الثانية، فلا ينكسر الفلو لو عدّل المستخدم نص الحقل بعد إرسال الرمز.
  String? _submittedPhone;

  int _secondsLeft = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  /// تنظيف وتطبيع الرقم: حذف الفراغات والرموز، وتحويل `00` إلى `+`
  String? _normalizePhone(String raw) {
    var p = raw.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    if (p.startsWith('00')) p = '+${p.substring(2)}';
    if (!p.startsWith('+')) return null;
    if (_syPhone.hasMatch(p) || _dePhone.hasMatch(p)) return p;
    return null;
  }

  void _startCooldown([int seconds = _resendCooldown]) {
    _timer?.cancel();
    setState(() => _secondsLeft = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  /// رسالة الخطأ من الباك مترجَمة أصلاً حسب لغة الطلب (`getMessages`)،
  /// والمفتاح المحلي سقوط آمن عند انقطاع الاتصال أو رد بلا نص.
  String _serverError(DioException e, String fallbackKey) {
    final data = e.response?.data;
    final message = data is Map ? data['message']?.toString() : null;
    if (message != null && message.trim().isNotEmpty) return message;
    return fallbackKey.tr();
  }

  Future<void> _sendCode() async {
    final phone = _normalizePhone(_phoneController.text);
    if (phone == null) {
      setState(() => _errorText = "enter_valid_phone_error".tr());
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final response = await AuthService().forgotPassword(phone);
      if (!mounted) return;
      final data = response.data;
      setState(() {
        _isLoading = false;
        _submittedPhone = phone;
        _codeSent = true;
        // مرحلة اختبار: الباك يُرجع الرمز ضمن نص الرسالة مؤقتاً فنعرضه كما هو.
        // عند حذفه من الباك تبقى الرسالة "OTP sent successfully" ولا يتغيّر
        // شيء هنا — الإدخال يدوي في الحالتين.
        _serverMessage = data is Map ? data['message']?.toString() : null;
      });
      _startCooldown();
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = _serverError(e, "unexpected_error");
      });
      if (e.response?.statusCode == 429) {
        final data = e.response?.data;
        final retryAfter =
            data is Map ? int.tryParse('${data['retryAfterSeconds']}') : null;
        _startCooldown(retryAfter ?? _resendCooldown);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = "unexpected_error".tr();
      });
    }
  }

  /// إعادة الإرسال من شاشة الرمز — نفس نداء الخطوة الأولى بنفس الرقم،
  /// ويبقى المستخدم مكانه حتى لا يفقد ما كتبه من كلمة مرور.
  Future<void> _resendCode() async {
    if (_secondsLeft > 0 || _isLoading) return;
    _phoneController.text = _submittedPhone ?? _phoneController.text;
    _otpController.clear();
    await _sendCode();
  }

  Future<void> _resetPassword() async {
    final phone = _submittedPhone;
    final otp = _otpController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (phone == null) {
      setState(() {
        _codeSent = false;
        _errorText = "enter_valid_phone_error".tr();
      });
      return;
    }
    if (otp.isEmpty) {
      setState(() => _errorText = "enter_reset_code_error".tr());
      return;
    }
    if (password.length < 6) {
      setState(() => _errorText = "password_min_6_error".tr());
      return;
    }
    if (password != confirm) {
      setState(() => _errorText = "passwords_mismatch_error".tr());
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await AuthService().resetPassword(
        phone: phone,
        otp: otp,
        newPassword: password,
        confirmPassword: confirm,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("password_reset_success".tr()),
          backgroundColor: Colors.green,
        ),
      );
      // العودة لشاشة تسجيل الدخول التي فُتحت منها هذه الشاشة: الجلسات القديمة
      // لا تُلغى في هذا الإصدار (JWT عديم الحالة)، فلا خروج قسري هنا.
      Navigator.of(context).pop();
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = _serverError(e, "unexpected_error");
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = "unexpected_error".tr();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "reset_password_title".tr(),
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back, size: 20),
            ),
          ),
        ),
      ),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark ? AppTheme.myBackgroundGradient : null,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.p24),
          child: _codeSent ? _buildResetForm(theme) : _buildRequestForm(theme),
        ),
      ),
    );
  }

  Widget _buildRequestForm(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(AppSizes.p24),
          decoration: const BoxDecoration(
            color: AppTheme.myOrange,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lock_outline, size: 50, color: Colors.white),
        ),
        const SizedBox(height: 24),
        Text(
          "forgot_password".tr(),
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          "reset_password_subtitle".tr(),
          textAlign: TextAlign.center,
          style: TextStyle(color: theme.hintColor, fontSize: 14),
        ),
        const SizedBox(height: 32),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "phone_label".tr(),
              style: TextStyle(color: theme.hintColor, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                hintText: "phone_number_hint".tr(),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (_errorText != null) _buildErrorBanner(),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _sendCode,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.myOrange,
            minimumSize: const Size(double.infinity, 55),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text("send_code_button".tr(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildResetForm(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.all(AppSizes.p24),
          decoration: const BoxDecoration(
            color: AppTheme.myOrange,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lock_reset, size: 50, color: Colors.white),
        ),
        const SizedBox(height: 24),
        Text(
          "enter_code_and_new_password".tr(),
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "verification_sent_to".tr(args: [_submittedPhone ?? ""]),
          textAlign: TextAlign.center,
          style: TextStyle(color: theme.hintColor, fontSize: 14),
        ),
        if (_serverMessage != null) ...[
          const SizedBox(height: 16),
          _buildInfoBanner(_serverMessage!),
        ],
        const SizedBox(height: 32),
        _buildOtpField(theme),
        const SizedBox(height: 16),
        _buildPasswordField(theme),
        const SizedBox(height: 16),
        _buildConfirmField(theme),
        const SizedBox(height: 8),
        _buildResendRow(theme),
        if (_errorText != null) ...[
          const SizedBox(height: 8),
          _buildErrorBanner(),
        ],
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _resetPassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.myOrange,
            minimumSize: const Size(double.infinity, 55),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text("reset_password_button".tr(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildResendRow(ThemeData theme) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: TextButton(
        onPressed: (_secondsLeft > 0 || _isLoading) ? null : _resendCode,
        child: Text(
          _secondsLeft > 0
              ? "resend_code_in".tr(args: ["$_secondsLeft"])
              : "resend_code".tr(),
          style: TextStyle(
            color: _secondsLeft > 0 ? theme.hintColor : AppTheme.myOrange,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildOtpField(ThemeData theme) {
    return TextField(
      controller: _otpController,
      keyboardType: TextInputType.number,
      textDirection: TextDirection.ltr,
      maxLength: 6,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        counterText: "",
        hintText: "reset_code_hint".tr(),
        prefixIcon:
            const Icon(Icons.vpn_key, color: AppTheme.myOrange, size: 20),
        filled: true,
        fillColor: theme.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildPasswordField(ThemeData theme) {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        hintText: "new_password_hint".tr(),
        prefixIcon:
            const Icon(Icons.lock_outline, color: AppTheme.myOrange, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: theme.hintColor,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        filled: true,
        fillColor: theme.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildConfirmField(ThemeData theme) {
    return TextField(
      controller: _confirmController,
      obscureText: _obscureConfirm,
      decoration: InputDecoration(
        hintText: "confirm_password_hint".tr(),
        prefixIcon:
            const Icon(Icons.lock_outline, color: AppTheme.myOrange, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirm ? Icons.visibility_off : Icons.visibility,
            color: theme.hintColor,
          ),
          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
        ),
        filled: true,
        fillColor: theme.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildInfoBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.sms_outlined, color: Colors.blue, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: Colors.blue, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_errorText!,
                style: const TextStyle(color: Colors.red, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
