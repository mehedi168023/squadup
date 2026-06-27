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

/// Web / no-op implementation. Used when `dart:io` is unavailable (web),
/// where flutter_local_notifications has no platform support.
class LocalNotifier {
  Future<void> init() async {}

  Future<bool> requestPermission() async => true;

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
    // No OS notification on web; the in-app banner/list still records it.
  }
}
