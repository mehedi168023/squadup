import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Premium, consistent bottom sheets used across the app. Rounded top, drag
/// handle, themed surface, keyboard-aware, and width-capped on tablets so the
/// content never stretches edge-to-edge on large screens.
class AppSheet {
  AppSheet._();

  static Future<T?> show<T>({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Get.bottomSheet<T>(
      _SheetShell(title: title, subtitle: subtitle, child: child),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
    );
  }
}

class _SheetShell extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  const _SheetShell({required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mq = MediaQuery.of(context);
    final bottomInset = mq.viewInsets.bottom;
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        // Bounded height keeps the inner Flexible/scroll view safe and stops the
        // sheet from ever covering the whole screen.
        constraints:
            BoxConstraints(maxWidth: 560, maxHeight: mq.size.height * 0.85),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
            border: Border.all(color: theme.dividerColor),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md,
                  AppSpacing.xl, AppSpacing.xl + bottomInset),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.textMuted.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(title, style: AppTextStyles.h2.copyWith(fontSize: 20)),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(subtitle!,
                        style: AppTextStyles.body1
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Flexible(child: SingleChildScrollView(child: child)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
