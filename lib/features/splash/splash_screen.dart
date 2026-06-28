import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import '../../app/core/app_constants.dart';
import '../../app/data/services/session_service.dart';
import '../../app/data/services/security_service.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

enum SecurityStatus {
  scanning,
  passed,
  failedRoot,
  failedNetwork,
  failedIntegrity,
  failedBan,
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // Logo intro animation
  late final AnimationController _logoController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final Animation<double> _logoFade = CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic);
  late final Animation<double> _logoScale = Tween<double>(begin: 0.82, end: 1.0)
      .chain(CurveTween(curve: Curves.easeOutCubic))
      .animate(_logoController);

  // Terminal console fade animation
  late final AnimationController _terminalController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final Animation<double> _terminalFade = CurvedAnimation(parent: _terminalController, curve: Curves.easeIn);

  final RxList<String> _visibleLogs = <String>[].obs;
  final Rx<SecurityStatus> _status = SecurityStatus.scanning.obs;
  final RxDouble _progress = 0.0.obs;
  final RxString _failureMessage = ''.obs;

  @override
  void initState() {
    super.initState();
    _logoController.forward().then((_) {
      _terminalController.forward();
      _runSecurityChecks();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _terminalController.dispose();
    super.dispose();
  }

  /// Simulation + real checks running step-by-step
  Future<void> _runSecurityChecks() async {
    final sec = SecurityService.to;
    _visibleLogs.clear();
    _status.value = SecurityStatus.scanning;
    _progress.value = 0.0;

    const delay = Duration(milliseconds: 400);

    // Helper to add log and increment progress
    Future<void> logStep(String msg, double p) async {
      _visibleLogs.add(msg);
      _progress.value = p;
      await Future.delayed(delay);
    }

    await logStep('⚡ [INFO] Init SquadUp Secure Shield v1.0.2...', 0.1);

    // 1. Network check
    await logStep('📡 [SEC] Checking internet connection...', 0.25);
    final hasNet = await sec.hasInternetConnection();
    if (!hasNet) {
      _visibleLogs.add('❌ [FAIL] Network offline! Action blocked.');
      _status.value = SecurityStatus.failedNetwork;
      _failureMessage.value = 'Internet connection required to verify tournament integrity. Please connect to Wi-Fi/data.';
      return;
    }
    _visibleLogs.add('✅ [OK] Connection secure.');
    await Future.delayed(const Duration(milliseconds: 150));

    // 2. Root check
    await logStep('🔒 [SEC] Scanning for SU binaries & Root access...', 0.45);
    final isRooted = await sec.isDeviceRooted();
    if (isRooted) {
      _visibleLogs.add('⚠️ [ALERT] ROOT ACCESS DETECTED! Device compromised.');
      _status.value = SecurityStatus.failedRoot;
      _failureMessage.value = 'Rooted or custom ROM devices are not allowed in SquadUp Tournaments to prevent scripting and hacks. Code: SQ-SEC-ROOT';
      return;
    }
    _visibleLogs.add('✅ [OK] Sandbox secure.');
    await Future.delayed(const Duration(milliseconds: 150));

    // 3. Application Integrity
    await logStep('🛡️ [SEC] Verifying package signature integrity...', 0.65);
    final integrityPassed = await sec.verifyAppIntegrity();
    if (!integrityPassed) {
      _visibleLogs.add('❌ [FAIL] APK Signature verification failed! Mod detected.');
      _status.value = SecurityStatus.failedIntegrity;
      _failureMessage.value = 'This app has been modified or re-signed. Running modified clients is strictly prohibited. Please download the official app.';
      return;
    }
    _visibleLogs.add('✅ [OK] Signature valid.');
    await Future.delayed(const Duration(milliseconds: 150));

    // 4. Device Account limit & Ban status
    await logStep('👤 [SEC] Verifying device and ban status...', 0.85);
    
    // Check if device is banned
    if (sec.isDeviceBanned()) {
      _visibleLogs.add('❌ [BANNED] Device banned for policy violations.');
      _status.value = SecurityStatus.failedBan;
      _failureMessage.value = 'This device (ID: ${sec.deviceId.value}) is banned due to code violations or toxic behavior. Code: SQ-BAN-DEV';
      return;
    }

    // Check if currently logged in user (if any) is banned
    final session = SessionService.to;
    final currentUser = session.user.value;
    if (currentUser != null && sec.isUserBanned(currentUser.email)) {
      _visibleLogs.add('❌ [BANNED] User account is banned.');
      _status.value = SecurityStatus.failedBan;
      _failureMessage.value = 'Your account (${currentUser.email}) has been banned from SquadUp Tournaments. Code: SQ-BAN-USER';
      return;
    }
    
    _visibleLogs.add('✅ [OK] Device registered & active.');
    await Future.delayed(const Duration(milliseconds: 150));

    // 5. Finalizing boot
    await logStep('⚙️ [BOOT] Initializing tournament environment...', 1.0);
    _status.value = SecurityStatus.passed;
    await Future.delayed(const Duration(milliseconds: 500));

    // Normal routing
    final loggedIn = await session.tryAutoLogin();
    // Double check email ban if logged in
    if (loggedIn && session.user.value != null) {
      if (sec.isUserBanned(session.user.value!.email)) {
        _status.value = SecurityStatus.failedBan;
        _failureMessage.value = 'Your account has been banned from SquadUp Tournaments. Code: SQ-BAN-USER';
        return;
      }
    }
    Get.offAllNamed(loggedIn ? AppRoutes.shell : AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Obx(() {
              final status = _status.value;
              final isFailed = status != SecurityStatus.scanning && status != SecurityStatus.passed;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo & Brand intro
                  FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  isFailed 
                                      ? AppColors.danger.withValues(alpha: 0.18)
                                      : AppColors.primary.withValues(alpha: 0.18),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Hero(
                              tag: 'brand-logo',
                              child: Image.asset(
                                AppConstants.logo,
                                width: 110,
                                height: 110,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppConstants.appName,
                            style: AppTextStyles.h1.copyWith(
                              color: isFailed ? AppColors.danger : Colors.white,
                              fontSize: 28,
                            ),
                          ),
                          Text(
                            isFailed ? 'SHIELD BLOCKED' : 'TOURNAMENT SYSTEM',
                            style: AppTextStyles.label.copyWith(
                              color: isFailed ? AppColors.danger : AppColors.gold,
                              letterSpacing: 4,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Show error warning if failed, else show premium Lottie loader
                  if (isFailed)
                    _buildSecurityAlertCard()
                  else
                    FadeTransition(
                      opacity: _terminalFade,
                      child: _buildLottieLoader(),
                    ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  String get _statusText {
    final p = _progress.value;
    if (p < 0.25) return 'Initializing security shield...';
    if (p < 0.45) return 'Checking internet connection...';
    if (p < 0.65) return 'Scanning sandbox environment...';
    if (p < 0.85) return 'Verifying client integrity...';
    return 'Entering arena...';
  }

  Widget _buildLottieLoader() {
    return Column(
      children: [
        Lottie.asset(
          'assets/images/gaming_pad.json',
          width: 140,
          height: 140,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 24),
        // Premium linear progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 5,
            width: 240,
            child: LinearProgressIndicator(
              value: _progress.value,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _statusText,
          style: AppTextStyles.body2.copyWith(
            fontSize: 12, 
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  /// Access violation block screen
  Widget _buildSecurityAlertCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.gpp_bad_rounded,
                color: AppColors.danger,
                size: 52,
              ),
              const SizedBox(height: 14),
              Text(
                'ACCESS DENIED',
                style: AppTextStyles.h2.copyWith(color: AppColors.danger, fontSize: 18),
              ),
              const SizedBox(height: 10),
              Text(
                _failureMessage.value,
                textAlign: TextAlign.center,
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Retry/Fix Button
        ElevatedButton.icon(
          onPressed: _runSecurityChecks,
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          label: const Text('RE-SCAN SYSTEM', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        // Back / Cancel
        OutlinedButton(
          onPressed: () {
            // Closes application
            Get.back();
          },
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            'EXIT',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
