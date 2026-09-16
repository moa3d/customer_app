import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../network/dio_client.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  io.Socket? socket;

  factory SocketService() => _instance;

  SocketService._internal();

  String? _token;

  StreamController<Map<String, dynamic>> _orderStatusController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get orderStatusStream =>
      _orderStatusController.stream;

  final ValueNotifier<bool> connected = ValueNotifier<bool>(false);

  bool get isConnected => socket != null && socket!.connected;

  bool get hasToken => _token != null && _token!.isNotEmpty;

  void connect(String token) {
    if (token.isEmpty) return;

    if (isConnected && _token == token) {
      debugPrint('ℹ️ [SOCKET]: Already connected, skipping reconnect');
      return;
    }

    _token = token;

    if (_orderStatusController.isClosed) {
      _orderStatusController =
          StreamController<Map<String, dynamic>>.broadcast();
    }

    if (socket != null) {
      socket!.clearListeners();
      socket!.dispose();
      socket = null;
    }

    final String url = DioClient.baseUrl.endsWith('/')
        ? '${DioClient.baseUrl}user'
        : '${DioClient.baseUrl}/user';

    socket = io.io(
      url,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(2000)
          .setReconnectionDelayMax(15000)
          .build(),
    );

    socket!.onConnect((_) {
      connected.value = true;
      debugPrint('✅ [SOCKET SUCCESS]: Connected to /user Namespace');
    });

    socket!.on('order:statusUpdated', (data) {
      if (data is! Map) return;
      if (_orderStatusController.isClosed) return;
      _orderStatusController.add(Map<String, dynamic>.from(data));
    });

    socket!.onConnectError((data) {
      connected.value = false;
      debugPrint('❌ [SOCKET ERROR]: Connection failed: $data');
    });

    socket!.onDisconnect((_) {
      connected.value = false;
      debugPrint('ℹ️ [SOCKET INFO]: Disconnected from server');
    });
  }

  void ensureConnected() {
    if (!hasToken) return;

    if (socket == null) {
      connect(_token!);
      return;
    }
    if (!socket!.connected) {
      debugPrint('🔄 [SOCKET]: Reconnecting…');
      socket!.connect();
    }
  }

  StreamSubscription<Map<String, dynamic>> listenToOrderStatus(
      Function(Map<String, dynamic>) onStatusChanged) {
    return orderStatusStream.listen(onStatusChanged);
  }

  void listenToErrors(Function(String message) onError) {
    socket?.off('order:error');
    socket?.on('order:error', (data) {
      final msg = data is Map ? data['message'] : null;
      onError(msg?.toString() ?? 'Unknown socket error');
    });
  }

  void listenToPromotionExpired(Function(Map<String, dynamic> data) onExpired) {
    socket?.off('order:promotionExpired');
    socket?.on('order:promotionExpired', (data) {
      if (data is! Map) return;
      onExpired(Map<String, dynamic>.from(data));
    });
  }

  void listenToOrderSent(Function(Map<String, dynamic> data) onSent) {
    socket?.off('order:sent');
    socket?.on('order:sent', (data) {
      if (data is! Map) return;
      onSent(Map<String, dynamic>.from(data));
    });
  }

  /// v4.2 — السلة تغيّرت بين إنشاء الطلب وإرساله، فلم يُرسَل الطلب.
  ///
  /// الباك يبثّه **بدل** `order:sent`، فبلا مستمع له يبقى انتظار التأكيد معلّقاً
  /// حتى تنتهي مهلة العشرين ثانية ثم تظهر رسالة «تعذّر تأكيد حالة الطلب» —
  /// وهي أسوأ من الصمت الذي كان قبله.
  ///
  /// خلافاً لبقية المستمعات لا يشترط أن تكون الحمولة `Map`: شكلها غير مؤكَّد
  /// من الباك بعد، وسقوط النداء بسبب شكل غير متوقَّع يعيد التعليق نفسه الذي
  /// وُجد هذا المستمع ليمنعه.
  void listenToCartChanged(Function(Map<String, dynamic> data) onChanged) {
    socket?.off('order:cartChanged');
    socket?.on('order:cartChanged', (data) {
      onChanged(data is Map ? Map<String, dynamic>.from(data) : const {});
    });
  }

  void removeCheckoutListeners() {
    socket?.off('order:sent');
    socket?.off('order:promotionExpired');
    socket?.off('order:cartChanged');
    socket?.off('order:error');
  }

  bool sendOrderToRestaurant(String orderId, {String? paymentIntentId}) {
    if (!isConnected) {
      debugPrint('🚨 Cannot send order: Socket is not connected!');
      return false;
    }

    final payload = {
      'orderId': orderId,
      'paymentIntentId': ?paymentIntentId,
    };
    socket!.emit('order:send', payload);
    debugPrint('📤 Socket emitted order:send with data: $payload');
    return true;
  }

  // v3.0 — حُذفت دالة confirmOrderDelivery: الباك اند ألغى المستمع
  // order:confirmDelivery بالكامل (كان جزءاً من مرحلة تأكيد العميل التي
  // اختفت مع حالة delivered_by_driver). التسليم الآن يُنشئه السائق مباشرة
  // عبر order:delivered، والزبون يتابع الحالة فقط دون أي إجراء تأكيد.

  void disconnect() {
    if (socket != null) {
      socket!.clearListeners();
      socket!.disconnect();
      socket!.dispose();
      socket = null;
    }
    _token = null;
    connected.value = false;
    debugPrint('🔌 [SOCKET INFO]: Manual disconnection');
  }

  void dispose() {
    _orderStatusController.close();
    disconnect();
  }
}
