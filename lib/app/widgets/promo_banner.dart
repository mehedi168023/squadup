import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/app_links.dart';
import '../data/models/misc_models.dart';
import '../theme/app_spacing.dart';

/// Auto-scrolling promo banner carousel. Each slide is a pure image (or gradient
/// fallback) with NO text overlay; tapping it opens the slide's social link.
/// Page dots are overlaid inside the banner at the bottom-right.
///
/// Built on a plain [PageView] + [Timer] — no third-party carousel dependency.
class PromoBanner extends StatefulWidget {
  final List<BannerItem> banners;
  const PromoBanner({super.key, required this.banners});

  @override
  State<PromoBanner> createState() => _PromoBannerState();
}

class _PromoBannerState extends State<PromoBanner> {
  final PageController _controller = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    if (widget.banners.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) => _advance());
    }
  }

  void _advance() {
    if (!_controller.hasClients) return;
    final next = (_index + 1) % widget.banners.length;
    _controller.animateToPage(
      next,
      duration: AppDurations.slow,
      curve: AppCurves.emphasized,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        height: 150,
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.banners.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => _Banner(item: widget.banners[i]),
            ),
            // Page dots overlaid inside the banner, bottom-right.
            if (widget.banners.length > 1)
              Positioned(
                right: AppSpacing.lg,
                bottom: AppSpacing.md,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(widget.banners.length, (i) {
                    final active = i == _index;
                    return AnimatedContainer(
                      duration: AppDurations.base,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 20 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final BannerItem item;
  const _Banner({required this.item});

  void _onTap() {
    if (item.route != null) {
      Get.toNamed(item.route!);
    } else if (item.url.isNotEmpty) {
      AppLinks.open(item.url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.lg);
    final Widget surface = item.image != null
        ? Image.asset(item.image!, fit: BoxFit.cover, width: double.infinity)
        : DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: item.colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          );

    return Semantics(
      label: item.title,
      button: true,
      child: GestureDetector(
        onTap: _onTap,
        child: Padding(
          // Small horizontal gap so adjacent slides peek slightly while swiping.
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: ClipRRect(
            borderRadius: radius,
            child: SizedBox(width: double.infinity, child: surface),
          ),
        ),
      ),
    );
  }
}
