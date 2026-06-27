import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// Centralized motion system (Material Motion, hand-rolled — no extra deps).
///
/// Every page route picks ONE of these transitions based on its navigational
/// relationship (see [AppPages]). The three core patterns mirror Google's
/// Material Motion spec and the behaviour of the `animations` package, but are
/// implemented in pure Dart so the app keeps its zero-extra-dependency, small
/// APK discipline:
///
///   • [SharedAxisXTransition]  — hierarchical drill / steps / checkout (→ ←)
///   • [SharedAxisYTransition]  — modal surfaces that rise up (↑)
///   • [FadeThroughTransition]  — switching unrelated content (auth/settings)
///   • [FadeScaleTransition]    — arriving "home", surfacing the dashboard
///
/// All four are stateless and share one reusable instance per pattern, so
/// there is no duplicated per-page animation code. GetX hands each its own
/// `animation` (this page entering) and `secondaryAnimation` (this page being
/// covered by a newer one), so back-navigation and the iOS edge-swipe both
/// reverse correctly and stay at 60fps.
/// ─────────────────────────────────────────────────────────────────────────

/// Motion tokens — durations stay inside the premium 220–300ms band, with one
/// emphasized curve used everywhere for platform-consistent feel.
class AppMotion {
  AppMotion._();

  /// Light, lateral swaps and drills.
  static const Duration drill = Duration(milliseconds: 260);

  /// Arriving at / leaving a top-level surface, or a modal rising up.
  static const Duration emphasized = Duration(milliseconds: 300);

  /// Material's standard easing — accelerate out, decelerate in.
  static const Curve curve = Curves.fastOutSlowIn;

  /// Shared-axis spatial shift, in logical pixels (Material spec: 30dp).
  static const double shift = 30.0;
}

// ── Shared Axis ────────────────────────────────────────────────────────────

enum _SharedAxisDir { horizontal, vertical }

/// Material "shared axis" — the entering and outgoing pages slide together
/// along one axis while cross-fading, communicating a clear forward/back
/// (or up/down) spatial relationship.
class _SharedAxis extends StatelessWidget {
  const _SharedAxis({
    required this.animation,
    required this.secondaryAnimation,
    required this.dir,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final _SharedAxisDir dir;
  final Widget child;

  Offset _offset(double v) =>
      dir == _SharedAxisDir.horizontal ? Offset(v, 0) : Offset(0, v);

  @override
  Widget build(BuildContext context) {
    // Outer builder drives THIS page entering/leaving via `animation`;
    // inner builder drives it being covered/uncovered via `secondaryAnimation`.
    return DualTransitionBuilder(
      animation: animation,
      forwardBuilder: (_, anim, child) => _enter(anim, child!, reverse: false),
      reverseBuilder: (_, anim, child) => _exit(anim, child!, reverse: true),
      child: DualTransitionBuilder(
        animation: ReverseAnimation(secondaryAnimation),
        forwardBuilder: (_, anim, child) => _enter(anim, child!, reverse: true),
        reverseBuilder: (_, anim, child) => _exit(anim, child!, reverse: false),
        child: child,
      ),
    );
  }

  /// Page coming in: slide from the offset to rest + fade in (late, 0.3→1.0).
  Widget _enter(Animation<double> anim, Widget child, {required bool reverse}) {
    final begin = reverse ? -AppMotion.shift : AppMotion.shift;
    final position = Tween<Offset>(begin: _offset(begin), end: Offset.zero)
        .chain(CurveTween(curve: AppMotion.curve))
        .animate(anim);
    final opacity =
        CurveTween(curve: const Interval(0.30, 1.0)).animate(anim);
    return _slideFade(position, opacity, child);
  }

  /// Page going away: slide to the opposite offset + fade out (early, 0→0.3).
  Widget _exit(Animation<double> anim, Widget child, {required bool reverse}) {
    final end = reverse ? AppMotion.shift : -AppMotion.shift;
    final position = Tween<Offset>(begin: Offset.zero, end: _offset(end))
        .chain(CurveTween(curve: AppMotion.curve))
        .animate(anim);
    final opacity = Tween<double>(begin: 1, end: 0)
        .chain(CurveTween(curve: const Interval(0.0, 0.30)))
        .animate(anim);
    return _slideFade(position, opacity, child);
  }

  Widget _slideFade(
      Animation<Offset> position, Animation<double> opacity, Widget child) {
    return FadeTransition(
      opacity: opacity,
      child: AnimatedBuilder(
        animation: position,
        builder: (_, c) => Transform.translate(offset: position.value, child: c),
        child: child,
      ),
    );
  }
}

// ── Fade Through ───────────────────────────────────────────────────────────

/// Material "fade through" — outgoing content fades out, then incoming content
/// fades in while scaling up from 92%. For UI with no spatial relationship
/// (auth, settings, reference/result screens).
class _FadeThrough extends StatelessWidget {
  const _FadeThrough({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DualTransitionBuilder(
      animation: animation,
      forwardBuilder: (_, anim, child) => _enter(anim, child!),
      reverseBuilder: (_, anim, child) => _exit(anim, child!),
      child: DualTransitionBuilder(
        animation: ReverseAnimation(secondaryAnimation),
        forwardBuilder: (_, anim, child) => _enter(anim, child!),
        reverseBuilder: (_, anim, child) => _exit(anim, child!),
        child: child,
      ),
    );
  }

  Widget _enter(Animation<double> anim, Widget child) {
    final opacity =
        CurveTween(curve: const Interval(0.35, 1.0)).animate(anim);
    final scale = Tween<double>(begin: 0.92, end: 1.0)
        .chain(CurveTween(curve: AppMotion.curve))
        .animate(anim);
    return FadeTransition(
      opacity: opacity,
      child: ScaleTransition(scale: scale, child: child),
    );
  }

  Widget _exit(Animation<double> anim, Widget child) {
    final opacity = Tween<double>(begin: 1, end: 0)
        .chain(CurveTween(curve: const Interval(0.0, 0.35)))
        .animate(anim);
    return FadeTransition(opacity: opacity, child: child);
  }
}

// ── Fade + Scale ───────────────────────────────────────────────────────────

/// "Fade + Scale" — the surface fades in while gently scaling up from 94%,
/// like content surfacing. Used when arriving at the home/dashboard shell.
class _FadeScale extends StatelessWidget {
  const _FadeScale({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Entering: fade + scale up. Being covered: recede slightly (scale down +
    // dim) so a pushed child reads as floating above the dashboard.
    final enter = CurvedAnimation(parent: animation, curve: AppMotion.curve);
    final cover = CurvedAnimation(
      parent: secondaryAnimation,
      curve: AppMotion.curve,
      reverseCurve: AppMotion.curve.flipped,
    );
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.6).animate(cover),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1, end: 0.96).animate(cover),
        child: FadeTransition(
          opacity: enter,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(enter),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ── Zoom (shared axis Z) ────────────────────────────────────────────────────

/// Premium "zoom" page transition (Material shared-axis Z). The incoming page
/// scales up from 90% while fading in; the outgoing page scales up past 100% and
/// fades out — a soft depth-zoom that reads as "moving forward/inward". Used as
/// the app-wide DEFAULT navigation motion.
class _Zoom extends StatelessWidget {
  const _Zoom({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  static const double _enterFrom = 0.90; // incoming starts slightly smaller
  static const double _exitTo = 1.08; // outgoing pushes slightly larger

  @override
  Widget build(BuildContext context) {
    return DualTransitionBuilder(
      animation: animation,
      forwardBuilder: (_, anim, child) => _enter(anim, child!, reverse: false),
      reverseBuilder: (_, anim, child) => _exit(anim, child!, reverse: true),
      child: DualTransitionBuilder(
        animation: ReverseAnimation(secondaryAnimation),
        forwardBuilder: (_, anim, child) => _enter(anim, child!, reverse: true),
        reverseBuilder: (_, anim, child) => _exit(anim, child!, reverse: false),
        child: child,
      ),
    );
  }

  /// Page appearing: scale up to rest + fade in (late, 0.3→1.0).
  Widget _enter(Animation<double> anim, Widget child, {required bool reverse}) {
    final begin = reverse ? _exitTo : _enterFrom;
    final scale = Tween<double>(begin: begin, end: 1.0)
        .chain(CurveTween(curve: AppMotion.curve))
        .animate(anim);
    final opacity =
        CurveTween(curve: const Interval(0.30, 1.0)).animate(anim);
    return _scaleFade(scale, opacity, child);
  }

  /// Page leaving: scale away from rest + fade out (early, 0→0.3).
  Widget _exit(Animation<double> anim, Widget child, {required bool reverse}) {
    final end = reverse ? _enterFrom : _exitTo;
    final scale = Tween<double>(begin: 1.0, end: end)
        .chain(CurveTween(curve: AppMotion.curve))
        .animate(anim);
    final opacity = Tween<double>(begin: 1, end: 0)
        .chain(CurveTween(curve: const Interval(0.0, 0.30)))
        .animate(anim);
    return _scaleFade(scale, opacity, child);
  }

  Widget _scaleFade(
          Animation<double> scale, Animation<double> opacity, Widget child) =>
      FadeTransition(
        opacity: opacity,
        child: ScaleTransition(scale: scale, child: child),
      );
}

// ── GetX CustomTransition adapters (one reusable instance each) ─────────────

class ZoomTransition extends CustomTransition {
  @override
  Widget buildTransition(BuildContext context, Curve? curve, Alignment? align,
          Animation<double> animation, Animation<double> secondary, Widget child) =>
      _Zoom(
          animation: animation, secondaryAnimation: secondary, child: child);
}

class SharedAxisXTransition extends CustomTransition {
  @override
  Widget buildTransition(BuildContext context, Curve? curve, Alignment? align,
          Animation<double> animation, Animation<double> secondary, Widget child) =>
      _SharedAxis(
          animation: animation,
          secondaryAnimation: secondary,
          dir: _SharedAxisDir.horizontal,
          child: child);
}

class SharedAxisYTransition extends CustomTransition {
  @override
  Widget buildTransition(BuildContext context, Curve? curve, Alignment? align,
          Animation<double> animation, Animation<double> secondary, Widget child) =>
      _SharedAxis(
          animation: animation,
          secondaryAnimation: secondary,
          dir: _SharedAxisDir.vertical,
          child: child);
}

class FadeThroughTransition extends CustomTransition {
  @override
  Widget buildTransition(BuildContext context, Curve? curve, Alignment? align,
          Animation<double> animation, Animation<double> secondary, Widget child) =>
      _FadeThrough(
          animation: animation, secondaryAnimation: secondary, child: child);
}

class FadeScaleTransition extends CustomTransition {
  @override
  Widget buildTransition(BuildContext context, Curve? curve, Alignment? align,
          Animation<double> animation, Animation<double> secondary, Widget child) =>
      _FadeScale(
          animation: animation, secondaryAnimation: secondary, child: child);
}

/// Shared, reusable transition instances — referenced by [AppPages]. Stateless,
/// so a single instance per pattern is safe across every route.
class AppTransitions {
  AppTransitions._();

  static final zoom = ZoomTransition();
  static final sharedAxisX = SharedAxisXTransition();
  static final sharedAxisY = SharedAxisYTransition();
  static final fadeThrough = FadeThroughTransition();
  static final fadeScale = FadeScaleTransition();
}
