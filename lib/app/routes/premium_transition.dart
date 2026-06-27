import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

/// App-wide premium page transition (the app's original, default navigation
/// motion — used by every route EXCEPT Login→Home).
///
/// The incoming screen fades in while scaling up from 96% with a subtle
/// rightward slide; the outgoing screen slides left, dims and scales down a
/// touch — giving navigation a layered, depth-of-field feel instead of a flat
/// push. The [child] already carries GetX's iOS back-swipe detector, so the
/// edge-swipe-to-go-back gesture is preserved.
class PremiumPageTransition extends CustomTransition {
  PremiumPageTransition();

  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final enter = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final leave = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    // Outgoing layer: as a newer page covers this one, push it back for depth.
    final content = SlideTransition(
      position:
          Tween(begin: Offset.zero, end: const Offset(-0.16, 0)).animate(leave),
      child: ScaleTransition(
        scale: Tween(begin: 1.0, end: 0.94).animate(leave),
        child: FadeTransition(
          opacity: Tween(begin: 1.0, end: 0.55).animate(leave),
          child: child,
        ),
      ),
    );

    // Incoming layer: fade + scale-up + subtle slide.
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
      child: SlideTransition(
        position:
            Tween(begin: const Offset(0.05, 0), end: Offset.zero).animate(enter),
        child: ScaleTransition(
          scale: Tween(begin: 0.96, end: 1.0).animate(enter),
          child: content,
        ),
      ),
    );
  }
}
