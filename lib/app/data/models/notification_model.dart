import 'package:flutter/material.dart';

enum NotifType { match, wallet, system, promo }

/// An in-app notification shown on the Notifications screen.
class AppNotification {
  final int id;
  final NotifType type;
  final String title;
  final String body;
  final DateTime time;
  bool read;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    this.read = false,
  });

  IconData get icon => switch (type) {
        NotifType.match => Icons.sports_esports,
        NotifType.wallet => Icons.account_balance_wallet,
        NotifType.system => Icons.info,
        NotifType.promo => Icons.local_fire_department,
      };

  Color get color => switch (type) {
        NotifType.match => const Color(0xFF2F6BFF),
        NotifType.wallet => const Color(0xFF2BD9A0),
        NotifType.system => const Color(0xFF8A93A5),
        NotifType.promo => const Color(0xFFF5B71E),
      };
}
