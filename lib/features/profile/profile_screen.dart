import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../app/core/app_toast.dart';
import '../../app/core/app_dialogs.dart';
import '../../app/core/app_sheets.dart';
import '../../app/core/app_constants.dart';
import '../../app/core/theme_controller.dart';
import '../../app/data/services/session_service.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/widgets/brand_app_bar.dart';
import '../../app/widgets/common_widgets.dart';
import '../../app/widgets/primary_button.dart';
import '../../app/widgets/responsive.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionService.to;
    return Scaffold(
      appBar: const BrandAppBar(),
      body: ResponsiveCenter(
        child: ListView(
          // Extra bottom space so the last items (Logout) clear the floating
          // bottom nav bar (the shell uses extendBody: true).
          padding: EdgeInsets.fromLTRB(
              12, 12, 12, MediaQuery.of(context).padding.bottom + 84),
          children: [
            _ProfileHeader(),
            const SizedBox(height: 15),
            const SectionHeader('ACCOUNT'),
            const SizedBox(height: 12),
            ListNavTile(
                icon: Icons.person_outline,
                label: 'Edit Profile',
                onTap: () => Get.toNamed(AppRoutes.editProfile)),
            const SizedBox(height: 12),
            ListNavTile(
                icon: Icons.account_balance_wallet_outlined,
                label: 'My Wallet',
                onTap: () => Get.toNamed(AppRoutes.wallet)),
            const SizedBox(height: 12),
            ListNavTile(
                icon: Icons.sports_esports_outlined,
                label: 'My Matches',
                onTap: () => Get.toNamed(AppRoutes.myMatches)),
            const SizedBox(height: 12),
            ListNavTile(
                icon: Icons.receipt_long_outlined,
                label: 'Order History',
                subtitle: 'Top-ups & purchases',
                onTap: () => Get.toNamed(AppRoutes.orders)),
            const SizedBox(height: 12),
            ListNavTile(
                icon: Icons.leaderboard_outlined,
                label: 'Top Players',
                onTap: () => Get.toNamed(AppRoutes.topPlayers)),
            const SizedBox(height: 14),
            const SectionHeader('SETTINGS'),
            const SizedBox(height: 12),
            const _AppearanceTile(),
            const SizedBox(height: 14),
            const SectionHeader('MORE'),
            const SizedBox(height: 12),
            ListNavTile(
                icon: Icons.share_outlined,
                label: 'Share App',
                onTap: () => _openShare(session)),
            const SizedBox(height: 12),
            ListNavTile(
                icon: Icons.gavel_outlined,
                label: 'Match Rules',
                onTap: () => Get.toNamed(AppRoutes.matchRules)),
            const SizedBox(height: 12),
            ListNavTile(
                icon: Icons.description_outlined,
                label: 'Terms & Conditions',
                onTap: () => Get.toNamed(AppRoutes.terms)),
            const SizedBox(height: 12),
            ListNavTile(
                icon: Icons.code,
                label: 'Developer Profile',
                onTap: () => Get.toNamed(AppRoutes.developer)),
            const SizedBox(height: 12),
            ListNavTile(
              icon: Icons.logout,
              label: 'Logout',
              iconColor: AppColors.danger,
              onTap: () => _confirmLogout(session),
            ),
            const SizedBox(height: 13),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(SessionService session) async {
    final ok = await AppDialogs.confirm(
      title: 'Logout',
      message: 'Are you sure you want to logout of your account?',
      confirmText: 'Logout',
      destructive: true,
    );
    if (ok) {
      session.logout();
      Get.offAllNamed(AppRoutes.login);
    }
  }
}

void _openShare(SessionService session) {
  final code = session.user.value?.referCode ?? 'SQUADUP';
  AppSheet.show(
    title: 'Share SquadUp',
    subtitle: 'Invite friends with your referral code and earn rewards.',
    child: _ShareSheet(code: code),
  );
}

class _ShareSheet extends StatelessWidget {
  final String code;
  const _ShareSheet({required this.code});

  String get _invite =>
      'Join me on ${AppConstants.appName} 🎮 Play Free Fire tournaments and win cash! '
      'Use my referral code $code when you sign up.';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.card_giftcard_rounded, color: AppColors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(code,
                    style: AppTextStyles.h2
                        .copyWith(color: AppColors.primary, letterSpacing: 2)),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: code));
                  AppToast.success('Referral code copied');
                },
                child: const Icon(Icons.copy_rounded,
                    color: AppColors.primary, size: 20),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: 'Copy Invite Message',
          icon: Icons.ios_share_rounded,
          onPressed: () {
            Clipboard.setData(ClipboardData(text: _invite));
            Get.back();
            AppToast.success('Invite message copied — paste it anywhere!');
          },
        ),
      ],
    );
  }
}

class _AppearanceTile extends StatelessWidget {
  const _AppearanceTile();

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.to;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      child: Obx(() {
        final dark = theme.isDark;
        return Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                  dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: AppColors.primary,
                  size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dark Mode',
                      style: AppTextStyles.body1.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyLarge?.color)),
                  Text(dark ? 'On' : 'Off', style: AppTextStyles.body2),
                ],
              ),
            ),
            Switch.adaptive(
              value: dark,
              // Active color comes from colorScheme.primary (AppColors.primary),
              // so no explicit (version-sensitive) color arg is needed.
              onChanged: (_) => theme.toggle(),
            ),
          ],
        );
      }),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final session = SessionService.to;
    return AppCard(
      child: Obx(() {
        final user = session.user.value;
        final wallet = session.wallet.value;
        return Column(
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.5)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(AppConstants.logo,
                        fit: BoxFit.cover, cacheWidth: 160),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.name ?? 'Guest',
                        style: AppTextStyles.h2.copyWith(fontSize: 18)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.5)),
                      ),
                      child: Text('UID : ${user?.uid ?? '#0'}',
                          style: AppTextStyles.label
                              .copyWith(color: AppColors.primary)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.cBgAlt,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.cBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Available Balance',
                            style: AppTextStyles.body2),
                        const SizedBox(height: 4),
                        Text(taka(wallet.availableBalance),
                            style: AppTextStyles.h1.copyWith(fontSize: 24)),
                        const SizedBox(height: 8),
                        StatusPill(
                          text: 'Winnings: ${taka(wallet.winningBalance)}',
                          color: AppColors.winningTeal,
                          showDot: false,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: PrimaryButton(
                      label: 'ADD',
                      icon: Icons.add,
                      variant: ButtonVariant.green,
                      height: 42,
                      onPressed: () => Get.toNamed(AppRoutes.deposit),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 11),
            Row(
              children: [
                _stat(Icons.sports_esports, AppColors.gold,
                    '${user?.totalMatchesPlayed ?? 0}', 'Matches'),
                const SizedBox(width: 12),
                _stat(Icons.military_tech, AppColors.gold,
                    '${user?.totalMatchesWon ?? 0}', 'Wins'),
                const SizedBox(width: 12),
                _stat(Icons.currency_exchange, AppColors.gold,
                    taka(wallet.wonAmount), 'Earnings'),
              ],
            ),
          ],
        );
      }),
    );
  }

  Widget _stat(IconData icon, Color color, String value, String label) {
    return Expanded(
      child: StatCell(
          icon: icon,
          iconColor: color,
          value: value,
          label: label,
          valueFirst: true),
    );
  }
}
