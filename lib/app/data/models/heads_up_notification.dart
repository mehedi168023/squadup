import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// The three notification styles (spec §2):
/// * [push]    — plain informational notification.
/// * [headsUp] — instant top banner for important events.
/// * [action]  — banner carrying a deep-link action button.
enum NotifKind { push, headsUp, action }

/// Delivery priority — drives the banner accent colour and OS importance.
enum NotifPriority { low, normal, high, urgent }

/// A backend / FCM-driven notification. Field names mirror the API payload so a
/// raw data map decodes 1:1 — see `NOTIFICATIONS.md` for the full contract.
class HeadsUpNotification {
  final String id; // dedupe key
  final String title;
  final String message;
  final String? image; // large banner image (asset path or http URL)
  final String? icon; // small icon key (mapped to a glyph)
  final NotifKind kind; // notification_type
  final NotifPriority priority;
  final String? actionText; // action_button_text
  final String? actionTarget; // action_target_screen (deep-link key)
  final Map<String, dynamic> actionArgs;
  final String? sound; // sound_file (bundled raw resource name)
  final Duration autoHide; // auto_hide_duration (Duration.zero = sticky)

  const HeadsUpNotification({
    required this.id,
    required this.title,
    required this.message,
    this.image,
    this.icon,
    this.kind = NotifKind.headsUp,
    this.priority = NotifPriority.normal,
    this.actionText,
    this.actionTarget,
    this.actionArgs = const {},
    this.sound,
    this.autoHide = const Duration(seconds: 4),
  });

  bool get hasAction =>
      kind == NotifKind.action &&
      (actionTarget != null || (actionText != null && actionText!.isNotEmpty));
  bool get hasImage => image != null && image!.isNotEmpty;
  bool get isNetworkImage =>
      hasImage &&
      (image!.startsWith('http://') || image!.startsWith('https://'));

  /// Small icon glyph for the banner / feed.
  IconData get glyph {
    switch (icon) {
      case 'wallet':
        return Icons.account_balance_wallet_rounded;
      case 'payment':
      case 'coin':
      case 'money':
        return Icons.payments_rounded;
      case 'match':
      case 'tournament':
        return Icons.sports_esports_rounded;
      case 'room':
        return Icons.meeting_room_rounded;
      case 'trophy':
      case 'result':
      case 'winner':
        return Icons.emoji_events_rounded;
      case 'topup':
        return Icons.bolt_rounded;
      case 'profile':
        return Icons.person_rounded;
      case 'promo':
        return Icons.local_fire_department_rounded;
      case 'success':
        return Icons.check_circle_rounded;
      case 'warning':
        return Icons.warning_amber_rounded;
      default:
        return switch (kind) {
          NotifKind.action => Icons.notifications_active_rounded,
          NotifKind.headsUp => Icons.campaign_rounded,
          NotifKind.push => Icons.notifications_rounded,
        };
    }
  }

  /// Accent colour (banner border/glow + action button) derived from priority.
  Color get accent => switch (priority) {
        NotifPriority.urgent => AppColors.killRed,
        NotifPriority.high => AppColors.gold,
        NotifPriority.normal => AppColors.primary,
        NotifPriority.low => AppColors.winningTeal,
      };

  /// Decodes a backend / FCM `data` payload. Unknown/missing fields fall back to
  /// safe defaults so a partial payload never throws.
  factory HeadsUpNotification.fromJson(Map<String, dynamic> j) {
    final rawDur = j['auto_hide_duration'];
    final ms = rawDur is int ? rawDur : int.tryParse('${rawDur ?? ''}') ?? 4000;
    final args = j['action_args'];
    return HeadsUpNotification(
      id: _str(j['id']) ?? 'ntf_${DateTime.now().microsecondsSinceEpoch}',
      title: _str(j['title']) ?? '',
      message: _str(j['message']) ?? _str(j['body']) ?? '',
      image: _str(j['image']),
      icon: _str(j['icon']),
      kind: _kind(_str(j['notification_type'])),
      priority: _priority(_str(j['priority'])),
      actionText: _str(j['action_button_text']),
      actionTarget: _str(j['action_target_screen']),
      actionArgs: args is Map
          ? args.map((k, v) => MapEntry(k.toString(), v))
          : const {},
      sound: _str(j['sound_file']),
      autoHide: Duration(milliseconds: ms < 0 ? 0 : ms),
    );
  }

  static String? _str(dynamic v) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  static NotifKind _kind(String? s) => switch (s) {
        'push' => NotifKind.push,
        'action' => NotifKind.action,
        _ => NotifKind.headsUp,
      };

  static NotifPriority _priority(String? s) => switch (s) {
        'low' => NotifPriority.low,
        'high' => NotifPriority.high,
        'urgent' => NotifPriority.urgent,
        _ => NotifPriority.normal,
      };
}
