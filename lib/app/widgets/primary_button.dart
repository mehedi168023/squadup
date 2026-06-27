import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum ButtonVariant { blue, green, red }

/// Full-width gradient action button with a soft outer glow matching its fill.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final double height;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ButtonVariant.blue,
    this.icon,
    this.loading = false,
    this.height = 48,
  });

  List<Color> get _gradient => switch (variant) {
        ButtonVariant.green => AppColors.greenGradient,
        ButtonVariant.red => AppColors.redGradient,
        ButtonVariant.blue => AppColors.blueGradient,
      };

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: _gradient),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _gradient.last.withValues(alpha: 0.40),
                blurRadius: 14,
                spreadRadius: -4,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: Colors.white),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                      ],
                      Text(label,
                          style: AppTextStyles.button
                              .copyWith(color: Colors.white)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
