import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../app/core/app_constants.dart';
import '../../app/core/notice_popup.dart';
import '../../app/data/services/permission_service.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_shadows.dart';
import '../../app/theme/app_text_styles.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../shop/shop_screen.dart';

class ShellController extends GetxController {
  static ShellController get to => Get.find();

  // Index 1 = Home (the default landing tab, center of the nav bar).
  final index = 1.obs;
  void go(int i) => index.value = i;

  bool _precached = false;

  /// Warm the first-screen images (Home categories/banners + Shop tiles) into
  /// the image cache so tab switches and re-entries paint instantly with no
  /// decode hitch. Runs once; failures are ignored (assets are bundled).
  void precacheFirstScreenImages(BuildContext context) {
    if (_precached) return;
    _precached = true;
    const assets = <String>[
      AppConstants.logo,
      AppConstants.freefireLogo,
      AppConstants.ludoClassic,
      AppConstants.ludoAuto,
      AppConstants.bannerAddMoney,
      AppConstants.bannerHowToPlay,
      AppConstants.bannerJoinGroup,
      AppConstants.shopProductsBanner,
      AppConstants.shopTopupBanner,
      AppConstants.shopGamingLogo,
    ];
    for (final a in assets) {
      precacheImage(AssetImage(a), context, onError: (_, __) {});
    }
  }

  @override
  void onReady() {
    super.onReady();
    // Show the launch notice popup once per app launch (after the first frame).
    WidgetsBinding.instance
        .addPostFrameCallback((_) => NoticePopup.showIfFirstLaunch());
    // Request the permissions the app uses (notification / file-image).
    Future(() => PermissionService.to.requestAll());
  }
}

class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key});

  static const _tabs = [ShopScreen(), HomeScreen(), ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    final c = Get.put(ShellController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) c.precacheFirstScreenImages(context);
    });
    return Scaffold(
      // Let the page content draw behind the floating nav bar so the
      // transparent margins around it show the screen — not a flat colour block.
      extendBody: true,
      body: Obx(() => IndexedStack(index: c.index.value, children: _tabs)),
      bottomNavigationBar:
          Obx(() => _NavBar(current: c.index.value, onTap: c.go)),
    );
  }
}

/// Floating, fully-rounded bottom navigation bar. A gradient "glow pill" glides
/// to the active tab with iOS-style **spring physics** (super smooth, gentle
/// follow-through) while the icon lifts and scales — a premium, tactile nav
/// with light haptic feedback on tap.
class _NavBar extends StatefulWidget {
  final int current;
  final ValueChanged<int> onTap;
  const _NavBar({required this.current, required this.onTap});

  @override
  State<_NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<_NavBar> with SingleTickerProviderStateMixin {
  static const _items = [
    (Icons.storefront_outlined, Icons.storefront, 'Shop'),
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.person_outline, Icons.person_rounded, 'Profile'),
  ];

  // Slightly-underdamped spring → fluid iOS-style motion with only a sub-pixel
  // overshoot, so the pill stays smooth yet never escapes the bar.
  static const _spring =
      SpringDescription(mass: 1, stiffness: 360, damping: 33);
  static const _pop = Duration(milliseconds: 380);

  // The pill's continuous position, in tab units (0..items-1), driven by the
  // spring simulation. Unbounded so the simulation can run freely.
  late final AnimationController _pos = AnimationController.unbounded(
    vsync: this,
    value: widget.current.toDouble(),
  )..addListener(_tick);

  void _tick() => setState(() {});

  @override
  void didUpdateWidget(covariant _NavBar old) {
    super.didUpdateWidget(old);
    if (old.current != widget.current) {
      _pos.animateWith(SpringSimulation(
          _spring, _pos.value, widget.current.toDouble(), _pos.velocity));
    }
  }

  @override
  void dispose() {
    _pos.dispose();
    super.dispose();
  }

  void _tap(int i) {
    HapticFeedback.lightImpact();
    widget.onTap(i);
  }

  @override
  Widget build(BuildContext context) {
    final maxIndex = (_items.length - 1).toDouble();
    return RepaintBoundary(
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Container(
            height: 56,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: context.cSurface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: context.cBorder),
              boxShadow: AppShadows.raised,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final slot = constraints.maxWidth / _items.length;
                // Clamp the rendered position so a spring overshoot can never
                // push the pill outside the bar.
                final pos = _pos.value.clamp(0.0, maxIndex);
                return Stack(
                  children: [
                    // Spring-driven glow pill — continuous, contained position.
                    Positioned(
                      left: pos * slot,
                      top: 0,
                      bottom: 0,
                      width: slot,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF3B7BF0), Color(0xFF16357D)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFF6AA1FF)
                                  .withValues(alpha: 0.7),
                              width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.5),
                              blurRadius: 14,
                              spreadRadius: -3,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: List.generate(_items.length, (i) {
                        final active = i == widget.current;
                        final item = _items[i];
                        return Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _tap(i),
                            child: TweenAnimationBuilder<double>(
                              duration: _pop,
                              curve: Curves.easeOutBack,
                              tween: Tween(end: active ? 1.0 : 0.0),
                              builder: (_, t, __) {
                                final tc = t.clamp(0.0, 1.0);
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Active icon lifts up and grows slightly.
                                    Transform.translate(
                                      offset: Offset(0, -2 * t),
                                      child: Transform.scale(
                                        scale: 1 + 0.1 * t,
                                        child: Icon(
                                          active ? item.$2 : item.$1,
                                          size: 19,
                                          color: Color.lerp(context.cTextDim,
                                              Colors.white, tc),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.$3,
                                      style: AppTextStyles.label.copyWith(
                                        color: Color.lerp(context.cTextDim,
                                            Colors.white, tc),
                                        fontWeight: tc > 0.5
                                            ? FontWeight.w800
                                            : FontWeight.w500,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
