import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/core/app_toast.dart';
import '../../app/core/validators.dart';
import '../../app/data/services/session_service.dart';
import '../../app/theme/app_colors.dart';
import '../../app/widgets/auth_field.dart';
import '../../app/widgets/premium_back_button.dart';
import '../../app/widgets/primary_button.dart';
import '../../app/widgets/responsive.dart';

class EditProfileController extends GetxController {
  final session = SessionService.to;
  final profileKey = GlobalKey<FormState>();
  final passwordKey = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController email;
  late final TextEditingController phone;
  final current = TextEditingController();
  final next = TextEditingController();
  final confirm = TextEditingController();
  final savingProfile = false.obs;
  final savingPassword = false.obs;

  @override
  void onInit() {
    super.onInit();
    final u = session.user.value;
    name = TextEditingController(text: u?.name ?? '');
    email = TextEditingController(text: u?.email ?? '');
    phone = TextEditingController(text: u?.phone ?? '');
  }

  Future<void> updateProfile() async {
    if (!(profileKey.currentState?.validate() ?? false)) return;
    savingProfile.value = true;
    await session.updateProfile(name: name.text.trim());
    savingProfile.value = false;
    AppToast.success('Profile updated');
  }

  Future<void> changePassword() async {
    if (!(passwordKey.currentState?.validate() ?? false)) return;
    savingPassword.value = true;
    final ok = await session.changePassword(current.text, next.text);
    savingPassword.value = false;
    if (ok) {
      current.clear();
      next.clear();
      confirm.clear();
      AppToast.success('Password changed');
    } else {
      AppToast.error('Failed to change password');
    }
  }

  @override
  void onClose() {
    name.dispose();
    email.dispose();
    phone.dispose();
    current.dispose();
    next.dispose();
    confirm.dispose();
    super.onClose();
  }
}

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(EditProfileController());
    return Scaffold(
      appBar: AppBar(leading: const PremiumBackButton(), title: const Text('Edit Profile')),
      body: ResponsiveCenter(
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Form(
              key: c.profileKey,
              child: AuthField(
                  label: 'Full Name',
                  hint: 'Your name',
                  icon: Icons.person_outline,
                  controller: c.name,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.name],
                  validator: Validators.name,
                  onSubmitted: c.updateProfile),
            ),
            const SizedBox(height: 12),
            AuthField(
                label: 'Email Address',
                hint: 'Email',
                icon: Icons.email_outlined,
                controller: c.email,
                locked: true),
            const SizedBox(height: 12),
            AuthField(
                label: 'Phone Number',
                hint: 'Phone',
                icon: Icons.phone_outlined,
                controller: c.phone,
                locked: true),
            const SizedBox(height: 11),
            Obx(() => PrimaryButton(
                label: 'UPDATE PROFILE',
                loading: c.savingProfile.value,
                onPressed: c.updateProfile)),
            const SizedBox(height: 30),
            Divider(color: context.cBorder),
            const SizedBox(height: 13),
            Form(
              key: c.passwordKey,
              child: Column(
                children: [
                  AuthField(
                    label: 'Current Password',
                    hint: 'Enter current password',
                    icon: Icons.lock_outline,
                    controller: c.current,
                    isPassword: true,
                    validator: Validators.loginPassword,
                  ),
                  const SizedBox(height: 12),
                  AuthField(
                    label: 'New Password',
                    hint: 'At least 8 chars, 1 letter & 1 number',
                    icon: Icons.lock_outline,
                    controller: c.next,
                    isPassword: true,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: Validators.password,
                  ),
                  const SizedBox(height: 12),
                  AuthField(
                    label: 'Confirm New Password',
                    hint: 'Confirm new password',
                    icon: Icons.lock_outline,
                    controller: c.confirm,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    validator: (v) => Validators.confirmPassword(v, c.next.text),
                    onSubmitted: c.changePassword,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 11),
            Obx(() => PrimaryButton(
                  label: 'CHANGE PASSWORD',
                  variant: ButtonVariant.red,
                  loading: c.savingPassword.value,
                  onPressed: c.changePassword,
                )),
          ],
        ),
      ),
    );
  }
}
