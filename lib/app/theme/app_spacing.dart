import 'package:flutter/animation.dart';

/// Spacing scale (4-pt grid). Use these instead of ad-hoc magic numbers so the
/// whole app shares one vertical/horizontal rhythm.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;
}

/// Corner-radius scale. `pill` is effectively fully rounded.
class AppRadius {
  AppRadius._();

  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double pill = 999;
}

/// Motion tokens — one source of truth for animation timing so transitions feel
/// consistent and native across the app.
class AppDurations {
  AppDurations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 360);
}

/// Easing curves. `spring` gives the gentle iOS overshoot used on press/scale.
class AppCurves {
  AppCurves._();

  static const Curve standard = Curves.easeOutCubic;
  static const Curve spring = Curves.easeOutBack;
  static const Curve emphasized = Curves.fastOutSlowIn;
}
