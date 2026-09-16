import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'dio_client.dart';

/// استثناء يحمل [AppError] مصنَّفاً مسبقاً.
///
/// المستودعات وحدها ترى `DioException` الخام، والواجهة تحتاج رسالة جاهزة.
/// وكانت المستودعات تلفّ الخطأ في `Exception(message)` عادي، فيفقد
/// [AppError.from] كل ما يميّزه ويصنّفه `unknown` — فتُستبدل رسالة الخادم
/// المفيدة (سلة من مطعم آخر، وجبة غير متاحة، حجم مطلوب...) برسالة عامة.
/// هذا النوع يحفظ التصنيف والرسالة معاً حتى تصل الواجهة.
class ApiException implements Exception {
  final AppError error;

  const ApiException(this.error);

  String get message => error.message;

  @override
  String toString() => message;
}

/// تصنيف موحّد لأخطاء الشبكة والاستثناءات العامة.
enum AppErrorKind {
  noConnection,
  timeout,
  server,
  notFound,
  unauthorized,
  badRequest,
  unknown,
}

/// يحوّل الاستثناء الخام إلى رسالة صالحة للعرض على المستخدم.
///
/// الغرض الأساسي منه منع تسريب التفاصيل التقنية (اسم نطاق الخادم،
/// `DioException`، `errno`) إلى الواجهة كما كان يحدث سابقاً في الصفحة
/// الرئيسية. التفاصيل الخام تبقى متاحة في [technicalDetails] وتُعرض
/// في وضع التطوير فقط.
class AppError {
  final AppErrorKind kind;
  final String titleKey;
  final String messageKey;

  /// رسالة قادمة من الباك أند — تُستخدم بدل [messageKey] عند توفرها،
  /// وذلك في أخطاء 4xx فقط حيث تكون الرسالة موجّهة للمستخدم أصلاً.
  final String? serverMessage;

  /// النص الخام للاستثناء — للسجلات ووضع التطوير، لا يُعرض في الإصدار.
  final String technicalDetails;

  const AppError({
    required this.kind,
    required this.titleKey,
    required this.messageKey,
    this.serverMessage,
    this.technicalDetails = '',
  });

  String get title => titleKey.tr();

  String get message => serverMessage ?? messageKey.tr();

  /// هل تُجدي إعادة المحاولة؟ الجلسة المنتهية والمورد المحذوف لا يُصلحهما زر.
  bool get canRetry =>
      kind != AppErrorKind.unauthorized && kind != AppErrorKind.notFound;

  IconData get icon {
    switch (kind) {
      case AppErrorKind.noConnection:
        return Icons.wifi_off_rounded;
      case AppErrorKind.timeout:
        return Icons.schedule_rounded;
      case AppErrorKind.server:
        return Icons.cloud_off_rounded;
      case AppErrorKind.notFound:
        return Icons.search_off_rounded;
      case AppErrorKind.unauthorized:
        return Icons.lock_outline_rounded;
      case AppErrorKind.badRequest:
      case AppErrorKind.unknown:
        return Icons.error_outline_rounded;
    }
  }

  factory AppError.from(Object? error) {
    if (error is AppError) return error;
    if (error is ApiException) return error.error;
    if (error is DioException) return AppError._fromDio(error);
    if (error is SocketException) {
      return AppError._of(AppErrorKind.noConnection, details: '$error');
    }
    return AppError._of(AppErrorKind.unknown, details: '$error');
  }

  factory AppError._fromDio(DioException e) {
    final details = _detailsOf(e);

    // خطأ الشبكة قد يصل ملفوفاً بنوع unknown، لذا نفحص الاستثناء الداخلي.
    if (e.error is SocketException) {
      return AppError._of(AppErrorKind.noConnection, details: details);
    }

    switch (e.type) {
      case DioExceptionType.connectionError:
        return AppError._of(AppErrorKind.noConnection, details: details);

      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppError._of(AppErrorKind.timeout, details: details);

      case DioExceptionType.badCertificate:
        return AppError._of(AppErrorKind.server, details: details);

      case DioExceptionType.badResponse:
        return AppError._fromStatus(e, details);

      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return AppError._of(AppErrorKind.unknown, details: details);
    }
  }

  factory AppError._fromStatus(DioException e, String details) {
    final status = e.response?.statusCode ?? 0;

    if (status == 401 || status == 403) {
      return AppError._of(AppErrorKind.unauthorized, details: details);
    }
    if (status == 404) {
      return AppError._of(AppErrorKind.notFound, details: details);
    }
    if (status >= 500) {
      return AppError._of(AppErrorKind.server, details: details);
    }
    return AppError._of(
      AppErrorKind.badRequest,
      details: details,
      serverMessage: _userFacingServerMessage(e.response?.data),
    );
  }

  /// خطأ معروف التصنيف لا ينبع من استثناء — مثل ردّ ناجح شكلياً
  /// يحمل `success: false`.
  factory AppError.ofKind(AppErrorKind kind, {String? serverMessage}) =>
      AppError._of(kind, serverMessage: serverMessage);

  factory AppError._of(
    AppErrorKind kind, {
    String details = '',
    String? serverMessage,
  }) {
    final slug = _slugs[kind]!;
    return AppError(
      kind: kind,
      titleKey: 'errors.${slug}_title',
      messageKey: 'errors.${slug}_msg',
      serverMessage: serverMessage,
      technicalDetails: details,
    );
  }

  /// أسماء مفاتيح الترجمة تحت `errors` في ملفات assets/translations.
  static const Map<AppErrorKind, String> _slugs = {
    AppErrorKind.noConnection: 'no_connection',
    AppErrorKind.timeout: 'timeout',
    AppErrorKind.server: 'server',
    AppErrorKind.notFound: 'not_found',
    AppErrorKind.unauthorized: 'unauthorized',
    AppErrorKind.badRequest: 'bad_request',
    AppErrorKind.unknown: 'unknown',
  };

  /// تُقبل رسالة الخادم فقط إذا كانت نصاً قصيراً خالياً من أي أثر تقني
  /// (رابط أو اسم نطاق)، وإلا نرجع إلى الرسالة المترجمة.
  static String? _userFacingServerMessage(dynamic data) {
    if (data is! Map) return null;
    final raw = data['message'] ?? data['error'];
    if (raw is! String) return null;

    final text = raw.trim();
    if (text.isEmpty || text.length > 160) return null;
    if (text.contains('http') || text.contains(_host)) return null;
    return text;
  }

  static final String _host = Uri.parse(DioClient.baseUrl).host;

  static String _detailsOf(DioException e) {
    final status = e.response?.statusCode;
    return '${e.type.name}'
        '${status != null ? ' ($status)' : ''}'
        ': ${e.message ?? e.error ?? ''}';
  }
}
