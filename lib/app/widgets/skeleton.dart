import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A lightweight shimmer skeleton — a single repeating gradient sweep, no extra
/// package. Use to fill the screen while data loads instead of a bare spinner.
class Skeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;
  const Skeleton(
      {super.key, this.width, this.height = 16, this.radius = AppRadius.sm});

  /// A circular skeleton (avatars, icon tiles).
  const Skeleton.circle(double size, {super.key})
      : width = size,
        height = size,
        radius = AppRadius.pill;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final t = _c.value;
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius),
              gradient: LinearGradient(
                begin: Alignment(-1 - 2 * (1 - t), 0),
                end: Alignment(1 - 2 * (1 - t), 0),
                colors: const [
                  AppColors.surface,
                  AppColors.surfaceAlt,
                  AppColors.surface,
                ],
                stops: const [0.35, 0.5, 0.65],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A reusable, premium-feeling [AnimatedCrossFade] for smooth UI state swaps —
/// loading↔content, error↔content, empty↔content, etc. Both children are kept
/// the same logical size, so this is meant for bounded content (a field, a card,
/// a section) — not full-page scrollables. 300ms / easeInOutCubic by default.
class CrossFade extends StatelessWidget {
  /// When true, [first] is shown; otherwise [second]. (e.g. first = skeleton.)
  final bool showFirst;
  final Widget first;
  final Widget second;
  final Duration duration;
  final Alignment alignment;

  const CrossFade({
    super.key,
    required this.showFirst,
    required this.first,
    required this.second,
    this.duration = const Duration(milliseconds: 300),
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      duration: duration,
      firstChild: first,
      secondChild: second,
      alignment: alignment,
      firstCurve: Curves.easeInOutCubic,
      secondCurve: Curves.easeInOutCubic,
      sizeCurve: Curves.easeInOutCubic,
      crossFadeState:
          showFirst ? CrossFadeState.showFirst : CrossFadeState.showSecond,
    );
  }
}

/// A column of skeleton "cards" — a ready-made list/grid placeholder.
class SkeletonList extends StatelessWidget {
  final int count;
  final double itemHeight;
  const SkeletonList({super.key, this.count = 4, this.itemHeight = 92});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, __) =>
          Skeleton(height: itemHeight, radius: AppRadius.lg),
    );
  }
}
