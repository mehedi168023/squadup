import 'package:flutter/material.dart';

/// A premium, reusable text field with inline validation feedback.
///
/// • A circular **red "!"** badge appears inside the field (right) when invalid,
///   and a green ✓ when valid.
/// • Tapping the badge reveals a floating **dark tooltip** (`#111827`) whose small
///   arrow points back up at the badge — Linear/Stripe/Notion style.
/// • The tooltip **fades + scales in** and auto-dismisses the instant the field
///   becomes valid.
///
/// Self-contained (no app-theme dependency beyond Material) so it drops into any
/// project. Pass a [validator] that returns an error description when invalid or
/// `null` when valid.
class ValidatedTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  /// Returns an error description when invalid, or `null` when valid.
  final String? Function(String value) validator;

  /// Tooltip headline (e.g. "Invalid username").
  final String errorTitle;

  /// Optional confirmation shown beneath the field when valid (e.g. "Looks good!").
  final String? successText;

  /// Validate even while the field is empty (default: empty == neutral).
  final bool validateWhenEmpty;

  const ValidatedTextField({
    super.key,
    required this.label,
    required this.validator,
    this.controller,
    this.errorTitle = 'Invalid input',
    this.successText,
    this.hint,
    this.prefixIcon = Icons.person_outline,
    this.keyboardType,
    this.obscureText = false,
    this.autofocus = false,
    this.onChanged,
    this.validateWhenEmpty = false,
  });

  @override
  State<ValidatedTextField> createState() => _ValidatedTextFieldState();
}

class _ValidatedTextFieldState extends State<ValidatedTextField>
    with SingleTickerProviderStateMixin {
  static const _error = Color(0xFFEF4444);
  static const _success = Color(0xFF22C55E);
  static const _tooltipBg = Color(0xFF111827);

  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  final LayerLink _link = LayerLink();

  /// Created lazily the first time a tooltip is shown (see [_anim]) — never
  /// eagerly and never in [dispose]. A late-final controller initialized inside
  /// dispose() would build a Ticker via `vsync: this`, reading inherited
  /// `TickerMode` from a deactivated `context` → "Looking up a deactivated
  /// widget's ancestor is unsafe." Nullable so dispose can no-op when unused.
  AnimationController? _animCtl;

  /// Builds (or returns) the controller while the widget is alive. Only call
  /// from event/build paths — never from dispose.
  AnimationController get _anim => _animCtl ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 190),
      );

  OverlayEntry? _entry;

  String? _err;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _err = _evaluate(_controller.text);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _removeTooltip(animated: false);
    _animCtl?.dispose();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  String? _evaluate(String v) {
    if (v.isEmpty && !widget.validateWhenEmpty) return null;
    return widget.validator(v);
  }

  void _onChanged() {
    final err = _evaluate(_controller.text);
    if (err != _err) {
      setState(() => _err = err);
      if (err == null) {
        _removeTooltip(); // became valid → dismiss
      } else {
        _entry?.markNeedsBuild(); // keep open tooltip text in sync
      }
    }
    widget.onChanged?.call(_controller.text);
  }

  // ── Tooltip overlay ────────────────────────────────────────────────────────

  void _toggleTooltip() => _entry == null ? _showTooltip() : _removeTooltip();

  void _showTooltip() {
    if (_err == null || _entry != null) return;
    _entry = OverlayEntry(builder: _buildTooltip);
    Overlay.of(context).insert(_entry!);
    _anim.forward(from: 0);
  }

  void _removeTooltip({bool animated = true}) {
    final entry = _entry;
    if (entry == null) return;
    final anim = _animCtl;
    if (!animated || anim == null) {
      entry.remove();
      _entry = null;
      anim?.value = 0;
      return;
    }
    anim.reverse().whenComplete(() {
      entry.remove();
      if (_entry == entry) _entry = null;
    });
  }

  Widget _buildTooltip(BuildContext context) {
    return Stack(
      children: [
        // Tap-outside-to-dismiss barrier.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _removeTooltip,
          ),
        ),
        CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomRight,
          followerAnchor: Alignment.topRight,
          offset: const Offset(0, 8),
          child: AnimatedBuilder(
            animation: _anim,
            builder: (_, child) {
              final t = Curves.easeOutCubic.transform(_anim.value);
              return Opacity(
                opacity: _anim.value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 0.94 + 0.06 * t,
                  alignment: Alignment.topRight,
                  child: child,
                ),
              );
            },
            child: _tooltipCard(),
          ),
        ),
      ],
    );
  }

  Widget _tooltipCard() {
    return Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Arrow, inset so its tip sits under the centre of the badge.
          const Padding(
            padding: EdgeInsets.only(right: 3),
            child: CustomPaint(
                size: Size(18, 9), painter: _ArrowPainter(_tooltipBg)),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _tooltipBg,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 24,
                    spreadRadius: -4,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _error.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: _error.withValues(alpha: 0.5)),
                    ),
                    child: const Icon(Icons.error_outline_rounded,
                        color: _error, size: 19),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.errorTitle,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                height: 1.2)),
                        const SizedBox(height: 3),
                        Text(_err ?? '',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.72),
                                fontSize: 13.5,
                                height: 1.35)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Field ──────────────────────────────────────────────────────────────────

  Widget? _statusBadge() {
    final hasError = _err != null;
    final isValid = _err == null && _controller.text.isNotEmpty;
    if (!hasError && !isValid) return null;

    final color = hasError ? _error : _success;
    final badge = Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: -1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
          hasError ? Icons.priority_high_rounded : Icons.check_rounded,
          size: 15,
          color: Colors.white),
    );

    return Padding(
      padding: const EdgeInsets.only(right: 12, left: 6),
      child: hasError
          ? CompositedTransformTarget(
              link: _link,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleTooltip,
                child: badge,
              ),
            )
          : badge,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = _err != null;
    final isValid = _err == null && _controller.text.isNotEmpty;
    final accent =
        hasError ? _error : (isValid ? _success : theme.dividerColor);
    final fill = hasError
        ? Color.alphaBlend(_error.withValues(alpha: 0.05), theme.cardColor)
        : isValid
            ? Color.alphaBlend(_success.withValues(alpha: 0.05), theme.cardColor)
            : theme.cardColor;

    OutlineInputBorder border(Color c, [double w = 1.2]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: c, width: w),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _controller,
          keyboardType: widget.keyboardType,
          obscureText: widget.obscureText,
          autofocus: widget.autofocus,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            filled: true,
            fillColor: fill,
            prefixIcon: Icon(widget.prefixIcon),
            suffixIcon: _statusBadge(),
            suffixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            border: border(theme.dividerColor),
            enabledBorder: border(accent, hasError || isValid ? 1.4 : 1.0),
            focusedBorder: border(
                hasError ? _error : (isValid ? _success : theme.colorScheme.primary),
                1.6),
          ),
        ),
        if (isValid && widget.successText != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.verified_user_rounded,
                  color: _success, size: 17),
              const SizedBox(width: 7),
              Text(widget.successText!,
                  style: const TextStyle(
                      color: _success,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5)),
            ],
          ),
        ],
      ],
    );
  }
}

/// Upward-pointing triangle that visually connects the tooltip to the badge.
class _ArrowPainter extends CustomPainter {
  final Color color;
  const _ArrowPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter old) => old.color != color;
}
