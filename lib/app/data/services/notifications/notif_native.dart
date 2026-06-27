import 'dart:convert';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../core/logger.dart';
import '../../../core/notification_router.dart';

class NotificationAction {
  final String id;
  final String title;
  final String? icon;

  const NotificationAction({
    required this.id,
    required this.title,
    this.icon,
  });
}

/// Mobile implementation backed by flutter_local_notifications.
class LocalNotifier {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    try {
      AppLogger.info('LocalNotifier', 'Initializing FlutterLocalNotificationsPlugin...');
      const android = AndroidInitializationSettings('ic_notification');
      const ios = DarwinInitializationSettings();
      
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      // Create the High Importance Notification Channel programmatically
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      const urgentChannel = AndroidNotificationChannel(
        'urgent_notifications', // id
        'Important Notifications', // name
        description: 'SquadUp critical match room, wallet, and tournament alerts.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
      );
      
      await androidPlugin?.createNotificationChannel(urgentChannel);
      AppLogger.info('LocalNotifier', 'Notification Channel "urgent_notifications" created/verified.');
      _ready = true;
    } catch (e, s) {
      AppLogger.error('LocalNotifier', 'Failed to initialize local notifier', e, s);
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    AppLogger.info('LocalNotifier', 'Notification tapped! actionId: ${response.actionId}, payload: ${response.payload}');
    final payloadStr = response.payload;
    if (payloadStr == null || payloadStr.isEmpty) return;

    try {
      final data = jsonDecode(payloadStr) as Map<String, dynamic>;
      final target = data['target']?.toString();
      final args = data['args'] is Map ? Map<String, dynamic>.from(data['args']) : const <String, dynamic>{};
      
      if (target != null && target.isNotEmpty) {
        NotificationRouter.open(target, args);
      }
    } catch (e, s) {
      AppLogger.error('LocalNotifier', 'Error routing from notification tap', e, s);
    }
  }

  Future<bool> requestPermission() async {
    AppLogger.info('LocalNotifier', 'Requesting system notification permission...');
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
    AppLogger.info('LocalNotifier', 'Notification permission result: $granted');
    return granted ?? true;
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? sound,
    String? image,
    List<NotificationAction>? actions,
    Map<String, dynamic>? payload,
    int? badge,
  }) async {
    await init();

    AppLogger.info('LocalNotifier', 'Showing notification. id: $id, title: "$title"');

    final hasSound = sound != null && sound.isNotEmpty;
    const largeIcon = DrawableResourceAndroidBitmap('ic_launcher');
    
    // Manage styles (BigPictureStyle for images)
    StyleInformation? styleInformation;
    if (image != null && image.isNotEmpty) {
      if (image.startsWith('http')) {
        final localPath = await _downloadAndSaveFile(image, 'notif_img_$id.png');
        if (localPath != null) {
          styleInformation = BigPictureStyleInformation(
            FilePathAndroidBitmap(localPath),
            largeIcon: largeIcon,
            contentTitle: title,
            summaryText: body,
          );
          AppLogger.debug('LocalNotifier', 'Configured BigPictureStyle with downloaded file: $localPath');
        }
      } else {
        styleInformation = BigPictureStyleInformation(
          DrawableResourceAndroidBitmap(image),
          largeIcon: largeIcon,
          contentTitle: title,
          summaryText: body,
        );
        AppLogger.debug('LocalNotifier', 'Configured BigPictureStyle with drawable resource: $image');
      }
    }

    // Map actions
    List<AndroidNotificationAction>? androidActions;
    if (actions != null && actions.isNotEmpty) {
      androidActions = actions.map((act) => AndroidNotificationAction(
        act.id,
        act.title,
        icon: act.icon != null ? DrawableResourceAndroidBitmap(act.icon!) : null,
        showsUserInterface: true,
      )).toList();
    }

    // Android-specific settings
    final androidDetails = AndroidNotificationDetails(
      'urgent_notifications', // Use the high importance channel
      'Important Notifications',
      channelDescription: 'SquadUp critical match room, wallet, and tournament alerts.',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      sound: hasSound ? RawResourceAndroidNotificationSound(sound) : null,
      enableVibration: true,
      enableLights: true,
      visibility: NotificationVisibility.public, // Lock screen visible
      largeIcon: largeIcon,
      styleInformation: styleInformation,
      actions: androidActions,
      number: badge,
    );

    final iosDetails = DarwinNotificationDetails(
      sound: hasSound ? '$sound.aiff' : null,
      presentSound: true,
      presentAlert: true,
      presentBadge: true,
      badgeNumber: badge,
    );

    final payloadStr = payload != null ? jsonEncode(payload) : null;

    try {
      await _plugin.show(
        id,
        title,
        body,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: payloadStr,
      );
      AppLogger.info('LocalNotifier', 'Notification posted successfully.');
    } catch (e, s) {
      AppLogger.error('LocalNotifier', 'Error displaying notification', e, s);
    }
  }

  Future<String?> _downloadAndSaveFile(String url, String fileName) async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode == 200) {
        final tempDir = Directory.systemTemp;
        final filePath = '${tempDir.path}/$fileName';
        final file = File(filePath);
        final bytes = await response.fold<List<int>>([], (p, e) => p..addAll(e));
        await file.writeAsBytes(bytes);
        return filePath;
      }
    } catch (e, s) {
      AppLogger.error('LocalNotifier', 'Failed to download notification image: $url', e, s);
    }
    return null;
  }
}
