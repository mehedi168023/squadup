import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/glass.dart';
import 'safe_overlay.dart';

/// A lightweight, dependency-free loading overlay (replaces flutter_easyloading).
///
/// Uses a single [OverlayEntry] on the root overlay so it never interferes with
/// the navigation stack — `dismiss()` removes exactly the loader, never a route.
class AppLoader {
  AppLoader._();

  static OverlayEntry? _entry;

  /// Shows a blocking, frosted loading overlay. No-op if already visible.
  static void show([String? status]) {
    if (_entry != null) return;
    final overlay = rootOverlayState();
    if (overlay == null) return;
    _entry = OverlayEntry(builder: (_) => _LoaderView(status: status));
    overlay.insert(_entry!);
  }

  /// Removes the loading overlay if present.
  static void dismiss() {
    _entry?.remove();
    _entry = null;
  }
}

class _LoaderView extends StatefulWidget {
  final String? status;
  const _LoaderView({this.status});

  @override
  State<_LoaderView> createState() => _LoaderViewState();
}

class _LoaderViewState extends State<_LoaderView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: AppDurations.base)..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _c, curve: Curves.easeOut),
      child: Stack(
        children: [
          const ModalBarrier(dismissible: false, color: Color(0x88000000)),
          Center(
            child: ScaleTransition(
              scale: Tween(begin: 0.9, end: 1.0).animate(
                  CurvedAnimation(parent: _c, curve: AppCurves.spring)),
              child: GlassSurface(
                blur: 20,
                opacity: 0.85,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl, vertical: AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 34,
                      height: 34,
                      child: CircularProgressIndicator(
                          strokeWidth: 3, color: AppColors.primary),
                    ),
                    if (widget.status != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(widget.status!,
                          style: AppTextStyles.body1
                              .copyWith(color: context.cText)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
