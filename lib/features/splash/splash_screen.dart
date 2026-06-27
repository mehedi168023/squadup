import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/core/app_constants.dart';
import '../../app/data/services/session_service.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

/// Boot screen — shows the brand, then routes to the shell (if logged in) or login.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // One-shot brand intro: the logo (and wordmark) fade in while scaling up from
  // 85% — premium and calm, not flashy. easeOutCubic decelerates into place.
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  late final Animation<double> _introFade =
      CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic);
  late final Animation<double> _introScale = Tween<double>(begin: 0.85, end: 1.0)
      .chain(CurveTween(curve: Curves.easeOutCubic))
      .animate(_intro);

  // Continuous heartbeat on the accent diamond.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _intro.forward();
    _boot();
  }

  /// Restore a saved session (if any) while the splash animation plays, then
  /// route to the shell or login.
  Future<void> _boot() async {
    // Keep the splash visible long enough to (a) play the logo intro and (b)
    // survive the slow first frame on a cold start (shader warm-up + profile
    // install can stall the very first frames), then route. 1200ms guarantees
    // the square-logo splash is actually seen, while still being noticeably
    // faster than the old flat 1600ms. Auto-login (~200ms) runs in parallel.
    final results = await Future.wait([
      SessionService.to.tryAutoLogin(),
      Future.delayed(const Duration(milliseconds: 1200)),
    ]);
    if (!mounted) return;
    final loggedIn = results[0] == true;
    Get.offAllNamed(loggedIn ? AppRoutes.shell : AppRoutes.login);
  }

  @override
  void dispose() {
    _intro.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgAlt,
      body: Center(
        child: FadeTransition(
          opacity: _introFade,
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _introScale,
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.winningTeal.withValues(alpha: 0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
                // Hero tag preserved ('brand-logo') so the Splash→Login shared
                // element keeps working. The intro scale/fade above wraps it and
                // has fully settled (≈800ms) before navigation (≈1600ms), so the
                // Hero lifts off cleanly with no scale fighting the flight.
                // Square logo shown in full (BoxFit.contain) — no round mask /
                // crop. The surrounding circle is only a soft glow halo, not a
                // clip, so the logo keeps its original square shape.
                child: Hero(
                  tag: 'brand-logo',
                  child: Image.asset(AppConstants.logo,
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                      cacheWidth: 400),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(AppConstants.appName, style: AppTextStyles.h1),
            const SizedBox(height: 8),
            Text(AppConstants.tagline,
                style: AppTextStyles.body1.copyWith(
                    color: AppColors.textSecondary, letterSpacing: 4)),
            const SizedBox(height: 50),
            ScaleTransition(
              scale: Tween(begin: 0.7, end: 1.1).animate(
                CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
              ),
              child: Transform.rotate(
                angle: 0.785398, // 45° → diamond
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.winningTeal,
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.winningTeal.withValues(alpha: 0.6),
                          blurRadius: 12),
                    ],
                  ),
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
