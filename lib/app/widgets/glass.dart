import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// A frosted-glass surface: real Gaussian blur of whatever is behind it, a
/// translucent fill, and a hairline highlight border. The core building block
/// for the app's premium iOS look (app bars, nav, sheets, cards).
///
/// Blur is GPU-cheap at these radii, but each layer is a render-target — use it
/// for chrome and hero surfaces, not for every list row.
class GlassSurface extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? tint;
  final bool border;

  const GlassSurface({
    super.key,
    required this.child,
    this.blur = 18,
    this.opacity = 0.6,
    this.borderRadius,
    this.padding,
    this.tint,
    this.border = true,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.lg);
    final fill =
        (tint ?? Theme.of(context).cardColor).withValues(alpha: opacity);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: radius,
            border: border
                ? Border.all(color: Colors.white.withValues(alpha: 0.08))
                : null,
          ),
          child: padding == null
              ? child
              : Padding(padding: padding!, child: child),
        ),
      ),
    );
  }
}

/// Scales its child down slightly on press for tactile, native-feeling feedback.
/// Wrap any tappable surface that doesn't already animate.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  const PressableScale(
      {super.key, required this.child, this.onTap, this.scale = 0.96});

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;
  void _set(bool v) {
    if (widget.onTap == null) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: AppDurations.fast,
        curve: AppCurves.standard,
        child: widget.child,
      ),
    );
  }
}
