import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/cart/presentation/bloc/mail_bloc.dart';
import '../../features/cart/presentation/bloc/mail_event.dart';
import 'order_notifications_service.dart';
import 'push_notification_service.dart';
import 'socket_service.dart';

class AppLifecycleGate extends StatefulWidget {
  final Widget child;

  const AppLifecycleGate({super.key, required this.child});

  @override
  State<AppLifecycleGate> createState() => _AppLifecycleGateState();
}

class _AppLifecycleGateState extends State<AppLifecycleGate>
    with WidgetsBindingObserver {
  DateTime? _lastSync;
  DateTime? _pausedAt;

  static const Duration _minSyncGap = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        _onResumed();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _pausedAt = DateTime.now();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  void _onResumed() {
    final socket = SocketService();
    if (!socket.hasToken) return;

    final now = DateTime.now();
    if (_lastSync != null && now.difference(_lastSync!) < _minSyncGap) {
      return;
    }
    _lastSync = now;

    final away = _pausedAt == null ? Duration.zero : now.difference(_pausedAt!);
    debugPrint('🔁 [LIFECYCLE]: Resumed after ${away.inSeconds}s — resyncing');

    socket.ensureConnected();

    // إعادة قراءة سجلّ الإشعارات من القرص قبل أي شيء يكتب فيه: عزلة الخلفية
    // قد تكون سجّلت إشعاراً بينما كانت هذه العملية موقوفة، فقائمتنا في الذاكرة
    // قديمة — وأول حفظ بعدها كان سيدهس ما كتبته.
    OrderNotificationsService().reload();

    // v3.5 — إعادة تسجيل توكن الإشعارات عند كل عودة للتطبيق، كما تفرض
    // المواصفة. الكاش الداخلي يمنع نداءً متكرراً إن لم يتغيّر التوكن.
    PushNotificationService().registerToken();

    if (!mounted) return;
    try {
      context.read<MailBloc>().add(FetchUserOrdersEvent());
    } catch (e) {
      debugPrint('[LIFECYCLE]: could not refresh orders → $e');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
