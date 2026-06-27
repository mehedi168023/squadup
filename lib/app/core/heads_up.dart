import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/heads_up_notification.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'notification_router.dart';
import 'safe_overlay.dart';

/// In-app heads-up notification banner. Slides down from the very top above
/// every screen (root overlay), auto-hides, and can be dismissed by swipe-up or
/// the close button. Theme-aware and queued so banners never overlap.
///
/// Usage: `HeadsUp.show(notification)` — but prefer `NotificationService` which
/// also mirrors to the in-app feed and fires the OS notification for sound.
class HeadsUp {
  HeadsUp._();

  static final List<HeadsUpNotification> _queue = [];
  static HeadsUpNotification? _current;
  static OverlayEntry? _entry;
  static bool _busy = false;

  /// Enqueue a banner. Duplicate ids (showing or queued) are ignored.
  static void show(HeadsUpNotification n) {
    if (_current?.id == n.id) return;
    if (_queue.any((q) => q.id == n.id)) return;
    // Higher-priority banners jump the queue.
    if (n.priority == NotifPriority.urgent) {
      _queue.insert(0, n);
    } else {
      _queue.add(n);
    }
    _pump();
  }

  static void _pump() {
    if (_busy || _queue.isEmpty) return;
    final overlay = rootOverlayState();
    if (overlay == null) {
      // Root overlay not mounted yet (very early startup or mid route
      // transition). Retry on the next frame instead of silently dropping the
      // banner — this is what makes notifications reliable from anywhere.
      WidgetsBinding.instance.addPostFrameCallback((_) => _pump());
      return;
    }
    _busy = true;
    _current = _queue.removeAt(0);
    _entry = OverlayEntry(
      builder: (_) => _Banner(data: _current!, onClosed: _onClosed),
    );
    overlay.insert(_entry!);
  }

  static void _onClosed() {
    _entry?.remove();
    _entry = null;
    _current = null;
    _busy = false;
    if (_queue.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 140), _pump);
    }
  }
}

class _Banner extends StatefulWidget {
  final HeadsUpNotification data;
  final VoidCallback onClosed;
  const _Banner({required this.data, required this.onClosed});

  @override
  State<_Banner> createState() => _BannerState();
}

class _BannerState extends State<_Banner> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: AppDurations.slow);
  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0, -1.25),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _c,
    curve: AppCurves.spring,
    reverseCurve: AppCurves.standard,
  ));
  late final Animation<double> _fade =
      CurvedAnimation(parent: _c, curve: Curves.easeOut);

  Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _c.forward();
    final ms = widget.data.autoHide.inMilliseconds;
    if (ms > 0) _timer = Timer(widget.data.autoHide, _close);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    _timer?.cancel();
    if (mounted) await _c.reverse();
    widget.onClosed();
  }

  void _onTapBanner() {
    final d = widget.data;
    // Tapping a push/heads-up opens its target if it has one; action banners
    // navigate only via their explicit button.
    if (d.kind != NotifKind.action && d.actionTarget != null) {
      NotificationRouter.open(d.actionTarget, d.actionArgs);
    }
    if (d.kind != NotifKind.action) _close();
  }

  void _onAction() {
    NotificationRouter.open(widget.data.actionTarget, widget.data.actionArgs);
    _close();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                  child: GestureDetector(
                    onTap: _onTapBanner,
                    onVerticalDragEnd: (e) {
                      if ((e.primaryVelocity ?? 0) < -120) _close();
                    },
                    child: _card(context),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context) {
    final d = widget.data;
    final accent = d.accent;
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: context.cSurface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: accent.withValues(alpha: 0.45)),
          boxShadow: [
            ...AppShadows.raised,
            ...AppShadows.glow(accent, opacity: 0.28),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _iconChip(accent, d.glyph),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.title.copyWith(
                                fontSize: 14.5, color: context.cText)),
                        if (d.message.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(d.message,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.body2
                                  .copyWith(color: context.cTextDim)),
                        ],
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _close,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded,
                          size: 20, color: context.cTextMuted),
                    ),
                  ),
                ],
              ),
            ),
            if (d.hasImage) _bannerImage(context, d),
            if (d.hasAction) _actionBar(context, accent),
          ],
        ),
      ),
    );
  }

  Widget _iconChip(Color accent, IconData glyph) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Icon(glyph, color: accent, size: 22),
    );
  }

  Widget _bannerImage(BuildContext context, HeadsUpNotification d) {
    final fallback = Container(
      color: context.cSurfaceAlt,
      alignment: Alignment.center,
      child: Icon(d.glyph, size: 40, color: context.cTextMuted),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: SizedBox(
          height: 150,
          width: double.infinity,
          child: d.isNetworkImage
              ? Image.network(d.image!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => fallback,
                  loadingBuilder: (c, w, p) => p == null ? w : fallback)
              : Image.asset(d.image!,
                  fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback),
        ),
      ),
    );
  }

  Widget _actionBar(BuildContext context, Color accent) {
    final label = widget.data.actionText ?? 'Open';
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _close,
              child: Container(
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: context.cBorder),
                ),
                child: Text('Dismiss',
                    style: AppTextStyles.button
                        .copyWith(color: context.cTextDim, fontSize: 13)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _onAction,
              child: Container(
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: AppShadows.glow(accent, opacity: 0.4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label,
                        style: AppTextStyles.button
                            .copyWith(color: Colors.white, fontSize: 13)),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 17, color: Colors.white),
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
