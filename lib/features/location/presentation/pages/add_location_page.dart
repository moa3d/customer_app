import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nomnow_app/features/location/presentation/widgets/appbar_location_order.dart';

// استيراد إدارة الحالة والموديلات
import '../../../../core/utils/app_sizes.dart';

// استيراد الويدجت المشتركة المستخدمة في الهيكل القديم
import '../bloc/location_bloc.dart';
import '../bloc/location_event.dart';
import '../bloc/location_state.dart';
import '../widgets/step_header.dart';
import '../widgets/styled_textfiled.dart';

// استيراد ويدجت معاينة العنوان الكامل
import '../../data/models/address_model.dart';
import '../widgets/full_address_preview_card.dart';
import 'location_picker_page.dart';

/// الحد الأقصى للعناوين — مطابق لقاعدة الباك في AddAddresses
const int kMaxAddresses = 5;

class AddLocationPage extends StatefulWidget {
  const AddLocationPage({super.key});

  @override
  State<AddLocationPage> createState() => _AddLocationPageState();
}

class _AddLocationPageState extends State<AddLocationPage> {
  // متغيرات التحكم في الحالة (إضافة موقع جديد أم عرض المحفوظ)
  bool _isAddingNewAddress = false;
  // يصل من onMapCreated — لا يتوفّر قبل بناء الخريطة فعلياً
  GoogleMapController? _mapController;
  LatLng _currentCenter = const LatLng(33.5138, 36.2765); // موقع افتراضي (دمشق)
  bool _isReverseGeocoding = false;
  bool _isInitialLoading = false;

  // متحكمات الحقول النصية (مطابقة للهيكل القديم تماماً)
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _buildingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // تحميل العناوين المحفوظة عند فتح الشاشة
    context.read<LocationBloc>().add(LoadAddressesEvent());
  }

  @override
  void dispose() {
    // تنظيف الذاكرة عند إغلاق الشاشة
    _nameController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _streetController.dispose();
    _buildingController.dispose();
    // GoogleMapController تتكفّل به الودجة نفسها عند إزالتها — لا نتخلّص منه
    // يدوياً هنا تفادياً للتخلّص المزدوج.
    super.dispose();
  }

  // طيّ فورم الإضافة وتفريغ حقوله بعد حفظ ناجح
  void _resetNewAddressForm() {
    if (!mounted) return;
    setState(() {
      _isAddingNewAddress = false;
      _nameController.clear();
      _countryController.clear();
      _cityController.clear();
      _areaController.clear();
      _streetController.clear();
      _buildingController.clear();
    });
  }

  // تحديد موقع المستخدم الحالي عبر GPS
  Future<void> _determinePosition() async {
    setState(() => _isInitialLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      Position position = await Geolocator.getCurrentPosition();
      _currentCenter = LatLng(position.latitude, position.longitude);
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentCenter, 15.0),
      );
      _getLocationDetails(_currentCenter);
    } catch (e) {
      debugPrint("GPS Error: $e");
    } finally {
      if (mounted) setState(() => _isInitialLoading = false);
    }
  }

  // جلب تفاصيل العنوان من الإحداثيات (OSM Nominatim)
  Future<void> _getLocationDetails(LatLng position) async {
    if (!mounted) return;
    setState(() => _isReverseGeocoding = true);
    final String url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position
        .latitude}&lon=${position
        .longitude}&zoom=18&addressdetails=1&accept-language=ar';

    try {
      final response = await http.get(
          Uri.parse(url), headers: {'User-Agent': 'NomNowApp'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final addr = data['address'];
        if (addr != null) {
          setState(() {
            _countryController.text = addr['country'] ?? "";
            _cityController.text =
                addr['city'] ?? addr['town'] ?? addr['state'] ?? "";
            _areaController.text =
                addr['suburb'] ?? addr['neighbourhood'] ?? addr['district'] ??
                    "";
            _streetController.text = addr['road'] ?? "";
            if (_nameController.text.isEmpty) {
              _nameController.text = _areaController.text.isNotEmpty
                  ? _areaController.text
                  : "My Location";
            }
          });
        }
      }
    } catch (e) {
      debugPrint("OSM Error: $e");
    } finally {
      if (mounted) setState(() => _isReverseGeocoding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // التحقق من اكتمال كافة الخطوات الإلزامية لتفعيل زر التأكيد والمعاينة
    bool allStepsCompleted = _nameController.text.isNotEmpty &&
        _countryController.text.isNotEmpty &&
        _cityController.text.isNotEmpty &&
        _buildingController.text.isNotEmpty;

    return BlocListener<LocationBloc, LocationState>(
      // كل فشل يُعرض أياً كان مصدره — الحذف وتعيين الافتراضي لا يمرّان بـ
      // LocationLoading أصلاً. أما رسالة النجاح فتقتصر على عملية حفظ اكتملت
      // (Loading → Success) حتى لا يظهر سناكبار عند كل إعادة تحميل للقائمة.
      listenWhen: (prev, curr) =>
          curr is LocationFailure ||
          (prev is LocationLoading && curr is LocationSuccess),
      listener: (context, state) {
        if (state is LocationFailure) {
          // state.error هو نص الباك المترجم كما استخرجه _handleDioError
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
                content: Text(state.error), backgroundColor: Colors.red));
        } else if (state is LocationSuccess) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
                content: Text("location_saved_success".tr()),
                backgroundColor: Colors.green));
          if (_isAddingNewAddress) _resetNewAddressForm();
        }
      },
      child: _buildScaffold(theme, allStepsCompleted),
    );
  }

  Widget _buildScaffold(ThemeData theme, bool allStepsCompleted) {
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // استخدام الهيدر القديم الاحترافي مع الحواف الدائرية
      appBar: appBarLocationOrder(theme: theme, context: context),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. قسم العناوين المحفوظة (يظهر تلقائياً)
                _buildSavedAddressesSection(theme),

                // 2. زر التبديل لإضافة موقع جديد
                _buildToggleNewAddressBtn(theme),

                // 3. فورم إضافة العنوان الجديد مع الخريطة
                if (_isAddingNewAddress) ...[
                  AppSizes.h24,
                  _buildMapSection(theme),
                  AppSizes.h24,
                  _buildAllStepItems(),

                  // ويدجت معاينة العنوان الكامل - تظهر عند اكتمال البيانات الأساسية
                  if (allStepsCompleted) ...[
                    FullAddressPreviewCard(
                      fullAddress: "${_buildingController
                          .text}، ${_streetController.text}، ${_areaController
                          .text}، ${_cityController.text}",
                    ),
                    AppSizes.h24,
                  ],

                  _buildConfirmButton(theme, allStepsCompleted),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ويدجت عرض العناوين المحفوظة
  Widget _buildSavedAddressesSection(ThemeData theme) {
    return BlocBuilder<LocationBloc, LocationState>(
      builder: (context, state) {
        if (state is LocationLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        // سابقاً كانت القائمة تختفي بصمت عند الفشل — الآن رسالة وزر إعادة محاولة
        if (state is LocationFailure) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Icon(Icons.cloud_off, color: theme.hintColor, size: 40),
                AppSizes.h12,
                Text("error_loading".tr(),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium),
                AppSizes.h12,
                OutlinedButton.icon(
                  onPressed: () =>
                      context.read<LocationBloc>().add(LoadAddressesEvent()),
                  icon: const Icon(Icons.refresh),
                  label: Text("retry".tr()),
                ),
              ],
            ),
          );
        }

        if (state is LocationSuccess && state.addresses.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("saved_addresses_label".tr(),
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold)),
                  // عدّاد يوضّح حد الـ 5 الذي يفرضه الباك
                  Text(
                    "addresses_count".tr().replaceFirst(
                        '{}', '${state.addresses.length}'),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor),
                  ),
                ],
              ),
              AppSizes.h12,
              ...state.addresses.map((addr) =>
                  _buildAddressCard(theme, addr, state)),
              AppSizes.h16,
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  // كارت العنوان المحفوظ الفردي
  Widget _buildAddressCard(ThemeData theme, AddressModel addr,
      LocationSuccess state) {
    final bool isDefault = addr.isDefault;
    // الباك يمنع حذف العنوان الوحيد (cannotDeleteOnly) — نعكس القاعدة هنا
    final bool canDelete = state.addresses.length > 1;
    final bool hasId = addr.id != null && addr.id!.isNotEmpty;

    return GestureDetector(
      // الضغط يعيّن العنوان افتراضياً في الباك (لا اختياراً محلياً)، والشاشة
      // تبقى مفتوحة لأنها شاشة إدارة لا شاشة انتقاء.
      onTap: (isDefault || !hasId)
          ? null
          : () => context
              .read<LocationBloc>()
              .add(SetDefaultAddressEvent(addr.id!)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDefault ? theme.primaryColor.withValues(alpha: 0.1) : theme
              .cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDefault ? theme.primaryColor : theme.dividerColor
                .withValues(alpha: 0.2),
            width: isDefault ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.location_on,
                color: isDefault ? theme.primaryColor : theme.hintColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(addr.addressName,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      if (isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text("default_address_label".tr(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  Text("${addr.city}, ${addr.area}, ${addr.streetChoice}",
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            IconButton(
              tooltip: "edit_button".tr(),
              icon: Icon(Icons.edit_outlined,
                  size: 20, color: theme.hintColor),
              onPressed: hasId ? () => _openEditAddress(addr) : null,
            ),
            IconButton(
              tooltip: "delete_button".tr(),
              icon: Icon(Icons.delete_outline,
                  size: 20,
                  color: canDelete ? Colors.red : theme.disabledColor),
              onPressed: (canDelete && hasId)
                  ? () => _confirmDeleteAddress(addr)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // فتح شاشة التعديل الجاهزة — تمرير existingAddress يجعلها ترسل PATCH
  void _openEditAddress(AddressModel addr) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LocationPickerPage(existingAddress: addr),
      ),
    );
  }

  // حوار تأكيد الحذف ثم إرسال DeleteLocationEvent
  Future<void> _confirmDeleteAddress(AddressModel addr) async {
    final bloc = context.read<LocationBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text("confirm_delete_title".tr()),
        content: Text("confirm_delete_msg".tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text("cancel".tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text("delete".tr(),
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      bloc.add(DeleteLocationEvent(addr.id!));
    }
  }

  // زر اختيار موقع جديد
  Widget _buildToggleNewAddressBtn(ThemeData theme) {
    return BlocBuilder<LocationBloc, LocationState>(
      builder: (context, state) {
        final int count =
            state is LocationSuccess ? state.addresses.length : 0;
        // نمنع رحلة شبكة مرفوضة سلفاً — الباك يرد 400 عند تجاوز الحد
        final bool limitReached = count >= kMaxAddresses;
        final bool disabled = limitReached && !_isAddingNewAddress;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                backgroundColor: _isAddingNewAddress
                    ? theme.primaryColor.withValues(alpha: 0.1)
                    : theme.cardColor,
              ),
              onPressed: disabled
                  ? null
                  : () {
                      setState(
                          () => _isAddingNewAddress = !_isAddingNewAddress);
                      if (_isAddingNewAddress) _determinePosition();
                    },
              icon: Icon(_isAddingNewAddress
                  ? Icons.close
                  : Icons.add_location_alt_outlined),
              label: Text(_isAddingNewAddress
                  ? "cancel".tr()
                  : "select_new_address_button".tr()),
            ),
            if (disabled) ...[
              const SizedBox(height: 8),
              Text(
                "max_addresses_reached".tr(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.hintColor),
              ),
            ],
          ],
        );
      },
    );
  }

  // قسم الخريطة التفاعلية
  Widget _buildMapSection(ThemeData theme) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            _isInitialLoading
                ? const Center(child: CircularProgressIndicator())
                : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentCenter,
                zoom: 15.0,
              ),
              onMapCreated: (controller) => _mapController = controller,
              // newLatLng يحافظ على مستوى التكبير الحالي — نفس سلوك
              // move(latLng, camera.zoom) السابق
              onTap: (latLng) {
                _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
                setState(() => _currentCenter = latLng);
                _getLocationDetails(latLng);
              },
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),
            if (!_isInitialLoading)
              Center(child: Padding(padding: const EdgeInsets.only(bottom: 35),
                  child: Icon(
                      Icons.location_on, color: theme.primaryColor, size: 45))),
            if (_isReverseGeocoding) const Positioned(top: 10,
                right: 10,
                child: CircularProgressIndicator(strokeWidth: 2)),
            Positioned(
              bottom: 15, right: 15,
              child: FloatingActionButton.small(
                heroTag: "gps_btn_in_add_page",
                backgroundColor: theme.cardColor,
                onPressed: _determinePosition,
                child: Icon(Icons.my_location, color: theme.primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // بناء حقول إدخال العنوان
  Widget _buildAllStepItems() {
    return Column(
      children: [
        _stepField(
            "1", "address_name_title", "address_name_desc", "address_name_hint",
            _nameController),
        _stepField(
            "2", "country_step_title", "country_step_desc", "country_hint",
            _countryController),
        _stepField(
            "3", "step_1_title", "step_1_desc", "city_hint", _cityController),
        _stepField(
            "4", "step_2_title", "step_2_desc", "area_hint", _areaController),
        _stepField("5", "street_choice_step_title", "street_choice_step_desc",
            "street_choice_hint", _streetController),
        _stepField(
            "6", "building_step_title", "building_step_desc", "building_hint",
            _buildingController),
      ],
    );
  }

  // ويدجت الخطوة الفردية
  Widget _stepField(String num, String title, String desc, String hint,
      TextEditingController ctrl) {
    return Column(
      children: [
        StepHeader(title: title.tr(),
            description: desc.tr(),
            isCompleted: ctrl.text.isNotEmpty,
            numberStep: num),
        StyledTextField(hint: hint.tr(),
            controller: ctrl,
            onChanged: (v) => setState(() {})),
        AppSizes.h20,
      ],
    );
  }

  // زر التأكيد النهائي
  Widget _buildConfirmButton(ThemeData theme, bool isReady) {
    return BlocBuilder<LocationBloc, LocationState>(
      builder: (context, state) {
        bool loading = state is LocationLoading;
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isReady ? theme.primaryColor : theme.disabledColor,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            elevation: isReady ? 4 : 0,
          ),
          onPressed: isReady && !loading
              ? () {
            final address = AddressModel(
              addressName: _nameController.text,
              country: _countryController.text,
              city: _cityController.text,
              area: _areaController.text,
              streetChoice: _streetController.text,
              buildingDetail: _buildingController.text,
              lat: _currentCenter.latitude,
              lng: _currentCenter.longitude,
              // الباك يجعل أول عنوان افتراضياً تلقائياً، وما بعده يُعيَّن
              // يدوياً بالضغط على الكارت
              isDefault: false,
            );
            context.read<LocationBloc>().add(ConfirmLocationEvent(address));
            // لا إغلاق تلقائي: المستمع في الأعلى يطوي الفورم عند النجاح
            // ويعرض رسالة الباك عند الفشل
          }
              : null,
          child: loading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text("confirm_address_button".tr(), style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold)),
        );
      },
    );
  }
}