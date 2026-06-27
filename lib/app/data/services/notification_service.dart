import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../core/heads_up.dart';
import '../models/heads_up_notification.dart';
import '../models/notification_model.dart';
import 'notifications/notif_platform.dart';

/// Manages the in-app notification feed and fires OS notifications (mobile).
class NotificationService extends GetxService {
  static NotificationService get to => Get.find();

  final LocalNotifier _notifier = LocalNotifier();
  final RxList<AppNotification> items = <AppNotification>[].obs;

  int get unreadCount => items.where((n) => !n.read).length;

  @override
  void onInit() {
    super.onInit();
    _seedDemo();
    // Defer the notification-plugin init (a platform-channel round-trip) until
    // after the first frame so it doesn't compete with startup rendering — a
    // major contributor to skipped frames on launch. `show()` also lazily
    // re-inits the notifier, so nothing breaks if a notification fires first.
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifier.init());
  }

  Future<bool> requestOsPermission() => _notifier.requestPermission();

  /// Fires a real OS heads-up notification right after a successful login so the
  /// pipeline is verifiable end-to-end. Requests the Android 13+
  /// POST_NOTIFICATIONS permission first, then posts on the *default* channel
  /// (Importance.max → system pop-up, visible even in the foreground). It
  /// deliberately uses no custom sound so it never depends on a bundled
  /// `res/raw` resource that may be absent.
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
      await _notifier.show(id: id % 100000, title: title, body: body);
    }
  }

  // Backend / FCM ───────────────────────────────────────────────────────────

  final Set<String> _seen = {};

  /// Entry point for backend / FCM `data` payloads (foreground). Dedupes by id,
  /// shows the in-app banner, mirrors to the feed and fires the OS notification
  /// so behaviour matches background/terminated delivery.
  ///
  /// FCM wiring (see NOTIFICATIONS.md):
  ///   FirebaseMessaging.onMessage.listen(
  ///     (m) => NotificationService.to.handleRemoteMessage(m.data));
  void handleRemoteMessage(Map<String, dynamic> data) {
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
      _notifier.show(
        id: n.id.hashCode & 0x7fffffff,
        title: n.title,
        body: n.message,
        sound: n.sound,
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
