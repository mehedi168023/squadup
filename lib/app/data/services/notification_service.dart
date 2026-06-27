import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../../core/heads_up.dart';
import '../../core/logger.dart';
import '../../core/notification_router.dart';
import '../models/heads_up_notification.dart';
import '../models/notification_model.dart';
import 'notifications/notif_platform.dart';

/// Manages the in-app notification feed and fires OS notifications (mobile).
class NotificationService extends GetxService {
  static NotificationService get to => Get.find();

  final LocalNotifier _notifier = LocalNotifier();
  LocalNotifier get notifier => _notifier;
  final RxList<AppNotification> items = <AppNotification>[].obs;

  int get unreadCount => items.where((n) => !n.read).length;

  @override
  void onInit() {
    super.onInit();
    _seedDemo();
    // Defer the notification-plugin init (a platform-channel round-trip) until
    // after the first frame so it doesn't compete with startup rendering.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifier.init();
      initOneSignal();
    });
  }

  Future<void> initOneSignal() async {
    try {
      AppLogger.info('NotificationService', 'Initializing OneSignal...');
      // Initialize OneSignal with correct App ID.
      OneSignal.initialize("39c35d80-6f4e-4672-86c8-40cdb14dfaff");

      // Handle notification clicks
      OneSignal.Notifications.addClickListener((event) {
        final notif = event.notification;
        final data = notif.additionalData;
        AppLogger.info('NotificationService', 'OneSignal notification clicked! Id: ${notif.notificationId}, Data: $data');
        if (data != null) {
          try {
            final target = (data['action_target_screen'] ?? data['target'])?.toString();
            final args = data['action_args'] is Map ? Map<String, dynamic>.from(data['action_args']) : const <String, dynamic>{};
            if (target != null && target.isNotEmpty) {
              AppLogger.info('NotificationService', 'Routing from OneSignal click. Target: $target, Args: $args');
              NotificationRouter.open(target, args);
            }
          } catch (e, s) {
            AppLogger.error('NotificationService', 'Error routing from notification tap', e, s);
          }
        }
      });

      // Handle foreground notifications (app is open)
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        final notif = event.notification;
        AppLogger.info('NotificationService', 'Foreground notification intercepted: ${notif.notificationId}');
        
        // Prevent default OneSignal OS notification to avoid duplicates,
        // and display our own custom notification through the high importance channel.
        event.preventDefault();

        final data = notif.additionalData ?? {};
        
        final map = {
          'id': notif.notificationId,
          'title': notif.title ?? '',
          'message': notif.body ?? '',
          ...data,
        };
        final headsUpNotif = HeadsUpNotification.fromJson(map);

        // Show the in-app heads-up banner
        HeadsUp.show(headsUpNotif);

        // Post a local notification using the 'urgent_notifications' channel
        _notifier.show(
          id: headsUpNotif.id.hashCode & 0x7fffffff,
          title: headsUpNotif.title,
          body: headsUpNotif.message,
          sound: headsUpNotif.sound,
          image: headsUpNotif.image,
          badge: unreadCount + 1,
          payload: {
            'target': headsUpNotif.actionTarget,
            'args': headsUpNotif.actionArgs,
          },
        );

        // Also push it to the internal feed items
        push(
          type: _feedType(headsUpNotif),
          title: notif.title ?? '',
          body: notif.body ?? '',
          osNotify: false,
        );
      });
    } catch (e, s) {
      AppLogger.error('NotificationService', 'OneSignal Initialization failed', e, s);
    }
  }

  Future<bool> requestOsPermission() async {
    AppLogger.info('NotificationService', 'Requesting OS Notification Permission...');
    try {
      await OneSignal.Notifications.requestPermission(true);
    } catch (e, s) {
      AppLogger.error('NotificationService', 'OneSignal requestPermission failed', e, s);
    }
    return _notifier.requestPermission();
  }

  /// Fires a real OS heads-up notification right after a successful login so the
  /// pipeline is verifiable end-to-end. Requests the Android 13+
  /// POST_NOTIFICATIONS permission first.
  Future<void> notifyLoginSuccess() async {
    await requestOsPermission();
    await push(
      type: NotifType.system,
      title: 'SquadUp',
      body: 'Login successful! Notifications are working.',
    );
  }

  /// Adds a notification to the in-app feed AND pops an OS notification.
  Future<void> push({
    required NotifType type,
    required String title,
    required String body,
    bool osNotify = true,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    items.insert(
        0,
        AppNotification(
            id: id,
            type: type,
            title: title,
            body: body,
            time: DateTime.now()));
    if (osNotify) {
      AppLogger.info('NotificationService', 'Triggering push local notification. title: "$title"');
      await _notifier.show(
        id: id % 100000,
        title: title,
        body: body,
      );
    }
  }

  // Backend / FCM ───────────────────────────────────────────────────────────

  final Set<String> _seen = {};

  /// Entry point for backend / FCM `data` payloads (foreground). Dedupes by id,
  /// shows the in-app banner, mirrors to the feed and fires the OS notification
  /// so behaviour matches background/terminated delivery.
  void handleRemoteMessage(Map<String, dynamic> data) {
    AppLogger.info('NotificationService', 'FCM Remote message received foreground. Data: $data');
    final n = HeadsUpNotification.fromJson(data);
    if (!_seen.add(n.id)) return; // duplicate — ignore
    showHeadsUp(n, osNotify: true);
  }

  /// Show a rich heads-up banner. With [osNotify] it also posts an OS
  /// notification (plays the custom/default sound + adds a tray entry).
  void showHeadsUp(HeadsUpNotification n, {bool osNotify = false}) {
    HeadsUp.show(n);
    items.insert(
      0,
      AppNotification(
        id: n.id.hashCode,
        type: _feedType(n),
        title: n.title,
        body: n.message,
        time: DateTime.now(),
      ),
    );
    if (osNotify) {
      AppLogger.info('NotificationService', 'FCM displaying HeadsUp notifications via LocalNotifier.');
      _notifier.show(
        id: n.id.hashCode & 0x7fffffff,
        title: n.title,
        body: n.message,
        sound: n.sound,
        image: n.image,
        payload: {
          'target': n.actionTarget,
          'args': n.actionArgs,
        },
      );
    }
  }

  NotifType _feedType(HeadsUpNotification n) {
    switch (n.icon) {
      case 'wallet':
      case 'payment':
      case 'coin':
      case 'money':
        return NotifType.wallet;
      case 'match':
      case 'tournament':
      case 'room':
        return NotifType.match;
      case 'trophy':
      case 'result':
      case 'winner':
      case 'promo':
        return NotifType.promo;
      default:
        return NotifType.system;
    }
  }

  void markAllRead() {
    for (final n in items) {
      n.read = true;
    }
    items.refresh();
  }

  void clearAll() => items.clear();

  /// A test notification triggered from the Notifications screen.
  Future<void> sendTest() => push(
        type: NotifType.system,
        title: 'Test Notification 🔔',
        body: 'This is a demo notification from SquadUp.',
      );

  void _seedDemo() {
    items.assignAll([
      AppNotification(
        id: 1,
        type: NotifType.promo,
        title: 'Weekly Mega Tournament 🔥',
        body: 'Join the BR Solo Time match and win up to ৳160!',
        time: DateTime.now().subtract(const Duration(minutes: 12)),
      ),
      AppNotification(
        id: 2,
        type: NotifType.wallet,
        title: 'Wallet Ready',
        body: 'Add money via bKash or Nagad to join paid matches.',
        time: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      AppNotification(
        id: 3,
        type: NotifType.system,
        title: 'Welcome to SquadUp 🏆',
        body: 'Compete in Free Fire tournaments and earn rewards.',
        time: DateTime.now().subtract(const Duration(days: 1)),
        read: true,
      ),
    ]);
  }
}
