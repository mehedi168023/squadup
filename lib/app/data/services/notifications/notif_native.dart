import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Mobile implementation backed by flutter_local_notifications.
class LocalNotifier {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    const android = AndroidInitializationSettings('@drawable/ic_notification');
    const ios = DarwinInitializationSettings();
    await _plugin
        .initialize(const InitializationSettings(android: android, iOS: ios));
    _ready = true;
  }

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
    return granted ?? true;
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? sound,
  }) async {
    await init();
    final hasSound = sound != null && sound.isNotEmpty;
    // Android plays per-channel sounds, so a custom sound needs its own channel
    // (a bundled raw resource: android/app/src/main/res/raw/<sound>.mp3). When no
    // sound is given, the default channel + default notification sound is used.
    // The app's original (colourful) logo, shown as the notification's large
    // icon. The small status-bar icon is rendered monochrome by Android on all
    // modern devices, so the launcher icon as the *large* icon is the reliable,
    // device-independent way to surface the real brand logo in the shade.
    const largeIcon = DrawableResourceAndroidBitmap('@mipmap/ic_launcher');
    final android = hasSound
        ? AndroidNotificationDetails(
            'squadup_sound_$sound',
            'SquadUp Alerts',
            channelDescription: 'SquadUp tournament alerts',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            sound: RawResourceAndroidNotificationSound(sound),
            largeIcon: largeIcon,
          )
        : const AndroidNotificationDetails(
            'squadup_default',
            'SquadUp',
            channelDescription: 'SquadUp tournament notifications',
            importance: Importance.max,
            priority: Priority.high,
            largeIcon: largeIcon,
          );
    final ios = DarwinNotificationDetails(
      sound: hasSound ? '$sound.aiff' : null,
      presentSound: true,
    );
    try {
      await _plugin.show(
          id, title, body, NotificationDetails(android: android, iOS: ios));
    } catch (_) {
      // Missing custom sound resource / platform quirk — never crash the app.
    }
  }
}
