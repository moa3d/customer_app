import 'package:flutter/material.dart';

class AppNotificationModel {
  final String id;

  /// معرّف الطلب — يحتاجه زر «تتبع» لفتح شاشة التتبّع الصحيحة.
  final String orderId;
  final String title;
  final String body;
  final String time;
  final IconData icon;
  final Color iconBgColor;
  bool isUnread;
  final bool hasAction;
  final String? actionLabel;
  final bool isPromo;

  AppNotificationModel({
    required this.id,
    required this.orderId,
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.iconBgColor,
    this.isUnread = false,
    this.hasAction = false,
    this.actionLabel,
    this.isPromo = false,
  });
}