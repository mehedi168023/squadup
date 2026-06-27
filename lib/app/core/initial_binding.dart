import 'package:get/get.dart';
import '../data/services/notification_service.dart';
import '../data/services/permission_service.dart';
import '../data/services/session_service.dart';
import 'theme_controller.dart';

/// Registers the always-on services before the first screen builds.
///
/// All backend-only services (REST client, token store, Socket.IO realtime, FCM
/// push) have been removed — the app now runs entirely on local mock data.
/// Only the theme, session, notification and permission services remain.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<SessionService>()) return;

    Get.put(ThemeController(), permanent: true);
    Get.put(SessionService(), permanent: true);
    Get.put(NotificationService(), permanent: true);
    Get.put(PermissionService(), permanent: true);
  }
}
