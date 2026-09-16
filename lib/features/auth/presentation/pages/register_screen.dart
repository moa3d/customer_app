import 'dart:io';
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nomnow_app/features/auth/presentation/widgets/auth_app_bar.dart';
import 'package:nomnow_app/features/auth/presentation/widgets/register_fields.dart';
import 'package:dio/dio.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_sizes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passController = TextEditingController();
  final _pass2Controller = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _passController.dispose();
    _pass2Controller.dispose();
    super.dispose();
  }

  bool _passError = false;
  bool _nameError = false;

  bool isMale = false;
  bool isFemale = false;

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  void _validateAndRegister() async {
    setState(() {
      _passError = false;
      _nameError = false;
    });

    final pass = _passController.text;
    final name = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();

    final nameRegExp = RegExp(r"^[a-zA-Z\s\u0600-\u06FF]+$");
    if (name.isEmpty) {
      setState(() => _nameError = true);
      _showSnackBar("يرجى إدخال الاسم الكامل");
      return;
    }
    if (!nameRegExp.hasMatch(name)) {
      setState(() => _nameError = true);
      _showSnackBar("الاسم يجب أن يحتوي على حروف فقط");
      return;
    }

    bool isSyPhone = RegExp(r"^\+9639[0-9]{8}$").hasMatch(phone);
    bool isDePhone = RegExp(r"^\+49[1-9][0-9]{9,13}$").hasMatch(phone);

    if (phone.isEmpty) {
      _showSnackBar("يرجى إدخال رقم الهاتف");
      return;
    }
    if (!isSyPhone && !isDePhone) {
      _showSnackBar("رقم الهاتف غير صحيح. (مثال سوريا: +9639xxxxxxxx)");
      return;
    }

    bool isPassValid = pass.length >= 8 &&
        RegExp(r'[0-9]').hasMatch(pass) &&
        RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(pass);
    if (!isPassValid) {
      setState(() => _passError = true);
      _showSnackBar(
          "كلمة المرور يجب أن تكون 8 رموز على الأقل وتحتوي أرقام ورموز خاصة");
      return;
    }
    if (pass != _pass2Controller.text) {
      _showSnackBar("كلمات المرور غير متطابقة");
      return;
    }

    if (!isMale && !isFemale) {
      _showSnackBar("يرجى اختيار الجنس");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _authService.register(
          name: name,
          phone: phone,
          password: pass,
          gender: isMale ? "male" : "female",
          imageFile: _imageFile
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        //  إظهار رسالة النجاح
        _showSnackBar("تم إنشاء الحساب بنجاح!", isError: false);

        if (mounted) {
          //  العودة لشاشة تسجيل الدخول (السابقة)
          Navigator.pop(context);
        }
      }
    } on DioException catch (e) {
      String errorMessage = e.response?.data['message'] ??
          "حدث خطأ في الاتصال بالسيرفر";
      _showSnackBar(errorMessage);
    } catch (e) {
      _showSnackBar("حدث خطأ غير متوقع");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDarkTheme = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: authAppBar(context: context),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDarkTheme ? AppTheme.myBackgroundGradient : null,
        ),
        width: double.infinity,
        height: double.infinity,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: Column(
            children: [
              _buildProfileImage().animate().fadeIn(duration: 500.ms).scale(),
              AppSizes.h20,
              _buildField(
                Icons.person,
                "full_name_label",
                "full_name_hint",
                _fullNameController,
                errorState: _nameError,
              ),
              _buildField(
                  Icons.phone,
                  "phone_number_label",
                  "+963...",
                  _phoneController,
                  textDirection: ui.TextDirection.ltr
              ),
              _buildField(
                Icons.lock_outline,
                "password",
                "********",
                _passController,
                errorState: _passError,
                isPassword: true,
              ),
              _buildField(
                Icons.lock_reset,
                "تحقق من كلمة مرور",
                "********",
                _pass2Controller,
                isPassword: true,
              ),
              AppSizes.h12,
              _buildGenderSection(theme).animate().fadeIn(delay: 600.ms),
              AppSizes.h24,
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.myOrange,
                  minimumSize: const Size(
                      double.infinity, AppSizes.buttonHeight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radius12),
                  ),
                ),
                onPressed: _validateAndRegister,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text("create_account_action".tr(),
                    style: const TextStyle(color: Colors.white, fontSize: 16)),
              ).animate().fadeIn(delay: 700.ms).scale(),
              AppSizes.h10,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "already_have_account".tr(),
                    style: TextStyle(
                      color: isDarkTheme ? const Color(0xff99A1AF) : Colors
                          .black54,
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "login_button".tr(),
                      style: const TextStyle(
                        color: AppTheme.myOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 800.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Stack(
      children: [
        CircleAvatar(
          backgroundColor: AppTheme.myOrange.withValues(alpha: 0.1),
          radius: 60,
          backgroundImage: _imageFile != null
              ? FileImage(_imageFile!)
              : const AssetImage("assets/images/person.png") as ImageProvider,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: CircleAvatar(
            backgroundColor: AppTheme.myOrange,
            radius: 18,
            child: IconButton(
              onPressed: _pickImage,
              icon: const Icon(
                  Icons.camera_alt_outlined, size: 18, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildField(IconData icon, String titleKey, String hintKey,
      TextEditingController controller,
      {bool errorState = false, bool isPassword = false, ui
          .TextDirection? textDirection}) {
    final bool isDark = Theme
        .of(context)
        .brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.p12),
      child: Theme(
        data: theme.copyWith(
          inputDecorationTheme: InputDecorationTheme(
            focusedBorder: errorState
                ? OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.red, width: 2),
                borderRadius: BorderRadius.circular(AppSizes.radius12))
                : OutlineInputBorder(borderSide: BorderSide(
                color: isDark ? theme.hintColor : const Color(0xff4A5565),
                width: 1.5),
                borderRadius: BorderRadius.circular(AppSizes.radius12)),
          ),
        ),
        child: RegisterFields(
          icon: icon,
          title: titleKey.tr(),
          hint: hintKey.tr(),
          controller: controller,
          isPassword: isPassword,
          textDirection: textDirection,
        ),
      ),
    );
  }

  Widget _buildGenderSection(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () =>
                setState(() {
                  isMale = true;
                  isFemale = false;
                }),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isMale ? AppTheme.myOrange.withValues(alpha: 0.1) : theme
                    .cardColor,
                border: Border.all(
                    color: isMale ? AppTheme.myOrange : theme.dividerColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text("male".tr(), style: TextStyle(
                  color: isMale ? AppTheme.myOrange : theme.hintColor))),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: () =>
                setState(() {
                  isMale = false;
                  isFemale = true;
                }),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isFemale ? AppTheme.myOrange.withValues(alpha: 0.1) : theme
                    .cardColor,
                border: Border.all(
                    color: isFemale ? AppTheme.myOrange : theme.dividerColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text("female".tr(), style: TextStyle(
                  color: isFemale ? AppTheme.myOrange : theme.hintColor))),
            ),
          ),
        ),
      ],
    );
  }
}
