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
import '../../app/widgets/auth_field.dart';
import '../../app/widgets/premium_back_button.dart';
import '../../app/widgets/primary_button.dart';

class RegisterController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final identifier = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  final refer = TextEditingController();
  final loading = false.obs;
  final passwordValue = ''.obs;

  @override
  void onClose() {
    name.dispose();
    identifier.dispose();
    password.dispose();
    confirm.dispose();
    refer.dispose();
    super.onClose();
  }

  Future<void> submit() async {
    // Inline validation surfaces field-level errors; bail if anything fails.
    if (!(formKey.currentState?.validate() ?? false)) return;
    loading.value = true;
    final ok = await SessionService.to.register(
      name.text.trim(),
      identifier.text.trim(),
      password.text,
      referCode: refer.text.trim(),
    );
    loading.value = false;
    if (!ok) return;
    Get.offAllNamed(AppRoutes.shell);
    NotificationService.to.showHeadsUp(
      HeadsUpNotification(
        id: 'reg_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Registration Successful 🎉',
        message: 'Welcome to SquadUp! Your account is ready.',
        icon: 'success',
        sound: 'success',
      ),
      osNotify: true,
    );
  }
}

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(RegisterController());
    return Scaffold(
      appBar: AppBar(leading: const PremiumBackButton(), title: const Text('Create Account')),
      body: SafeArea(
        child: Form(
          key: c.formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Image.asset(AppConstants.logo,
                    width: 80, height: 80, cacheWidth: 240),
                const SizedBox(height: 13),
                AuthField(
                    label: 'Full Name',
                    hint: 'Enter your name',
                    icon: Icons.person_outline,
                    controller: c.name,
                    autofillHints: const [AutofillHints.name],
                    validator: Validators.name),
                const SizedBox(height: 11),
                AuthField(
                    label: 'Phone or Email',
                    hint: 'Enter your phone or email',
                    icon: Icons.alternate_email,
                    controller: c.identifier,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [
                      AutofillHints.email,
                      AutofillHints.telephoneNumber
                    ],
                    validator: Validators.identifier),
                const SizedBox(height: 11),
                AuthField(
                  label: 'Password',
                  hint: 'At least 8 chars, 1 letter & 1 number',
                  icon: Icons.lock_outline,
                  controller: c.password,
                  isPassword: true,
                  autofillHints: const [AutofillHints.newPassword],
                  onChanged: (v) => c.passwordValue.value = v,
                  validator: Validators.password,
                ),
                const SizedBox(height: 8),
                Obx(() => _PasswordStrength(password: c.passwordValue.value)),
                const SizedBox(height: 11),
                AuthField(
                    label: 'Confirm Password',
                    hint: 'Re-enter your password',
                    icon: Icons.lock_outline,
                    controller: c.confirm,
                    isPassword: true,
                    validator: (v) =>
                        Validators.confirmPassword(v, c.password.text)),
                const SizedBox(height: 11),
                AuthField(
                    label: 'Refer Code',
                    hint: 'Enter refer code if any',
                    icon: Icons.card_giftcard_outlined,
                    controller: c.refer,
                    textInputAction: TextInputAction.done,
                    onSubmitted: c.submit),
                const SizedBox(height: 11),
                Obx(() => PrimaryButton(
                    label: 'Register',
                    loading: c.loading.value,
                    onPressed: c.submit)),
                const SizedBox(height: 11),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account? ',
                      style: AppTextStyles.body2
                          .copyWith(color: context.cTextDim)),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Text('Login',
                        style: AppTextStyles.title
                            .copyWith(color: AppColors.primary, fontSize: 15)),
                  ),
                ],
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Live password-strength meter: a colour bar + label that reacts as the user
/// types, reinforcing the strength requirement.
class _PasswordStrength extends StatelessWidget {
  final String password;
  const _PasswordStrength({required this.password});

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    final s = Validators.strength(password);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: s.score,
                minHeight: 5,
                backgroundColor: context.cBorder,
                valueColor: AlwaysStoppedAnimation<Color>(s.color),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(s.label,
              style: AppTextStyles.label
                  .copyWith(color: s.color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
