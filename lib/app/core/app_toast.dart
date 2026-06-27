import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Single source of truth for in-app toasts. A unique, premium top banner:
/// intent-tinted frosted glass, a glowing gradient icon badge, a soft coloured
/// glow, and a depleting timer bar.
///
/// **Smart icons:** beyond the success/error/warning/info colour, the banner
/// inspects the title + message and shows a *context* icon — e.g. a copy glyph
/// for "copied", a wallet for amounts/withdrawals, a controller for match
/// joins, a lock for passwords (works for English & the app's Bengali strings).
class AppToast {
  AppToast._();

  static void success(String message, {String title = 'Success'}) =>
      _show(title, message, AppColors.success, Icons.check_circle_rounded);

  static void error(String message, {String title = 'Oops'}) =>
      _show(title, message, AppColors.danger, Icons.error_rounded);

  static void warning(String message, {String title = 'Warning'}) =>
      _show(title, message, AppColors.gold, Icons.warning_amber_rounded);

  static void info(String message, {String title = 'Notice'}) =>
      _show(title, message, AppColors.primary, Icons.info_rounded);

  static void _show(
      String title, String message, Color color, IconData fallback) {
    if (Get.isSnackbarOpen) Get.closeAllSnackbars();
    const duration = Duration(seconds: 3);
    final icon = _smartIcon('$title $message', fallback);
    Get.showSnackbar(
      GetSnackBar(
        // The whole visual is our custom card; the GetSnackBar is just a
        // transparent, full-width host so we control blur, glow and the bar.
        messageText: _ToastCard(
          title: title,
          message: message,
          color: color,
          icon: icon,
          duration: duration,
        ),
        backgroundColor: Colors.transparent,
        padding: EdgeInsets.zero,
        borderRadius: 0,
        barBlur: 0,
        maxWidth: 560,
        margin: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
        snackPosition: SnackPosition.TOP,
        snackStyle: SnackStyle.FLOATING,
        duration: duration,
        isDismissible: true,
        dismissDirection: DismissDirection.up,
        boxShadows: const [],
        animationDuration: AppDurations.slow,
        forwardAnimationCurve: AppCurves.spring,
        reverseAnimationCurve: AppCurves.standard,
      ),
    );
  }

  /// Picks a context-appropriate glyph from the toast text, falling back to the
  /// intent's default icon. Keywords cover both English and the app's Bengali
  /// copy. Order matters — more specific matches come first.
  static IconData _smartIcon(String text, IconData fallback) {
    final t = text.toLowerCase();
    bool has(List<String> keys) => keys.any(t.contains);

    if (has(['copied', 'copy', 'paste', 'clipboard'])) {
      return Icons.content_copy_rounded;
    }
    if (has(['referr', 'invite', 'refer'])) return Icons.card_giftcard_rounded;
    if (has(['password', 'login', 'sign in'])) return Icons.lock_rounded;
    if (has(['withdraw'])) return Icons.account_balance_rounded;
    if (has(['deposit', 'add money', 'recharge'])) {
      return Icons.account_balance_wallet_rounded;
    }
    if (has(['top-up', 'topup', 'diamond', 'coin'])) {
      return Icons.diamond_rounded;
    }
    if (has(['order', 'purchase', 'bought', 'checkout', 'buy', 'delivery'])) {
      return Icons.shopping_bag_rounded;
    }
    if (has(['amount', 'balance', 'wallet', 'payment', 'pay', 'taka', '৳', 'টাকা'])) {
      return Icons.payments_rounded;
    }
    if (has(['room', 'রুম'])) return Icons.meeting_room_rounded;
    if (has(['join', 'match', 'tournament', 'জয়েন', 'ম্যাচ'])) {
      return Icons.sports_esports_rounded;
    }
    if (has(['screenshot', 'evidence', 'image', 'upload', 'attach', 'স্ক্রিনশট'])) {
      return Icons.image_rounded;
    }
    if (has(['link', 'url'])) return Icons.link_rounded;
    if (has(['phone', 'otp', '11-digit'])) return Icons.phone_rounded;
    if (has(['district', 'division', 'address', 'location'])) {
      return Icons.location_on_rounded;
    }
    if (has(['profile', 'name', 'account', 'নাম'])) return Icons.person_rounded;
    if (has(['network', 'connect', 'server', 'could not load', 'failed to load'])) {
      return Icons.wifi_off_rounded;
    }
    return fallback;
  }
}

class _ToastCard extends StatefulWidget {
  final String title;
  final String message;
  final Color color;
  final IconData icon;
  final Duration duration;

  const _ToastCard({
    required this.title,
    required this.message,
    required this.color,
    required this.icon,
    required this.duration,
  });

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bar =
      AnimationController(vsync: this, duration: widget.duration)..forward();

  @override
  void dispose() {
    _bar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    final radius = BorderRadius.circular(AppRadius.xl);
    // Intent-tinted frosted fill sitting over the real blur.
    final glass =
        Color.alphaBlend(color.withValues(alpha: 0.20), AppColors.surface)
            .withValues(alpha: 0.74);
    final maxMsgHeight =
        (MediaQuery.of(context).size.height * 0.4).clamp(120.0, 360.0);

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 28,
            spreadRadius: -8,
            offset: const Offset(0, 12),
          ),
          // Coloured glow matching the intent.
          BoxShadow(
            color: color.withValues(alpha: 0.32),
            blurRadius: 22,
            spreadRadius: -6,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            decoration: BoxDecoration(
              color: glass,
              borderRadius: radius,
              border: Border.all(color: color.withValues(alpha: 0.45)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _badge(color),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(widget.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.title.copyWith(
                                    color: AppColors.textPrimary,
                                    fontSize: 14.5)),
                            if (widget.message.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              ConstrainedBox(
                                constraints:
                                    BoxConstraints(maxHeight: maxMsgHeight),
                                child: SingleChildScrollView(
                                  child: Text(widget.message,
                                      style: AppTextStyles.body2.copyWith(
                                          color: AppColors.textSecondary,
                                          height: 1.35)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: Get.closeAllSnackbars,
                        behavior: HitTestBehavior.opaque,
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.close_rounded,
                              size: 18, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
                _timerBar(color),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(Color color) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            Color.alphaBlend(Colors.black.withValues(alpha: 0.22), color),
          ],
        ),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 14,
            spreadRadius: -2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(widget.icon, color: Colors.white, size: 23),
    );
  }

  /// A thin bar that depletes left→right over the toast's lifetime — a subtle,
  /// premium "time remaining" cue.
  Widget _timerBar(Color color) {
    return SizedBox(
      height: 3,
      width: double.infinity,
      child: Align(
        alignment: Alignment.centerLeft,
        child: AnimatedBuilder(
          animation: _bar,
          builder: (_, __) => FractionallySizedBox(
            widthFactor: (1 - _bar.value).clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                boxShadow: [
                  BoxShadow(
                      color: color.withValues(alpha: 0.6), blurRadius: 6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
