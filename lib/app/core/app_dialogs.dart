import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/glass.dart';

/// iOS-style confirm/alert dialogs, themed (light + dark) to match the app.
/// Replaces raw Material `AlertDialog` for a flagship feel.
class AppDialogs {
  AppDialogs._();

  /// A confirm dialog. Resolves `true` when the action button is tapped,
  /// `false` (or null → treat as false) otherwise.
  static Future<bool> confirm({
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool destructive = false,
  }) async {
    final result = await Get.dialog<bool>(
      _ConfirmDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        destructive: destructive,
      ),
      barrierColor: Colors.black.withValues(alpha: 0.55),
    );
    return result ?? false;
  }
}

class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final bool destructive;

  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmText,
    required this.cancelText,
    required this.destructive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = destructive ? AppColors.danger : AppColors.primary;
    final textColor = theme.textTheme.bodyLarge?.color;
    // A solid, theme-aware card (no BackdropFilter) — the blur used to flash
    // during the dialog's open/close transition. Animates in with a soft pop.
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.huge),
        child: TweenAnimationBuilder<double>(
          duration: AppDurations.base,
          curve: AppCurves.spring,
          tween: Tween(begin: 0.92, end: 1.0),
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: theme.dividerColor),
                boxShadow: AppShadows.raised,
              ),
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                        destructive
                            ? Icons.warning_amber_rounded
                            : Icons.help_outline_rounded,
                        color: accent,
                        size: 28),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(title,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.h3.copyWith(color: textColor)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(message,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body1
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                          child: _btn(
                              context,
                              cancelText,
                              AppColors.textSecondary,
                              () => Get.back(result: false),
                              subtle: true)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                          child: _btn(context, confirmText, accent,
                              () => Get.back(result: true))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _btn(
      BuildContext context, String label, Color color, VoidCallback onTap,
      {bool subtle = false}) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: subtle ? Colors.transparent : color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
              color: subtle
                  ? Theme.of(context).dividerColor
                  : color.withValues(alpha: 0.5)),
        ),
        child: Text(label,
            style: AppTextStyles.button
                .copyWith(color: subtle ? AppColors.textSecondary : color)),
      ),
    );
  }
}
