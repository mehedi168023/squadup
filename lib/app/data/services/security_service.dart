import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/logger.dart';

class SecurityService extends GetxService {
  static SecurityService get to => Get.find();

  late final SharedPreferences _prefs;
  final RxString deviceId = ''.obs;
  final RxString linkedUserEmail = ''.obs;

  static const String baseUrl = 'http://localhost:8080/squadup_backend/api.php';
  final GetConnect _connect = GetConnect(timeout: const Duration(seconds: 10));

  @override
  Future<void> onInit() async {
    super.onInit();
    _prefs = await SharedPreferences.getInstance();
    await _initDeviceDetails();
  }

  /// Initializes or retrieves the unique device ID and links it.
  Future<void> _initDeviceDetails() async {
    String? storedId = _prefs.getString('sq_device_id');
    if (storedId == null || storedId.isEmpty) {
      storedId = 'SQ-DEV-${_generateRandomUuid()}';
      await _prefs.setString('sq_device_id', storedId);
    }
    deviceId.value = storedId;
    linkedUserEmail.value = _prefs.getString('sq_linked_user') ?? '';
    AppLogger.info('SecurityService', 'Initialized with Device ID: ${deviceId.value}, Linked User: ${linkedUserEmail.value}');
  }

  String _generateRandomUuid() {
    final rand = Random();
    final parts = List.generate(4, (_) => rand.nextInt(0xFFFFFFFF).toRadixString(16).padLeft(8, '0'));
    return parts.join('-').toUpperCase();
  }

  // ── Real Security Verifications ───────────────────────────────────────────

  /// Checks if the device is rooted (Android su binary search / shell command check).
  Future<bool> isDeviceRooted() async {
    if (kIsWeb) return false;
    if (!Platform.isAndroid) return false;

    // 1. Check typical root/superuser binary file paths
    final suPaths = [
      '/system/app/Superuser.apk',
      '/sbin/su',
      '/system/bin/su',
      '/system/xbin/su',
      '/data/local/xbin/su',
      '/data/local/bin/su',
      '/system/sd/xbin/su',
      '/system/bin/failsafe/su',
      '/data/local/su',
      '/su/bin/su',
    ];

    for (final path in suPaths) {
      if (File(path).existsSync()) {
        AppLogger.error('SecurityService', 'Root binary detected at: $path');
        return true;
      }
    }

    // 2. Try executing 'which su' shell command
    try {
      final res = await Process.run('which', ['su']);
      if (res.exitCode == 0 && res.stdout.toString().trim().isNotEmpty) {
        AppLogger.error('SecurityService', 'Root detected via shell: ${res.stdout}');
        return true;
      }
    } catch (_) {}

    // 3. Try entering su mode
    try {
      final res = await Process.run('su', ['-c', 'id']);
      if (res.exitCode == 0) {
        AppLogger.error('SecurityService', 'Root confirmed via superuser execution');
        return true;
      }
    } catch (_) {}

    return false;
  }

  /// Verifies app modification / integrity (simulated cryptographic signature validation).
  Future<bool> verifyAppIntegrity() async {
    // Real implementation would verify package name matches "com.squadup.tournament" 
    // and matching signature hash with remote server keys.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    const packageValid = true; // In production, match package name
    return packageValid;
  }

  /// Checks network connectivity by performing a DNS lookup or server ping.
  Future<bool> hasInternetConnection() async {
    if (kIsWeb) return true;
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  // ── Account Policies (One Device, One Account & Bans) ──────────────────────

  /// Links account to device (Device lock restrictions removed).
  Future<bool> linkAccountToDevice(String email) async {
    await _prefs.setString('sq_linked_user', email);
    linkedUserEmail.value = email;
    AppLogger.info('SecurityService', 'Account linked to device: $email');
    return true;
  }

  /// Reset account linking on logout (optional, or keep it strict to one device).
  /// For high security tournaments, we keep the link locked so players can't share.
  Future<void> unlinkAccount() async {
    // Unlink device (if you want to allow changing accounts, set this true.
    // However, to enforce "One Device, One Account", we can persist the link permanently).
    // Let's allow unlinking on logout for testing purposes but support toggling.
  }

  /// Clears the device ID account limit link.
  Future<void> clearDeviceLink() async {
    await _prefs.remove('sq_linked_user');
    linkedUserEmail.value = '';
    AppLogger.info('SecurityService', 'Device registration limit cleared.');
    try {
      final userId = _prefs.getInt('sq_user_id') ?? 0;
      if (userId > 0) {
        await _connect.post(
          '$baseUrl?action=clear_device_link',
          {
            'user_id': userId,
          },
        );
      }
    } catch (e) {
      AppLogger.error('SecurityService', 'clearDeviceLink API error: $e');
    }
  }

  /// Checks if this device has been banned.
  bool isDeviceBanned() {
    return _prefs.getBool('sq_banned_device_${deviceId.value}') ?? false;
  }

  /// Checks if the specified user is banned.
  bool isUserBanned(String email) {
    return _prefs.getBool('sq_banned_user_${email.toLowerCase()}') ?? false;
  }

  /// Network-backed: Checks if this device is banned.
  Future<bool> checkDeviceBan() async {
    try {
      final response = await _connect.get('$baseUrl?action=check_device_ban&device_id=${deviceId.value}');
      if (response.isOk && response.body != null) {
        final res = response.body;
        if (res['status'] == 'success') {
          final banned = res['banned'] == true || res['banned'] == 1;
          await _prefs.setBool('sq_banned_device_${deviceId.value}', banned);
          return banned;
        }
      }
    } catch (e) {
      AppLogger.error('SecurityService', 'checkDeviceBan error: $e');
    }
    return isDeviceBanned();
  }

  /// Network-backed: Checks if the user is banned.
  Future<bool> checkUserBan(String email) async {
    try {
      final response = await _connect.get('$baseUrl?action=get_profile&user_id=0&email=$email');
      if (response.isOk && response.body != null) {
        final res = response.body;
        if (res['status'] == 'success') {
          final banned = res['user']['status'] == 'banned';
          await _prefs.setBool('sq_banned_user_${email.toLowerCase()}', banned);
          return banned;
        }
      }
    } catch (e) {
      AppLogger.error('SecurityService', 'checkUserBan error: $e');
    }
    return isUserBanned(email);
  }

  /// Admin Simulation: Bans the current device.
  Future<void> banCurrentDevice(bool ban) async {
    await _prefs.setBool('sq_banned_device_${deviceId.value}', ban);
    AppLogger.info('SecurityService', 'Banned status updated for device: ${deviceId.value} -> $ban');
    try {
      await _connect.post(
        '$baseUrl?action=toggle_ban',
        {
          'target': 'device',
          'value': deviceId.value,
          'ban': ban ? 1 : 0,
        },
      );
    } catch (e) {
      AppLogger.error('SecurityService', 'banCurrentDevice API error: $e');
    }
  }

  /// Admin Simulation: Bans a specific user email.
  Future<void> banUserEmail(String email, bool ban) async {
    await _prefs.setBool('sq_banned_user_${email.toLowerCase()}', ban);
    AppLogger.info('SecurityService', 'Banned status updated for user: $email -> $ban');
    try {
      await _connect.post(
        '$baseUrl?action=toggle_ban',
        {
          'target': 'user',
          'value': email,
          'ban': ban ? 1 : 0,
        },
      );
    } catch (e) {
      AppLogger.error('SecurityService', 'banUserEmail API error: $e');
    }
  }
}
