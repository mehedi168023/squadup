import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/logger.dart';
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

    AppLogger.info('PermissionService', 'Requesting all runtime permissions...');

    // OS notification permission (Android 13+, iOS, browser on web).
    await _safe(() async {
      AppLogger.info('PermissionService', 'Requesting OS Notification Permission...');
      await NotificationService.to.requestOsPermission();
      final status = await Permission.notification.request();
      AppLogger.info('PermissionService', 'Notification Permission Status: $status');
    });

    // File / image permission — Android photos (13+) and legacy storage.
    if (!kIsWeb) {
      await _safe(() async {
        AppLogger.info('PermissionService', 'Requesting Photos & Storage Permissions...');
        final photos = await Permission.photos.request();
        final storage = await Permission.storage.request();
        AppLogger.info('PermissionService', 'Photos: $photos, Storage: $storage');
      });
    }
  }

  /// Checks if battery optimizations are ignored (meaning the app runs freely in background).
  Future<bool> isBatteryOptimizationIgnored() async {
    if (kIsWeb) return true;
    final isIgnored = await Permission.ignoreBatteryOptimizations.isGranted;
    AppLogger.debug('PermissionService', 'Is Battery Optimization Ignored: $isIgnored');
    return isIgnored;
  }

  /// Requests the user to ignore battery optimizations for SquadUp.
  Future<bool> requestDisableBatteryOptimization() async {
    if (kIsWeb) return true;
    AppLogger.info('PermissionService', 'Requesting battery optimization exemption...');
    final result = await Permission.ignoreBatteryOptimizations.request();
    AppLogger.info('PermissionService', 'Battery optimization request result: $result');
    return result.isGranted;
  }

  Future<void> _safe(Future<void> Function() action) async {
    try {
      await action();
    } catch (e, s) {
      AppLogger.error('PermissionService', 'Error requesting permission', e, s);
    }
  }
}
