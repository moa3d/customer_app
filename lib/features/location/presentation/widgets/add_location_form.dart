import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:nomnow_app/features/location/presentation/widgets/step_header.dart';
import 'package:nomnow_app/features/location/presentation/widgets/styled_dropdown.dart';
import 'package:nomnow_app/features/location/presentation/widgets/styled_textfiled.dart';

import '../../../../core/utils/app_sizes.dart';


class AddLocationForm extends StatelessWidget {
  final String? addressName, country, city, area, streetChoice, buildingDetail;
  final TextEditingController nameController, buildingController;
  final Function(String, String?) onChanged;

  const AddLocationForm({
    super.key,
    required this.onChanged,
    required this.nameController,
    required this.buildingController,
    this.addressName, this.country, this.city, this.area, this.streetChoice, this.buildingDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildStep1(),
        if (addressName?.isNotEmpty ?? false) _buildStep2(),
        if (country != null) _buildStep3(),
        if (city != null) _buildStep4(),
        if (area != null) _buildStep5(),
        if (streetChoice != null) _buildStep6(),
      ],
    );
  }

  Widget _buildStep1() =>
      Column(children: [
        StepHeader(title: "address_name_title".tr(),
            description: "address_name_desc".tr(),
            isCompleted: addressName?.isNotEmpty ?? false,
            numberStep: '1'),
        StyledTextField(hint: "address_name_hint".tr(),
            onChanged: (v) => onChanged('name', v),
            controller: nameController),
        AppSizes.h20,
      ]);

  Widget _buildStep2() =>
      _animateStep(Column(children: [
        StepHeader(title: "country_step_title".tr(),
            description: "country_step_desc".tr(),
            isCompleted: country != null,
            numberStep: '2'),
        StyledDropdown(hint: "country_hint".tr(),
            options: ['syria'.tr(), 'uae'.tr(), 'ksa'.tr()],
            value: country,
            onChanged: (v) => onChanged('country', v)),
        AppSizes.h20,
      ]));

  Widget _buildStep3() =>
      _animateStep(Column(children: [
        StepHeader(title: "step_1_title".tr(),
            description: "step_1_desc".tr(),
            isCompleted: city != null,
            numberStep: '3'),
        StyledDropdown(hint: "city_hint".tr(),
            options: ['city_1'.tr(), 'city_2'.tr()],
            value: city,
            onChanged: (v) => onChanged('city', v)),
        AppSizes.h20,
      ]));

  Widget _buildStep4() =>
      _animateStep(Column(children: [
        StepHeader(title: "step_2_title".tr(),
            description: "step_2_desc".tr(),
            isCompleted: area != null,
            numberStep: '4'),
        StyledDropdown(hint: "area_hint".tr(),
            options: ['area_1'.tr(), 'area_2'.tr()],
            value: area,
            onChanged: (v) => onChanged('area', v)),
        AppSizes.h20,
      ]));

  Widget _buildStep5() =>
      _animateStep(Column(children: [
        StepHeader(title: "street_choice_step_title".tr(),
            description: "street_choice_step_desc".tr(),
            isCompleted: streetChoice != null,
            numberStep: '5'),
        StyledDropdown(hint: "street_choice_hint".tr(),
            options: ['street_1'.tr(), 'street_2'.tr()],
            value: streetChoice,
            onChanged: (v) => onChanged('street', v)),
        AppSizes.h20,
      ]));

  Widget _buildStep6() =>
      _animateStep(Column(children: [
        StepHeader(title: "building_step_title".tr(),
            description: "building_step_desc".tr(),
            isCompleted: buildingDetail?.isNotEmpty ?? false,
            numberStep: '6'),
        StyledTextField(hint: "building_hint".tr(),
            onChanged: (v) => onChanged('building', v),
            controller: buildingController),
        AppSizes.h20,
      ]));

  Widget _animateStep(Widget child) =>
      child.animate().fadeIn().slideY(begin: 0.1);
}