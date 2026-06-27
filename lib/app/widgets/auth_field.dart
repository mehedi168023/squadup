import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Labeled text field with a leading icon and a self-managed password
/// eye-toggle. The label starts as an in-field placeholder and smoothly
/// animates up onto the border outline when the field is focused or filled
/// (Material floating-label). Stateful so toggling visibility never rebuilds
/// the parent (avoids focus/cursor glitches while typing).
class AuthField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final bool isPassword;
  final bool locked;
  final TextInputType? keyboardType;

  /// Keyboard action button. Defaults to "next" so multi-field forms advance
  /// focus automatically; set [TextInputAction.done] on the last field.
  final TextInputAction textInputAction;

  /// Called when a completion action (done/go) is pressed — wire this to the
  /// form's submit on the last field.
  final VoidCallback? onSubmitted;

  /// Production-grade validation. When set, the field shows an inline error and
  /// validates as the user types (after first interaction).
  final String? Function(String?)? validator;

  /// Restrict what can be typed (e.g. digits-only for phone numbers).
  final List<TextInputFormatter>? inputFormatters;

  /// Platform autofill hints (email / password / telephone).
  final List<String>? autofillHints;

  /// Hard cap on character count (counter is always hidden).
  final int? maxLength;

  /// Live value callback (used to drive the password-strength meter).
  final ValueChanged<String>? onChanged;

  const AuthField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.isPassword = false,
    this.locked = false,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.validator,
    this.inputFormatters,
    this.autofillHints,
    this.maxLength,
    this.onChanged,
  });

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField>
    with SingleTickerProviderStateMixin {
  // Tooltip palette (Linear/Stripe style).
  static const _danger = Color(0xFFEF4444);
  static const _success = Color(0xFF22C55E);
  static const _tooltipBg = Color(0xFF111827);

  late bool _obscure = widget.isPassword;
  final LayerLink _link = LayerLink();

  /// The tooltip animation controller. Created lazily the first time a tooltip
  /// is actually shown (see [_tipController]) — NEVER eagerly and never in
  /// [dispose]. Creating an [AnimationController] builds a Ticker via
  /// `vsync: this`, which reads the inherited `TickerMode` from `context`; doing
  /// that on a deactivated widget throws "Looking up a deactivated widget's
  /// ancestor is unsafe." Kept nullable so dispose can no-op when it was never
  /// needed.
  AnimationController? _tipAnim;

  /// Lazily builds (or returns) the controller while the widget is still alive.
  /// Only call this from event/build paths — not from dispose.
  AnimationController get _tipController => _tipAnim ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 190),
      );

  OverlayEntry? _tip;
  String? _err;

  @override
  void initState() {
    super.initState();
    if (widget.validator != null && widget.controller.text.isNotEmpty) {
      _err = widget.validator!(widget.controller.text);
    }
  }

  @override
  void dispose() {
    // Tear down the overlay synchronously, then dispose the controller only if
    // it was ever created. No context / inherited-widget access happens here.
    _removeTooltip(animated: false);
    _tipAnim?.dispose();
    super.dispose();
  }

  void _setError(String? err) {
    if (err == _err) return;
    setState(() => _err = err);
    if (err == null) {
      _removeTooltip(); // became valid → auto-dismiss
    } else {
      _tip?.markNeedsBuild();
    }
  }

  /// Re-validates live and rebuilds (so the valid ✓ badge tracks text changes
  /// even when the error stays null).
  void _refresh(String v) {
    if (widget.validator == null) return;
    final e = widget.validator!(v);
    final wasError = _err != null;
    setState(() => _err = e);
    if (e == null) {
      if (wasError) _removeTooltip();
    } else {
      _tip?.markNeedsBuild();
    }
  }

  // ── Tooltip overlay ────────────────────────────────────────────────────────

  void _toggleTooltip() => _tip == null ? _showTooltip() : _removeTooltip();

  void _showTooltip() {
    if (_err == null || _tip != null) return;
    _tip = OverlayEntry(builder: _buildTooltip);
    Overlay.of(context).insert(_tip!);
    _tipController.forward(from: 0);
  }

  void _removeTooltip({bool animated = true}) {
    final entry = _tip;
    if (entry == null) return;
    final anim = _tipAnim;
    if (!animated || anim == null) {
      entry.remove();
      _tip = null;
      anim?.value = 0;
      return;
    }
    anim.reverse().whenComplete(() {
      entry.remove();
      if (_tip == entry) _tip = null;
    });
  }

  Widget _buildTooltip(BuildContext context) {
    return Stack(
      children: [
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
            animation: _tipController,
            builder: (_, child) {
              final t = Curves.easeOutCubic.transform(_tipController.value);
              return Opacity(
                opacity: _tipController.value.clamp(0.0, 1.0),
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
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: CustomPaint(
                size: Size(18, 9), painter: _TipArrow(_tooltipBg)),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 290),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: _tooltipBg,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
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
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _danger.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                      border: Border.all(color: _danger.withValues(alpha: 0.5)),
                    ),
                    child: const Icon(Icons.error_outline_rounded,
                        color: _danger, size: 18),
                  ),
                  const SizedBox(width: 11),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Invalid ${widget.label.toLowerCase()}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                                height: 1.2)),
                        const SizedBox(height: 2),
                        Text(_err ?? '',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.72),
                                fontSize: 13,
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

  /// The green ✓ badge shown when the field is valid.
  Widget _validBadge() {
    return Padding(
      padding: EdgeInsets.only(left: 4, right: widget.isPassword ? 2 : 12),
      child: Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _success,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _success.withValues(alpha: 0.4),
              blurRadius: 8,
              spreadRadius: -1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
      ),
    );
  }

  /// The red "!" badge shown inside the field; tap it to reveal the tooltip.
  Widget _badge() {
    return Padding(
      padding: EdgeInsets.only(left: 4, right: widget.isPassword ? 2 : 12),
      child: CompositedTransformTarget(
        link: _link,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleTooltip,
          child: Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _danger,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _danger.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: -1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.priority_high_rounded,
                size: 14, color: Colors.white),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;
    final hasError = _err != null;
    final isValid = widget.validator != null &&
        !hasError &&
        !widget.locked &&
        widget.controller.text.isNotEmpty;

    // Suffix = optional status badge (error "!" / valid ✓) + (eye / lock).
    final suffixChildren = <Widget>[];
    if (hasError && !widget.locked) {
      suffixChildren.add(_badge());
    } else if (isValid) {
      suffixChildren.add(_validBadge());
    }
    if (widget.locked) {
      suffixChildren.add(Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Icon(Icons.lock_outline, color: context.cTextMuted, size: 18),
      ));
    } else if (widget.isPassword) {
      suffixChildren.add(IconButton(
        splashRadius: 20,
        onPressed: () => setState(() => _obscure = !_obscure),
        icon: Icon(
          _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: context.cTextDim,
        ),
      ));
    }
    final Widget? suffix = suffixChildren.isEmpty
        ? null
        : Row(mainAxisSize: MainAxisSize.min, children: suffixChildren);

    OutlineInputBorder outline(Color c, [double w = 1.0]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );

    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      enabled: !widget.locked,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: (_) => widget.onSubmitted?.call(),
      onChanged: (v) {
        widget.onChanged?.call(v);
        _refresh(v);
      },
      validator: widget.validator == null
          ? null
          : (v) {
              final e = widget.validator!(v);
              // Sync the badge after this validate() pass (e.g. on submit).
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _setError(e);
              });
              return e;
            },
      autovalidateMode: widget.validator != null
          ? AutovalidateMode.onUserInteraction
          : null,
      inputFormatters: widget.inputFormatters,
      autofillHints: widget.autofillHints,
      maxLength: widget.maxLength,
      buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
          null,
      cursorColor: AppColors.primary,
      style: AppTextStyles.body1.copyWith(color: textColor, fontSize: 15),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle:
            AppTextStyles.body1.copyWith(color: context.cTextDim, fontSize: 15),
        floatingLabelStyle: AppTextStyles.title.copyWith(
          color: widget.locked
              ? context.cTextMuted
              : (hasError ? _danger : AppColors.primary),
          fontSize: 13.5,
        ),
        hintStyle: AppTextStyles.body1
            .copyWith(color: context.cTextMuted, fontSize: 14),
        filled: true,
        fillColor: widget.locked
            ? context.cSurface.withValues(alpha: 0.4)
            : (hasError
                ? Color.alphaBlend(
                    _danger.withValues(alpha: 0.06), context.cSurfaceAlt)
                : context.cSurfaceAlt),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        prefixIcon: Icon(widget.icon,
            color: hasError ? _danger : context.cTextDim, size: 22),
        suffixIcon: suffix,
        // The badge + tooltip replace the inline error text entirely.
        errorStyle: const TextStyle(height: 0, fontSize: 0),
        border: outline(context.cBorder),
        enabledBorder: outline(hasError ? _danger : context.cBorder,
            hasError ? 1.4 : 1.0),
        disabledBorder: outline(context.cBorder),
        focusedBorder: outline(hasError ? _danger : AppColors.primary, 1.4),
        errorBorder: outline(_danger, 1.4),
        focusedErrorBorder: outline(_danger, 1.6),
      ),
    );
  }
}

/// Upward-pointing arrow connecting the tooltip to the badge.
class _TipArrow extends CustomPainter {
  final Color color;
  const _TipArrow(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TipArrow old) => old.color != color;
}
