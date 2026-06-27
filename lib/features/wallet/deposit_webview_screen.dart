import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/core/app_constants.dart';
import '../../app/data/models/heads_up_notification.dart';
import '../../app/data/services/notification_service.dart';
import '../../app/data/services/session_service.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_shadows.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/widgets/premium_back_button.dart';
import '../../app/widgets/primary_button.dart';
import '../../app/widgets/responsive.dart';

/// Stands in for the real payment-gateway WebView (`deposit_gateway_url`).
/// In demo mode it simulates a successful payment and credits the wallet.
class DepositWebviewScreen extends StatefulWidget {
  const DepositWebviewScreen({super.key});

  @override
  State<DepositWebviewScreen> createState() => _DepositWebviewScreenState();
}

class _DepositWebviewScreenState extends State<DepositWebviewScreen> {
  late final double amount = Get.arguments as double;
  bool _processing = false;

  Future<void> _pay() async {
    setState(() => _processing = true);
    await SessionService.to.deposit(amount);
    if (!mounted) return;
    setState(() => _processing = false);
    Get.back(); // close gateway
    Get.back(); // close deposit screen → back to wallet
    NotificationService.to.showHeadsUp(
      HeadsUpNotification(
        id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Payment Success ✅',
        message: '${taka(amount)} added to your wallet.',
        kind: NotifKind.action,
        priority: NotifPriority.high,
        icon: 'wallet',
        actionText: 'Open Wallet',
        actionTarget: 'wallet',
        sound: 'coin',
      ),
      osNotify: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          leading: const PremiumBackButton(),
          title: const Text('Secure Payment')),
      body: ResponsiveCenter(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              _addressBar(context),
              const Spacer(),
              _PaymentCard(amount: amount),
              const SizedBox(height: AppSpacing.md),
              _trustRow(),
              const Spacer(),
              PrimaryButton(
                label: 'Confirm Payment',
                icon: Icons.lock_rounded,
                variant: ButtonVariant.green,
                loading: _processing,
                onPressed: _pay,
              ),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: 'Cancel',
                variant: ButtonVariant.red,
                onPressed: () => Get.back(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addressBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: context.cSurface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: context.cBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_rounded,
              color: AppColors.winningTeal, size: 15),
          const SizedBox(width: 8),
          Text('secure.squadup.gg/pay',
              style: AppTextStyles.body2.copyWith(color: context.cTextDim)),
          const Spacer(),
          Icon(Icons.refresh_rounded, color: context.cTextMuted, size: 16),
        ],
      ),
    );
  }

  Widget _trustRow() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _TrustChip(icon: Icons.verified_user_rounded, label: 'Secure'),
        SizedBox(width: 8),
        _TrustChip(icon: Icons.bolt_rounded, label: 'Instant'),
        SizedBox(width: 8),
        _TrustChip(icon: Icons.shield_rounded, label: 'Encrypted'),
      ],
    );
  }
}

/// The premium "card terminal" showing the payable amount.
class _PaymentCard extends StatelessWidget {
  final double amount;
  const _PaymentCard({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.glow(AppColors.primary, opacity: 0.3),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF2E55C4),
                      Color(0xFF1B2E63),
                      Color(0xFF0E1830),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Positioned(
              top: -40,
              right: -30,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25)),
                        ),
                        child: const Icon(Icons.lock_rounded,
                            color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Text('SquadUp Pay',
                          style: AppTextStyles.title.copyWith(
                              color: Colors.white,
                              fontSize: 14,
                              letterSpacing: 0.4)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.5)),
                        ),
                        child: Text('DEMO',
                            style: AppTextStyles.label.copyWith(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1)),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Total Payable',
                      style: AppTextStyles.body2
                          .copyWith(color: Colors.white.withValues(alpha: 0.7))),
                  const SizedBox(height: 4),
                  Text(taka(amount),
                      style: AppTextStyles.h1
                          .copyWith(color: Colors.white, fontSize: 40)),
                  const SizedBox(height: AppSpacing.lg),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                            color: Colors.white.withValues(alpha: 0.15)),
                      ),
                    ),
                    child: const SizedBox(width: double.infinity, height: 1),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet_rounded,
                          size: 15,
                          color: Colors.white.withValues(alpha: 0.7)),
                      const SizedBox(width: 8),
                      Text('Paying to SquadUp Wallet',
                          style: AppTextStyles.body2.copyWith(
                              color: Colors.white.withValues(alpha: 0.8))),
                      const Spacer(),
                      Text('256-bit SSL',
                          style: AppTextStyles.label.copyWith(
                              color: AppColors.winningTeal,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TrustChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: context.cSurface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: context.cBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.winningTeal),
          const SizedBox(width: 5),
          Text(label,
              style: AppTextStyles.label.copyWith(color: context.cTextDim)),
        ],
      ),
    );
  }
}
