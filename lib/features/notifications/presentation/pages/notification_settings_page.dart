import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/bloc/settings/settings_cubit.dart';
import '../../../../core/bloc/settings/settings_state.dart';
import '../../../../core/services/notification_permission_service.dart';
import '../../../../core/widgets/arrowforward.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage>
    with WidgetsBindingObserver {
  /// حالة صلاحية النظام. المفاتيح أدناه إعدادات داخل التطبيق فقط، فلو كانت
  /// الصلاحية مغلقة كانت الشاشة توحي بأن الإشعارات شغّالة وهي ليست كذلك.
  NotificationPermissionStatus _permission =
      NotificationPermissionStatus.granted;

  /// هل يكفي زر داخل التطبيق، أم لا مخرج إلا إعدادات النظام؟
  bool _canRequestAgain = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // العودة من إعدادات النظام: نعيد القراءة فوراً بلا إعادة تشغيل التطبيق
    if (state == AppLifecycleState.resumed) _refreshPermission();
  }

  Future<void> _refreshPermission() async {
    final service = NotificationPermissionService();
    final status = await service.check();
    final canPrompt = await service.canStillPrompt(status);
    if (!mounted) return;
    setState(() {
      _permission = status;
      _canRequestAgain = canPrompt;
    });
  }

  /// `unsupported` تعني منصّة غير أندرويد أو تعذّر الوصول للقناة — لا نُظهر
  /// تحذيراً لا نملك إثباته ولا نُعطّل المفاتيح.
  bool get _notificationsBlocked =>
      _permission != NotificationPermissionStatus.granted &&
      _permission != NotificationPermissionStatus.unsupported;

  Future<void> _onFixPressed() async {
    if (_canRequestAgain) {
      await NotificationPermissionService().request();
      await _refreshPermission();
    } else {
      await NotificationPermissionService().openSystemSettings();
      // القراءة الفعلية تحدث في didChangeAppLifecycleState عند العودة
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: _buildAppBar(theme),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // 0. تحذير حالة النظام — يظهر فقط حين تكون الصلاحية مغلقة
                if (_notificationsBlocked)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _buildPermissionBanner(theme),
                  ),

                // 1. بطاقة تفعيل جميع الإشعارات
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildAllNotificationsCard(theme, state),
                ),
                const SizedBox(height: 10),

                // 2. قسم أنواع الإشعارات
                Text(
                  "notification_types_title".tr(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildNotificationItem(
                    theme,
                    titleKey: "order_status_title",
                    subtitleKey: "order_status_subtitle",
                    icon: Icons.fastfood_outlined,
                    value: state.orderStatusNotifications,
                    onChanged: (v) =>
                        context.read<SettingsCubit>().updateNotification(
                            'orderStatus', v),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      left: 8.0, right: 8, bottom: 8),
                  child: _buildNotificationItem(
                    theme,
                    titleKey: "delivery_title",
                    subtitleKey: "delivery_subtitle",
                    icon: Icons.delivery_dining,
                    value: state.deliveryNotifications,
                    onChanged: (v) =>
                        context.read<SettingsCubit>().updateNotification(
                            'delivery', v),
                  ),
                ),
                // مفاتيح «العروض» و«الصوت» و«الاهتزاز» محذوفة عمداً: لا وجود
                // لإشعارات عروض في النظام أصلاً، والصوت والاهتزاز يحكمهما
                // إعداد قناة النظام (order_status) لا التطبيق — بلا
                // flutter_local_notifications لا سبيل للتحكّم بهما من هنا.
                // كانت الثلاثة تُحفَظ ولا يقرؤها شيء، أي إعداد يكذب على
                // المستخدم. حقولها باقية في SettingsState دون ضرر.

                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: theme.cardColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          ActionButton(onPressed: () => context.pop()),
          const SizedBox(width: 10),
          Text(
            "notifications_title".tr(),
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllNotificationsCard(ThemeData theme, SettingsState state) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.primaryColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "all_notifications_title".tr(),
                  style: const TextStyle(color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  "all_notifications_subtitle".tr(),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 1.2,
            child: Switch(
              value: state.allNotificationsEnabled && !_notificationsBlocked,
              onChanged: _notificationsBlocked
                  ? null
                  : (v) =>
                      context.read<SettingsCubit>().toggleAllNotifications(v),
              activeThumbColor: Colors.white,
              activeTrackColor: Colors.white38,
              inactiveTrackColor: Colors.black26,
              inactiveThumbColor: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.notifications_active_outlined, color: Colors.white,
              size: 30),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(ThemeData theme, {
    required String titleKey,
    required String subtitleKey,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Opacity(
      opacity: _notificationsBlocked ? 0.5 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Transform.scale(
                  scale: 0.85,
                  child: Switch(
                    value: value && !_notificationsBlocked,
                    onChanged: _notificationsBlocked ? null : onChanged,
                    activeThumbColor: theme.primaryColor,
                    inactiveThumbColor: theme.hintColor,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleKey.tr(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitleKey.tr(),
                      style: TextStyle(color: theme.hintColor, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
          ],
        ),
      ),
    );
  }

  /// بطاقة التحذير: تشرح أن الإشعارات مغلقة على مستوى النظام وتعطي مخرجاً.
  ///
  /// الزر يختلف حسب الحالة — الرفض العادي ما زال يقبل حوار النظام، أما الرفض
  /// النهائي أو الإغلاق من الإعدادات فلا يُصلحه إلا فتح شاشة الإعدادات.
  Widget _buildPermissionBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.orange, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_off_outlined,
                  color: Colors.orange, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "notif_permission_disabled_title".tr(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "notif_permission_disabled_body".tr(),
            style: TextStyle(color: theme.hintColor, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _onFixPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _canRequestAgain
                    ? "notif_permission_enable".tr()
                    : "notif_permission_open_settings".tr(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
