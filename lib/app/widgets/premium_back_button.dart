import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A premium app-bar back button: a compact, rounded, bordered surface tile with
/// an iOS-style chevron, a press ripple and light haptic feedback. Used as the
/// `leading` on every pushed screen for a consistent, polished look.
///
/// Safely no-ops (renders nothing) when there's no route to pop, so it can be
/// dropped onto any AppBar without guarding.
class PremiumBackButton extends StatelessWidget {
  /// Optional custom handler; defaults to popping the current route.
  final VoidCallback? onTap;
  const PremiumBackButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final canPop = onTap != null || Navigator.of(context).canPop();
    if (!canPop) return const SizedBox.shrink();
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.sm),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              HapticFeedback.lightImpact();
              if (onTap != null) {
                onTap!();
              } else {
                Get.back();
              }
            },
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.cSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.cBorder),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 17, color: context.cText),
            ),
          ),
        ),
      ),
    );
  }
}
