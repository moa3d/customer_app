import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/widgets/arrowforward.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _picker = ImagePicker();
  File? _imageFile;
  String _gender = 'male';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _pickImage() async {
    if (_isLoading) return;
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    final cubit = context.read<ProfileCubit>();
    cubit.updateProfile(
      name: _nameController.text.trim(),
      gender: _gender,
      imageFile: _imageFile,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocConsumer<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state is ProfileUpdateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() => _isLoading = false);
          context.pop();
        } else if (state is ProfileError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() => _isLoading = false);
        }
        if (state is ProfileLoading) {
          setState(() => _isLoading = true);
        }
      },
      builder: (context, state) {
        if (state is ProfileLoaded && _nameController.text.isEmpty) {
          final user = state.user;
          _nameController.text = user.name;
          _gender = user.gender.isNotEmpty ? user.gender : 'male';
        }

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.cardColor,
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                ActionButton(onPressed: () => context.pop()),
                const SizedBox(width: 10),
                Text("personal_information_title".tr()),
              ],
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildProfileImage(theme, state),
                  const SizedBox(height: 32),
                  _buildNameField(theme, isDark),
                  const SizedBox(height: 20),
                  _buildGenderField(theme, isDark),
                  const SizedBox(height: 40),
                  _buildSaveButton(theme),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileImage(ThemeData theme, ProfileState state) {
    final currentUrl = state is ProfileLoaded ? state.user.imgUrl : null;
    final bool hasNewImage = _imageFile != null;

    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
            backgroundImage: hasNewImage
                ? FileImage(_imageFile!)
                : (currentUrl != null && currentUrl.isNotEmpty
                    ? CachedNetworkImageProvider(currentUrl) as ImageProvider
                    : null),
            child: (!hasNewImage && (currentUrl == null || currentUrl.isEmpty))
                ? Icon(Icons.person, size: 50, color: theme.primaryColor)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField(ThemeData theme, bool isDark) {
    return TextFormField(
      controller: _nameController,
      enabled: !_isLoading,
      decoration: InputDecoration(
        labelText: "full_name_label".tr(),
        prefixIcon: const Icon(Icons.person_outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'field_required_error'.tr();
        }
        return null;
      },
    );
  }

  Widget _buildGenderField(ThemeData theme, bool isDark) {
    return AbsorbPointer(
      absorbing: _isLoading,
      child: DropdownButtonFormField<String>(
        initialValue: _gender,
        decoration: InputDecoration(
          labelText: "gender_label".tr(),
          prefixIcon: const Icon(Icons.wc),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          filled: true,
          fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05),
        ),
        items: const [
          DropdownMenuItem(value: 'male', child: Text('ذكر')),
          DropdownMenuItem(value: 'female', child: Text('أنثى')),
        ],
        onChanged: (value) {
          if (value != null) setState(() => _gender = value);
        },
      ),
    );
  }

  Widget _buildSaveButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(
                "save_changes_button".tr(),
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
