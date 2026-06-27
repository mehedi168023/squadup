import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Ambient background for the auth screens: a deep vertical gradient with two
/// soft, blurred color glows. Static (no animation) so it costs nothing to
/// composite and never competes with foreground interactions.
class AuthBackdrop extends StatelessWidget {
  const AuthBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [context.cBgAlt, context.cBg],
          ),
        ),
        child: const Stack(
          children: [
            _Glow(
                alignment: Alignment(-0.9, -0.85),
                color: AppColors.primary,
                size: 280),
            _Glow(
                alignment: Alignment(1.0, 0.6),
                color: AppColors.winningTeal,
                size: 240),
          ],
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final Alignment alignment;
  final Color color;
  final double size;
  const _Glow(
      {required this.alignment, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.18), Colors.transparent],
          ),
        ),
      ),
    );
  }
}
