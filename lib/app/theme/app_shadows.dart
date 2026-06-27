import 'package:flutter/material.dart';

/// Elevation / shadow tokens. Kept soft and low-opacity for the premium
/// "floating surface" look without heavy overdraw.
class AppShadows {
  AppShadows._();

  /// Resting card elevation — subtle lift off the background.
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 14,
      spreadRadius: -6,
      offset: Offset(0, 6),
    ),
  ];

  /// Raised surfaces (sheets, dialogs, floating nav).
  static const List<BoxShadow> raised = [
    BoxShadow(
      color: Color(0x4D000000),
      blurRadius: 28,
      spreadRadius: -8,
      offset: Offset(0, 12),
    ),
  ];

  /// Colored outer glow matching a button/accent fill.
  static List<BoxShadow> glow(Color color, {double opacity = 0.4}) => [
        BoxShadow(
          color: color.withValues(alpha: opacity),
          blurRadius: 18,
          spreadRadius: -4,
          offset: const Offset(0, 6),
        ),
      ];
}
