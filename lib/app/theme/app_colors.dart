import 'package:flutter/material.dart';

/// Palette measured directly from the original app screenshots (DESIGN_DETAILS Part B).
class AppColors {
  AppColors._();

  // Backgrounds (dark)
  static const Color bg = Color(0xFF0B1119);
  static const Color bgAlt = Color(0xFF0E1420);
  static const Color surface = Color(0xFF131C2B);
  static const Color surfaceAlt = Color(0xFF182234);
  static const Color border = Color(0xFF1E2A3D);

  // Brand / primary
  static const Color primary = Color(0xFF2F6BFF);
  static const Color primaryDeep = Color(0xFF3B6FE5);
  static const Color primarySoft = Color(0x332F6BFF);

  // Semantic
  static const Color success = Color(0xFF16A34A);
  static const Color successDeep = Color(0xFF0E7A38);
  static const Color winningTeal = Color(0xFF2BD9A0);
  static const Color danger = Color(0xFFD33B3B);
  static const Color dangerDeep = Color(0xFFC42B2B);

  // Accents
  static const Color gold = Color(0xFFF5B71E);
  static const Color silver = Color(0xFFAEB6C2);
  static const Color bronze = Color(0xFFC77B3C);
  static const Color killRed = Color(0xFFFF4D6A);
  static const Color matchesGreen = Color(0xFF2ECC71);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8A93A5);
  static const Color textMuted = Color(0xFF5E6878);

  // Light theme
  static const Color lightBg = Color(0xFFF4F6FB);
  static const Color lightBgAlt = Color(0xFFE9EEF6);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFEEF2F8);
  static const Color lightBorder = Color(0xFFDDE3EE);
  static const Color lightTextPrimary = Color(0xFF0E1726);
  static const Color lightTextSecondary = Color(0xFF5B6678);
  static const Color lightTextMuted = Color(0xFF94A0B3);

  // Gradients
  static const List<Color> greenGradient = [
    Color(0xFF1BC257),
    Color(0xFF12A148)
  ];
  static const List<Color> redGradient = [Color(0xFFE0444A), Color(0xFFC42B2B)];
  static const List<Color> blueGradient = [
    Color(0xFF3B82F6),
    Color(0xFF2F6BFF)
  ];
}

/// Theme-aware ("contextual") colors. Use these in custom containers instead of
/// the raw dark `AppColors.*` so surfaces, borders and text adapt to light mode.
/// Accent colors (primary/gold/danger/etc.) stay the same in both themes.
extension AppColorsX on BuildContext {
  bool get _dark => Theme.of(this).brightness == Brightness.dark;

  Color get cBg => _dark ? AppColors.bg : AppColors.lightBg;
  Color get cBgAlt => _dark ? AppColors.bgAlt : AppColors.lightBgAlt;
  Color get cSurface => _dark ? AppColors.surface : AppColors.lightSurface;
  Color get cSurfaceAlt =>
      _dark ? AppColors.surfaceAlt : AppColors.lightSurfaceAlt;
  Color get cBorder => _dark ? AppColors.border : AppColors.lightBorder;
  Color get cText => _dark ? AppColors.textPrimary : AppColors.lightTextPrimary;
  Color get cTextDim =>
      _dark ? AppColors.textSecondary : AppColors.lightTextSecondary;
  Color get cTextMuted =>
      _dark ? AppColors.textMuted : AppColors.lightTextMuted;
}
