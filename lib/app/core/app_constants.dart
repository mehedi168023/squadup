/// App-wide constants. Brand is white-label: the deployed instance shows
/// "WAR ZONE" in-app while the store/splash identity is "Play Tour".
class AppConstants {
  AppConstants._();

  static const String appName = 'SquadUp';
  static const String brandName = 'SquadUp';
  static const String tagline = 'Tournament';
  static const String appVersion = '1.0.0';

  /// Bangladeshi Taka symbol used throughout the UI.
  static const String currency = '৳'; // ৳

  // Brand assets (extracted from the original APK).
  static const String logo = 'assets/images/logo.webp';
  static const String freefireLogo = 'assets/images/freefire_logo.webp';
  static const String ludoClassic = 'assets/images/ludo_classic.webp';
  static const String ludoAuto = 'assets/images/ludo_auto.webp';
  static const String ffTopup = 'assets/images/ff_topup.webp';
  static const String ludoKingpass = 'assets/images/ludo_kingpass.webp';
  static const String ludoUidGuide = 'assets/images/ludo_uid_guide.webp';
  // Banners.
  static const String shopProductsBanner = 'assets/images/shop_products.webp';
  static const String shopTopupBanner = 'assets/images/shop_topup.webp';
  static const String bannerAddMoney = 'assets/images/banner_admoney.webp';
  static const String bannerHowToPlay = 'assets/images/banner_howtoplay.webp';
  static const String bannerJoinGroup = 'assets/images/banner_joingroup.webp';

  // Gaming store (e-commerce) — category logo + product images.
  static const String shopGamingLogo = 'assets/images/shop_gaming_logo.webp';
  static const String productMouseVx7 = 'assets/images/product_mouse_vx7.webp';
  static const String productHeadsetKraken =
      'assets/images/product_headset_kraken.webp';
  static const String productMouseVx9 = 'assets/images/product_mouse_vx9.webp';
  static const String productKeyboardAtom63 =
      'assets/images/product_keyboard_atom63.webp';
  static const String productGamepadShooter3 =
      'assets/images/product_gamepad_shooter3.webp';

  /// Demo credentials shown on the login screen (mock auth).
  static const String demoEmail = 'demo@squadup.gg';
  static const String demoPassword = 'play1234';
}

/// Formats an amount with the Taka symbol, e.g. `৳1,250`.
String taka(num value) {
  final s = value.toStringAsFixed(0);
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return '${AppConstants.currency}$buf';
}

const List<String> _kMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];
const List<String> _kWeekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday'
];

/// Compact date + 12h time, e.g. `5 Jan, 3:45 PM` (replaces intl's DateFormat).
String shortDateTime(DateTime d) {
  final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final ampm = d.hour < 12 ? 'AM' : 'PM';
  final m = d.minute.toString().padLeft(2, '0');
  return '${d.day} ${_kMonths[d.month - 1]}, $h12:$m $ampm';
}

/// Full date with weekday, e.g. `5 Jan 2026 · Monday`.
String fullDateWeekday(DateTime d) =>
    '${d.day} ${_kMonths[d.month - 1]} ${d.year} · ${_kWeekdays[d.weekday - 1]}';
