import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/utils/app_sizes.dart';


import '../../data/models/address_model.dart';
import '../bloc/location_bloc.dart';
import '../bloc/location_event.dart';
import '../bloc/location_state.dart';
import '../widgets/step_header.dart';
import '../widgets/styled_textfiled.dart';

// --- ويدجت ملخص العنوان الكامل (أضيفت هنا) ---
class FullAddressSummaryCard extends StatelessWidget {
  final String country;
  final String city;
  final String area;
  final String street;
  final bool isCompleted;

  const FullAddressSummaryCard({
    super.key,
    required this.country,
    required this.city,
    required this.area,
    required this.street,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final String fullAddress = [
      country,
      city,
      area,
      street,
    ].where((s) => s.isNotEmpty).join(" - ");
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "full_address_title".tr(),
                  style: TextStyle(
                    color: theme.textTheme.titleLarge?.color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fullAddress.isEmpty
                      ? "no_address_selected".tr()
                      : fullAddress,
                  style: TextStyle(
                    color: theme.hintColor,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (isCompleted)
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
        ],
      ),
    );
  }
}

class LocationPickerPage extends StatefulWidget {
  final AddressModel? existingAddress;

  const LocationPickerPage({super.key, this.existingAddress});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  LatLng _currentCenter = const LatLng(33.5138, 36.2765); // موقع افتراضي
  bool _isInitialLoading = true;
  // يصل من onMapCreated — لا يتوفّر قبل بناء الخريطة فعلياً
  GoogleMapController? _mapController;

  late TextEditingController _nameController;
  late TextEditingController _countryController;
  late TextEditingController _cityController;
  late TextEditingController _areaController;
  late TextEditingController _streetController;
  late TextEditingController _buildingController;

  @override
  void initState() {
    super.initState();

    _nameController =
        TextEditingController(text: widget.existingAddress?.addressName);
    _countryController =
        TextEditingController(text: widget.existingAddress?.country);
    _cityController = TextEditingController(text: widget.existingAddress?.city);
    _areaController = TextEditingController(text: widget.existingAddress?.area);
    _streetController =
        TextEditingController(text: widget.existingAddress?.streetChoice);
    _buildingController =
        TextEditingController(text: widget.existingAddress?.buildingDetail);

    if (widget.existingAddress?.lat != null &&
        widget.existingAddress?.lng != null) {
      _currentCenter =
          LatLng(widget.existingAddress!.lat!, widget.existingAddress!.lng!);
      _isInitialLoading = false;
    } else {
      _determinePosition();
    }
  }

  @override
  void dispose() {
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

  Future<void> _getLocationDetails(LatLng position) async {
    if (!mounted) return;

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
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    final bool allStepsCompleted = _nameController.text.isNotEmpty &&
        _countryController.text.isNotEmpty &&
        _cityController.text.isNotEmpty &&
        _buildingController.text.isNotEmpty;

    return BlocConsumer<LocationBloc, LocationState>(
      // نتفاعل فقط مع نتيجة عملية حفظ بدأت من هذه الشاشة (Loading → …)،
      // لا مع كل LocationSuccess عابر — وإلا أُغلقت الشاشة بعد فشل الحفظ
      // عندما يستعيد البلوك القائمة السابقة.
      listenWhen: (prev, curr) => prev is LocationLoading,
      listener: (context, state) {
        if (state is LocationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("location_saved_success".tr()),
                backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
        if (state is LocationFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is LocationLoading;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            leading: _buildResponsiveLeading(theme),
            title: Text(widget.existingAddress == null
                ? "add_location_title".tr()
                : "edit_location_title".tr(),
                style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold)),
            actions: [_buildResponsiveAction(theme)],
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildMapPicker(theme),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: mediaQuery
                            .size.width * 0.05),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppSizes.h16,
                            _buildStepField(
                                "1", "address_name_title", "address_name_desc",
                                "address_name_hint", _nameController),
                            _buildStepField(
                                "2", "country_step_title", "country_step_desc",
                                "country_hint", _countryController),
                            _buildStepField(
                                "3", "step_1_title", "step_1_desc", "city_hint",
                                _cityController),
                            _buildStepField(
                                "4", "step_2_title", "step_2_desc", "area_hint",
                                _areaController),
                            _buildStepField("5", "street_choice_step_title",
                                "street_choice_step_desc", "street_choice_hint",
                                _streetController),
                            _buildStepField("6", "building_step_title",
                                "building_step_desc", "building_hint",
                                _buildingController),

                            // ✅ إضافة كرت الملخص هنا
                            if (allStepsCompleted) ...[
                              FullAddressSummaryCard(
                                country: _countryController.text,
                                city: _cityController.text,
                                area: _areaController.text,
                                street: _streetController.text,
                                isCompleted: allStepsCompleted,
                              ),
                              AppSizes.h32,
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildBottomAction(context, theme, allStepsCompleted, isLoading),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepField(String step, String title, String desc, String hint,
      TextEditingController controller) {
    return Column(
      children: [
        StepHeader(
          title: title.tr(),
          isCompleted: controller.text.isNotEmpty,
          numberStep: step,
          description: desc.tr(),
        ),
        StyledTextField(
          hint: hint.tr(),
          controller: controller,
          onChanged: (val) => setState(() {}),
        ),
        AppSizes.h20,
      ],
    );
  }

  Widget _buildMapPicker(ThemeData theme) {
    return SizedBox(
      height: 250,
      width: double.infinity,
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
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 35),
                child: Icon(
                    Icons.location_on, color: theme.primaryColor, size: 45),
              ),
            ),
          Positioned(
            bottom: 15,
            right: 15,
            child: FloatingActionButton.small(
              heroTag: "gps_btn_feature",
              backgroundColor: theme.cardColor,
              onPressed: _determinePosition,
              child: Icon(Icons.my_location, color: theme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveLeading(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        child: InkWell(
          onTap: () => Navigator.pop(context),
          child: const Center(child: Icon(Icons.arrow_back)),
        ),
      ),
    );
  }

  Widget _buildResponsiveAction(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: CircleAvatar(
        backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
        child: Icon(Icons.location_on_outlined, color: theme.primaryColor),
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context, ThemeData theme, bool isReady,
      bool loading) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.p20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5))
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isReady ? theme.primaryColor : theme.disabledColor,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radius12)),
          ),
          onPressed: isReady && !loading
              ? () {
            final address = AddressModel(
              id: widget.existingAddress?.id,
              addressName: _nameController.text,
              country: _countryController.text,
              city: _cityController.text,
              area: _areaController.text,
              streetChoice: _streetController.text,
              buildingDetail: _buildingController.text,
              lat: _currentCenter.latitude,
              lng: _currentCenter.longitude,
            );
            context.read<LocationBloc>().add(ConfirmLocationEvent(address));
          }
              : null,
          child: loading
              ? const SizedBox(height: 20,
              width: 20,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2))
              : Text(
            isReady ? "confirm_address_button".tr() : "fill_all_fields_prompt"
                .tr(),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}