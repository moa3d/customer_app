import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nomnow_app/core/widgets/arrowforward.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguegeScreen extends StatefulWidget {
  const LanguegeScreen({super.key});

  @override
  State<LanguegeScreen> createState() => _LanguegeScreenState();
}

class _LanguegeScreenState extends State<LanguegeScreen> {
  // لستة اللغات المتوفرة بالتبيطق حالياً
  final List<Map<String, String>> globalLangsList = [

    {'code': 'ar', 'nameKey': 'language_ar', 'flag': '🇸🇦'},
    {'code': 'en', 'nameKey': 'language_en', 'flag': '🇺🇸'},
    {'code': 'de', 'nameKey': 'language_de', 'flag': '🇩🇪'},
  ];

  // وظيفة حفظ اللغة الجديدة بالذاكرة الحقيفيه
  Future<void> _setNewLocalData(String codeValue) async {

    context.setLocale(Locale(codeValue));
    final localPrefsStorage = await SharedPreferences
        .getInstance();
    await localPrefsStorage.setString('language_code', codeValue);
  }

  @override
  Widget build(BuildContext context) {
    final themeDataMain = Theme.of(context);
    final bool isRightToLeft = Directionality.of(context) == ui.TextDirection.rtl;

    return Scaffold(
      backgroundColor: themeDataMain.scaffoldBackgroundColor,
      appBar: _buildTopHeaderArea(themeDataMain),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildActiveLangCard(themeDataMain, isRightToLeft),

            const SizedBox(height: 25),

            // عرض خيارات اللغات المتاحة
            RadioGroup<String>(
              groupValue: context.locale.languageCode,
              onChanged: (v) {
                if (v != null) _setNewLocalData(v);
              },
              child: Column(
                children: globalLangsList
                    .map((langItem) =>
                        _buildSingleLangRow(themeDataMain, langItem))
                    .toList(),
              ),
            ),


            const SizedBox(height: 20),
            _buildNoticeBox(themeDataMain),

            const SizedBox(height: 20),
            _buildExtraInfoGrid(themeDataMain, isRightToLeft),
            const SizedBox(height: 20),
            _buildRequestNewBtn(themeDataMain),

          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildTopHeaderArea(ThemeData theme) {
    return AppBar(
      backgroundColor: theme.cardColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: ActionButton(onPressed: () => context.pop()),
          ),
          const SizedBox(width: 10),
          Text(
            "select_app_language_title".tr(),
            style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveLangCard(ThemeData theme, bool isRtl) {
    final currentLocale = context.locale;
    final current = globalLangsList.firstWhere(
          (l) => l['code'] == currentLocale.languageCode,
      orElse: () => globalLangsList.first,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: theme.primaryColor, borderRadius: BorderRadius.circular(15)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(current['flag']!, style: const TextStyle(fontSize: 48)),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("current_language_label".tr(),
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 5),
              Text(current['nameKey']!.tr(), style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSingleLangRow(ThemeData theme, Map<String, String> lang) {
    final isSelected = context.locale.languageCode == lang['code'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(15),
        border: isSelected
            ? Border.all(color: theme.primaryColor, width: 2)
            : null,
      ),
      child: ListTile(
        title: Text(lang['nameKey']!.tr(), style: TextStyle(
            color: isSelected ? theme.primaryColor : null,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
        leading: Text(lang['flag']!, style: const TextStyle(fontSize: 28)),
        trailing: Radio<String>(
          value: lang['code']!,
          activeColor: theme.primaryColor,
        ),
        onTap: () => _setNewLocalData(lang['code']!),
      ),
    );
  }

  Widget _buildNoticeBox(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: theme.cardColor, borderRadius: BorderRadius.circular(15)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: theme.primaryColor, size: 22),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("note_title".tr(), style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 5),
                Text("language_change_note".tr(),
                    style: const TextStyle(fontSize: 12, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtraInfoGrid(ThemeData theme, bool isRtl) {
    return Row(
      children: [
        Expanded(child: _buildInfoItem(theme, icon: Icons.translate,
            val: isRtl ? "RTL" : "LTR",
            lbl: "text_direction_title")),
        const SizedBox(width: 15),
        Expanded(child: _buildInfoItem(
            theme, val: globalLangsList.length.toString(),
            lbl: "available_languages_count")),
      ],
    );
  }

  Widget _buildInfoItem(ThemeData theme,
      {IconData? icon, required String val, required String lbl}) {
    return Container(
      height: 100, padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: theme.cardColor, borderRadius: BorderRadius.circular(15)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon != null ? Icon(icon, color: theme.primaryColor, size: 30) : Text(
              val, style: const TextStyle(
              fontSize: 30, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(lbl.tr(), style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildRequestNewBtn(ThemeData theme) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.add_comment_outlined),
      label: Text("request_new_language_button".tr(),
          style: const TextStyle(fontWeight: FontWeight.bold)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }
}

