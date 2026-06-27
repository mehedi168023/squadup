import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';

/// Holds the active [ThemeMode] and persists the user's choice.
class ThemeController extends GetxController {
  static ThemeController get to => Get.find();

  static const _key = 'theme_mode';
  final Rx<ThemeMode> mode = ThemeMode.dark.obs;

  bool get isDark => mode.value == ThemeMode.dark;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved == 'light') mode.value = ThemeMode.light;
    _applySystemUi();
  }

  Future<void> toggle() async {
    mode.value = isDark ? ThemeMode.light : ThemeMode.dark;
    Get.changeThemeMode(mode.value);
    _applySystemUi();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, isDark ? 'dark' : 'light');
  }

  /// Keeps the system status/navigation bars in sync with the active theme.
  void _applySystemUi() {
    final dark = isDark;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: dark ? AppColors.bg : AppColors.lightBg,
      systemNavigationBarIconBrightness:
          dark ? Brightness.light : Brightness.dark,
    ));
  }
}
