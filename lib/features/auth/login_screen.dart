import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/core/app_constants.dart';
import '../../app/core/validators.dart';
import '../../app/data/models/heads_up_notification.dart';
import '../../app/data/services/notification_service.dart';
import '../../app/data/services/session_service.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/widgets/auth_backdrop.dart';
import '../../app/widgets/auth_field.dart';
import '../../app/widgets/glass.dart';
import '../../app/widgets/primary_button.dart';

class LoginController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final identifier = TextEditingController();
  final password = TextEditingController();
  final googleLoading = false.obs;
  final emailLoading = false.obs;

  @override
  void onClose() {
    identifier.dispose();
    password.dispose();
    super.onClose();
  }

  /// Mock "Google" sign-in — simulates the account chooser + a successful
  /// local login (no backend, no real Google SDK). Keeps the button working.
  Future<void> signInWithGoogle() async {
    googleLoading.value = true;
    // Simulate the account-picker + auth round-trip latency.
    final ok = await SessionService.to.loginWithGoogle(
        'mock-google-id-token-${DateTime.now().millisecondsSinceEpoch}');
    googleLoading.value = false;
    if (!ok) return;
    _enter();
  }

  /// Email/phone + password login (mock — any credentials work).
  Future<void> submitEmail() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    emailLoading.value = true;
    final ok =
        await SessionService.to.login(identifier.text.trim(), password.text);
    emailLoading.value = false;
    if (!ok) return;
    _enter();
  }

  void _enter() {
    Get.offAllNamed(AppRoutes.shell);
    final name = SessionService.to.user.value?.name ?? 'Champion';
    Future.delayed(const Duration(milliseconds: 400), () {
      // In-app welcome banner (root-overlay heads-up). OS notification is left
      // off here so we don't double-post — the confirmation below is the single
      // OS notification, fired on the reliable default channel.
      NotificationService.to.showHeadsUp(
        HeadsUpNotification(
          id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Welcome, $name! 👋',
          message: 'Ready to compete? Join a tournament and win big rewards.',
          icon: 'success',
          priority: NotifPriority.normal,
        ),
      );
      // Real OS heads-up notification confirming the system works end-to-end
      // (requests POST_NOTIFICATIONS on Android 13+ before posting).
      NotificationService.to.notifyLoginSuccess();
    });
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(LoginController());
    return Scaffold(
      body: Stack(
        children: [
          const AuthBackdrop(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: GlassSurface(
                  // 18 (app-wide default) — a live BackdropFilter re-rasterizes
                  // every frame while the card animates; 18 is visually ~identical
                  // to 22 here but noticeably cheaper, avoiding auth-screen jank.
                  blur: 18,
                  opacity: 0.5,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xxl,
                      AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl),
                  child: Form(
                    key: c.formKey,
                    child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Square brand logo (NOT circular). Hero tag 'brand-logo'
                      // matches the Splash logo so the shared-element flight
                      // works. ClipRRect uses a small 12px radius; the logo is
                      // shown in full via BoxFit.contain (no crop, no stretch).
                      Hero(
                        tag: 'brand-logo',
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color:
                                    AppColors.primary.withValues(alpha: 0.5)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(AppConstants.logo,
                                width: 80,
                                height: 80,
                                fit: BoxFit.contain,
                                cacheWidth: 240),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Text('Welcome to ${AppConstants.appName}',
                          style: AppTextStyles.h1, textAlign: TextAlign.center),
                      const SizedBox(height: AppSpacing.xs),
                      Text('Sign in to join tournaments & win rewards',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body2
                              .copyWith(color: context.cTextDim)),
                      const SizedBox(height: AppSpacing.xl),
                      Obx(() => PrimaryButton(
                            label: 'Continue with Google',
                            icon: Icons.g_mobiledata_rounded,
                            loading: c.googleLoading.value,
                            onPressed: c.signInWithGoogle,
                          )),
                      const SizedBox(height: AppSpacing.lg),
                      Row(children: [
                        Expanded(child: Divider(color: context.cBorder)),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md),
                          child: Text('or',
                              style: AppTextStyles.body2
                                  .copyWith(color: context.cTextMuted)),
                        ),
                        Expanded(child: Divider(color: context.cBorder)),
                      ]),
                      const SizedBox(height: AppSpacing.lg),
                      AuthField(
                        label: 'Phone or Email',
                        hint: 'Enter your phone or email',
                        icon: Icons.person_outline,
                        controller: c.identifier,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [
                          AutofillHints.email,
                          AutofillHints.telephoneNumber
                        ],
                        validator: Validators.identifier,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AuthField(
                        label: 'Password',
                        hint: 'Enter your password',
                        icon: Icons.lock_outline,
                        controller: c.password,
                        isPassword: true,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        validator: Validators.loginPassword,
                        onSubmitted: c.submitEmail,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Obx(() => PrimaryButton(
                            label: 'Login',
                            variant: ButtonVariant.green,
                            loading: c.emailLoading.value,
                            onPressed: c.submitEmail,
                          )),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Don't have an account? ",
                              style: AppTextStyles.body2
                                  .copyWith(color: context.cTextDim)),
                          GestureDetector(
                            onTap: () => Get.toNamed(AppRoutes.register),
                            child: Text('Register',
                                style: AppTextStyles.title.copyWith(
                                    color: AppColors.primary, fontSize: 15)),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text('Version ${AppConstants.appVersion}',
                          style: AppTextStyles.body2
                              .copyWith(color: context.cTextMuted)),
                    ],
                  ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
