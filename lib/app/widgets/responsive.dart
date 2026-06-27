import 'package:flutter/material.dart';

/// Caps content width on large screens (tablets, foldables, landscape) so list
/// and form content stays comfortably readable and centered instead of
/// stretching edge-to-edge. A no-op on phones.
///
/// Wrap the body of a scrollable screen with this; it preserves the child's
/// own padding and scrolling behavior.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const ResponsiveCenter({super.key, required this.child, this.maxWidth = 640});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Layout breakpoints, single source of truth.
class Breakpoints {
  Breakpoints._();
  static const double tablet = 600;
  static const double large = 900;

  static bool isTablet(BuildContext c) => MediaQuery.of(c).size.width >= tablet;
}
