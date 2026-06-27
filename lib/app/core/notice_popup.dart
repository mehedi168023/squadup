import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/mock/mock_data.dart';
import '../data/models/misc_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/glass.dart';
import 'app_constants.dart';
import 'app_links.dart';

/// A swipeable launch notice popup. Shows once per app launch (and again when
/// the bell is tapped). Replaces the old in-app notifications screen.
///
/// Premium redesign: a single branded frosted-glass sheet (logo header +
/// counter), a full-bleed promo pager with a gradient scrim + "tap to open"
/// hint, an "Open" call-to-action that acts on the current notice, and a
/// worm-style page indicator — all wrapped in a scale/fade entrance.
class NoticePopup {
  NoticePopup._();

  static bool _shownThisLaunch = false;

  /// Shows the popup only the first time per app launch.
  static void showIfFirstLaunch() {
    if (_shownThisLaunch) return;
    _shownThisLaunch = true;
    show();
  }

  /// Always shows the popup (used by the bell icon).
  static void show() {
    if (MockData.notices.isEmpty) return;
    Get.dialog(
      const _NoticeDialog(notices: MockData.notices),
      barrierColor: Colors.black.withValues(alpha: 0.72),
    );
  }
}

class _NoticeDialog extends StatefulWidget {
  final List<NoticeItem> notices;
  const _NoticeDialog({required this.notices});

  @override
  State<_NoticeDialog> createState() => _NoticeDialogState();
}

class _NoticeDialogState extends State<_NoticeDialog>
    with SingleTickerProviderStateMixin {
  final PageController _controller = PageController();
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: AppDurations.slow,
  )..forward();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    _enter.dispose();
    super.dispose();
  }

  void _go(int to) {
    final i = to.clamp(0, widget.notices.length - 1);
    _controller.animateToPage(i,
        duration: AppDurations.base, curve: AppCurves.emphasized);
  }

  /// Acts on a notice: internal route first, else external url, else just close.
  void _open(NoticeItem notice) {
    Get.back();
    if (notice.route != null) {
      Get.toNamed(notice.route!);
    } else if (notice.url != null) {
      AppLinks.open(notice.url!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;
    // Promo image height: scales with width but is capped against short screens
    // so the sheet never overflows on small devices.
    final imgH = (media.width * 0.66).clamp(180.0, media.height * 0.42);
    final multi = widget.notices.length > 1;
    final current = widget.notices[_index];
    final hasAction = current.route != null || current.url != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ScaleTransition(
            scale: Tween(begin: 0.92, end: 1.0)
                .animate(CurvedAnimation(parent: _enter, curve: AppCurves.spring)),
            child: FadeTransition(
              opacity: CurvedAnimation(parent: _enter, curve: Curves.easeOut),
              // Get.dialog doesn't insert a Material ancestor (unlike
              // showDialog), so Text would render with the debug yellow
              // underline. A transparent Material gives every child a proper
              // text style without affecting the glass look.
              child: Material(
                type: MaterialType.transparency,
                child: GlassSurface(
                  blur: 24,
                  opacity: 0.82,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _header(context, multi),
                    SizedBox(
                      height: imgH.toDouble(),
                      child: PageView.builder(
                        controller: _controller,
                        itemCount: widget.notices.length,
                        onPageChanged: (i) => setState(() => _index = i),
                        itemBuilder: (_, i) => _NoticeCard(
                          notice: widget.notices[i],
                          onTap: () => _open(widget.notices[i]),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (multi) _dots(),
                    const SizedBox(height: AppSpacing.md),
                    _footer(context, multi, current, hasAction),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, bool multi) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.md, AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
              boxShadow: AppShadows.glow(AppColors.primary, opacity: 0.25),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Image.asset(AppConstants.logo,
                  width: 34, height: 34, cacheWidth: 102),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notices',
                    style: AppTextStyles.h3.copyWith(color: context.cText)),
                Text('Latest updates & offers',
                    style: AppTextStyles.body2
                        .copyWith(color: context.cTextDim)),
              ],
            ),
          ),
          if (multi) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4)),
              ),
              child: Text('${_index + 1}/${widget.notices.length}',
                  style: AppTextStyles.label.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          GestureDetector(
            onTap: () => Get.back(),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.cSurfaceAlt,
                shape: BoxShape.circle,
                border: Border.all(color: context.cBorder),
              ),
              child: Icon(Icons.close_rounded,
                  size: 19, color: context.cTextDim),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.notices.length, (i) {
        final active = i == _index;
        return AnimatedContainer(
          duration: AppDurations.base,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? AppColors.winningTeal
                : context.cTextMuted.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _footer(BuildContext context, bool multi, NoticeItem current,
      bool hasAction) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          if (multi) ...[
            _ArrowButton(
              icon: Icons.chevron_left_rounded,
              enabled: _index > 0,
              onTap: () => _go(_index - 1),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: PressableScale(
              onTap: () => _open(current),
              child: Container(
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: AppColors.blueGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: AppShadows.glow(AppColors.primary, opacity: 0.4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(hasAction ? 'Open' : 'Got it',
                        style: AppTextStyles.button
                            .copyWith(color: Colors.white)),
                    if (hasAction) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 18, color: Colors.white),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (multi) ...[
            const SizedBox(width: AppSpacing.md),
            _ArrowButton(
              icon: Icons.chevron_right_rounded,
              enabled: _index < widget.notices.length - 1,
              onTap: () => _go(_index + 1),
            ),
          ],
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _ArrowButton(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: context.cSurfaceAlt,
            shape: BoxShape.circle,
            border: Border.all(color: context.cBorder),
          ),
          child: Icon(icon, color: context.cText, size: 26),
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final NoticeItem notice;
  final VoidCallback onTap;
  const _NoticeCard({required this.notice, required this.onTap});

  bool get _isNetwork =>
      notice.image.startsWith('http://') || notice.image.startsWith('https://');

  bool get _hasAction => notice.route != null || notice.url != null;

  @override
  Widget build(BuildContext context) {
    final image = _isNetwork
        ? Image.network(
            notice.image,
            fit: BoxFit.cover,
            loadingBuilder: (c, child, p) =>
                p == null ? child : const _NoticeFallback(loading: true),
            errorBuilder: (_, __, ___) => const _NoticeFallback(),
          )
        : Image.asset(
            notice.image,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const _NoticeFallback(),
          );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: notice.colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.16), width: 1),
          boxShadow: AppShadows.raised,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            image,
            // Bottom scrim so the hint chip stays legible over any image.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 70,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.5),
                    ],
                  ),
                ),
              ),
            ),
            if (_hasAction)
              Positioned(
                left: 12,
                bottom: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.touch_app_rounded,
                          size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text('Tap to open',
                          style: AppTextStyles.label.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Shown while a notice image loads or if it fails — keeps the card looking
/// intentional instead of broken.
class _NoticeFallback extends StatelessWidget {
  final bool loading;
  const _NoticeFallback({this.loading = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: loading
          ? const CircularProgressIndicator(color: Colors.white)
          : Icon(Icons.image_outlined,
              size: 64, color: Colors.white.withValues(alpha: 0.5)),
    );
  }
}
