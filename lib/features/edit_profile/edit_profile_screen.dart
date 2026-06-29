import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
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
  final pickedImage = Rxn<File>();

  @override
  void onInit() {
    super.onInit();
    final u = session.user.value;
    name = TextEditingController(text: u?.name ?? '');
    email = TextEditingController(text: u?.email ?? '');
    phone = TextEditingController(text: u?.phone ?? '');
  }

  Future<void> selectAvatar() async {
    try {
      final picker = ImagePicker();
      final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (img != null) {
        pickedImage.value = File(img.path);
      }
    } catch (e) {
      AppToast.error('Failed to select image: $e');
    }
  }

  Future<void> updateProfile() async {
    if (!(profileKey.currentState?.validate() ?? false)) return;
    savingProfile.value = true;
    final ok = await session.updateProfile(
      name: name.text.trim(),
      avatarFile: pickedImage.value,
    );
    savingProfile.value = false;
    if (ok) {
      pickedImage.value = null;
      AppToast.success('Profile updated successfully!');
    }
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
      backgroundColor: const Color(0xFF081026),
      appBar: AppBar(
        leading: const PremiumBackButton(),
        title: const Text('Edit Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF081026),
        elevation: 0,
        centerTitle: true,
      ),
      body: ResponsiveCenter(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            // DP (Display Picture) Section
            Center(
              child: Stack(
                children: [
                  Obx(() {
                    final u = c.session.user.value;
                    final localFile = c.pickedImage.value;
                    
                    return Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 15,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: ClipOval(
                        child: localFile != null
                            ? Image.file(localFile, fit: BoxFit.cover)
                            : (u?.avatar != null && u!.avatar!.startsWith('http')
                                ? Image.network(
                                    u.avatar!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(u.name),
                                  )
                                : _buildAvatarPlaceholder(u?.name ?? '?')),
                      ),
                    );
                  }),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: c.selectAvatar,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Profile info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F1E3D), Color(0xFF0C142B)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PERSONAL DETAILS',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      )),
                  const SizedBox(height: 16),
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
                      onSubmitted: c.updateProfile,
                    ),
                  ),
                  const SizedBox(height: 14),
                  AuthField(
                    label: 'Email Address',
                    hint: 'Email',
                    icon: Icons.email_outlined,
                    controller: c.email,
                    locked: true,
                  ),
                  const SizedBox(height: 14),
                  AuthField(
                    label: 'Phone Number',
                    hint: 'Phone',
                    icon: Icons.phone_outlined,
                    controller: c.phone,
                    locked: true,
                  ),
                  const SizedBox(height: 20),
                  Obx(() => PrimaryButton(
                        label: 'UPDATE PROFILE',
                        loading: c.savingProfile.value,
                        onPressed: c.updateProfile,
                      )),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Password change card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F1E3D), Color(0xFF0C142B)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SECURITY PASSWORD',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      )),
                  const SizedBox(height: 16),
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
                        const SizedBox(height: 14),
                        AuthField(
                          label: 'New Password',
                          hint: 'At least 8 chars, 1 letter & 1 number',
                          icon: Icons.lock_outline,
                          controller: c.next,
                          isPassword: true,
                          autofillHints: const [AutofillHints.newPassword],
                          validator: Validators.password,
                        ),
                        const SizedBox(height: 14),
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
                  const SizedBox(height: 20),
                  Obx(() => PrimaryButton(
                        label: 'CHANGE PASSWORD',
                        variant: ButtonVariant.red,
                        loading: c.savingPassword.value,
                        onPressed: c.changePassword,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(String name) {
    final char = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Text(
        char,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 36,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
