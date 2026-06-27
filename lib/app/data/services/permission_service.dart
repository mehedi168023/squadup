import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'notification_service.dart';

/// Requests the runtime permissions the app uses: OS notifications (for the
/// notification system) and photos/storage (for notification banner images and
/// future media features). Every call is wrapped so a denial — or an
/// unsupported-on-web platform — never crashes the app.
class PermissionService extends GetxService {
  static PermissionService get to => Get.find();

  final RxBool requested = false.obs;

  /// Called once after the user enters the app. Best-effort on every platform.
  Future<void> requestAll() async {
    if (requested.value) return;
    requested.value = true;

    // OS notification permission (Android 13+, iOS, browser on web).
    await _safe(() async {
      await NotificationService.to.requestOsPermission();
      await Permission.notification.request();
    });

    // File / image permission — Android photos (13+) and legacy storage.
    if (!kIsWeb) {
      await _safe(() => Permission.photos.request());
      await _safe(() => Permission.storage.request());
    }
  }

  Future<void> _safe(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Permission unsupported / denied / unavailable — ignore, never crash.
    }
  }
}
