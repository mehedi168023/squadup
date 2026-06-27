import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/core/app_sheets.dart';
import '../../app/core/app_constants.dart';
import '../../app/data/models/wallet_model.dart';
import '../../app/data/services/session_service.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_shadows.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/widgets/common_widgets.dart';
import '../../app/widgets/premium_back_button.dart';
import '../../app/widgets/primary_button.dart';
import '../../app/widgets/responsive.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionService.to;
    return Scaffold(
      appBar: AppBar(
          leading: const PremiumBackButton(), title: const Text('My Wallet')),
      body: ResponsiveCenter(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
              12, 12, 12, MediaQuery.of(context).padding.bottom + 24),
          children: [
            Obx(() => _BalanceHero(wallet: session.wallet.value)),
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(child: SectionHeader('RECENT ACTIVITY')),
                GestureDetector(
                  onTap: () => Get.toNamed(AppRoutes.transactions),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      Text('See all',
                          style: AppTextStyles.label
                              .copyWith(color: AppColors.primary)),
                      const Icon(Icons.chevron_right_rounded,
                          size: 18, color: AppColors.primary),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Obx(() {
              final txs = session.transactions.take(3).toList();
              if (txs.isEmpty) {
                return AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          color: context.cTextMuted, size: 20),
                      const SizedBox(width: 12),
                      Text('No transactions yet',
                          style: AppTextStyles.body1
                              .copyWith(color: context.cTextDim)),
                    ],
                  ),
                );
              }
              return Column(
                children: [
                  for (final tx in txs) ...[
                    _MiniTxRow(tx: tx),
                    if (tx != txs.last) const SizedBox(height: 10),
                  ],
                ],
              );
            }),
            const SizedBox(height: 18),
            const SectionHeader('QUICK ACTIONS'),
            const SizedBox(height: 12),
            ListNavTile(
              icon: Icons.receipt_long_outlined,
              label: 'Transaction History',
              subtitle: 'View all your transactions',
              onTap: () => Get.toNamed(AppRoutes.transactions),
            ),
            const SizedBox(height: 12),
            ListNavTile(
              icon: Icons.shopping_bag_outlined,
              label: 'Order History',
              subtitle: 'Top-ups & purchases',
              iconColor: AppColors.winningTeal,
              onTap: () => Get.toNamed(AppRoutes.orders),
            ),
            const SizedBox(height: 18),
            const SectionHeader('HOW TO GUIDE'),
            const SizedBox(height: 12),
            _guide(context, Icons.add_card, 'How to Add Money?', const [
              'Open the Wallet and tap “Add Money”.',
              'Enter the amount you want to deposit.',
              'Tap “Proceed to Payment” and complete it on the secure gateway.',
              'Your balance is credited instantly after a successful payment.',
            ]),
            const SizedBox(height: 12),
            _guide(context, Icons.sports_esports_outlined,
                'How to Join a Match?', const [
              'Pick a game mode from the Home screen.',
              'Open a match to review the rules and prize pool.',
              'Tap “Join Match”, choose your slot type and enter player names.',
              'The entry fee is deducted and your slot is confirmed.',
            ]),
            const SizedBox(height: 12),
            _guide(context, Icons.account_balance_outlined,
                'How to Withdraw?', const [
              'Open the Wallet and tap “Withdraw”.',
              'Choose bKash or Nagad and enter your wallet number.',
              'Enter an amount between ৳105 and ৳10000.',
              'Submit — your request is processed to the selected channel.',
            ]),
          ],
        ),
      ),
    );
  }

  Widget _guide(
      BuildContext context, IconData icon, String title, List<String> steps) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => _openGuide(icon, title, steps),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: context.cSurfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: context.cTextDim, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Text(title,
                  style: AppTextStyles.title.copyWith(fontSize: 15))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.menu_book_rounded,
                    size: 15, color: AppColors.primary),
                const SizedBox(width: 4),
                Text('Guide',
                    style:
                        AppTextStyles.label.copyWith(color: AppColors.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void _openGuide(IconData icon, String title, List<String> steps) {
    AppSheet.show(
      title: title,
      subtitle: 'Follow these steps:',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Text('${i + 1}',
                        style: AppTextStyles.title
                            .copyWith(color: AppColors.primary, fontSize: 13)),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(steps[i],
                        style: AppTextStyles.body1.copyWith(height: 1.5)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Premium credit-card style wallet hero: deep gradient + depth glow, a brand
/// wordmark, a metallic chip & contactless mark, an animated light-sweep, a
/// masked card number (from the user's id), a balance privacy toggle, glass
/// sub-balance tiles and the Add/Withdraw actions.
class _BalanceHero extends StatefulWidget {
  final WalletModel wallet;
  const _BalanceHero({required this.wallet});

  @override
  State<_BalanceHero> createState() => _BalanceHeroState();
}

class _BalanceHeroState extends State<_BalanceHero> {
  bool _hidden = false;

  String get _maskedNumber {
    final id = SessionService.to.user.value?.id ?? 0;
    final last = id.toString().padLeft(4, '0');
    final tail = last.substring(last.length - 4);
    return '••••  ••••  ••••  $tail';
  }

  String get _holder =>
      (SessionService.to.user.value?.name ?? 'SquadUp Member').toUpperCase();

  @override
  Widget build(BuildContext context) {
    final wallet = widget.wallet;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.glow(AppColors.primary, opacity: 0.32),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Stack(
          children: [
            // Base gradient.
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
            // Soft depth circles.
            Positioned(
                top: -50,
                right: -30,
                child: _circle(110, Colors.white.withValues(alpha: 0.06))),
            Positioned(
                bottom: -55,
                left: -40,
                child:
                    _circle(140, AppColors.winningTeal.withValues(alpha: 0.07))),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text('SquadUp Wallet',
                          style: AppTextStyles.title.copyWith(
                              color: Colors.white,
                              fontSize: 14,
                              letterSpacing: 0.4)),
                      const Spacer(),
                      _pill(Icons.lock_rounded, 'Secured'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Chip + contactless + PREMIUM tag (one compact row).
                  Row(
                    children: [
                      _chip(),
                      const SizedBox(width: 9),
                      Transform.rotate(
                        angle: 1.5708,
                        child: Icon(Icons.wifi_rounded,
                            size: 17,
                            color: Colors.white.withValues(alpha: 0.8)),
                      ),
                      const Spacer(),
                      Text('PREMIUM',
                          style: AppTextStyles.label.copyWith(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Available Balance',
                              style: AppTextStyles.body2.copyWith(
                                  color: Colors.white.withValues(alpha: 0.7))),
                          const SizedBox(height: 1),
                          Text(
                              _hidden
                                  ? '৳ • • • • •'
                                  : taka(wallet.availableBalance),
                              style: AppTextStyles.h1.copyWith(
                                  color: Colors.white, fontSize: 27)),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _hidden = !_hidden),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 3, left: 8),
                          child: Icon(
                              _hidden
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              size: 19,
                              color: Colors.white.withValues(alpha: 0.7)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Masked card number + holder on one line.
                  Row(
                    children: [
                      Expanded(
                        child: Text(_maskedNumber,
                            style: AppTextStyles.title.copyWith(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontSize: 13.5,
                                letterSpacing: 1.2)),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(_holder,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: AppTextStyles.label.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                                letterSpacing: 0.6)),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _subTile(Icons.emoji_events_rounded, 'Winning',
                            taka(wallet.winningBalance), AppColors.gold),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _subTile(
                            Icons.savings_rounded,
                            'Withdrawable',
                            taka(wallet.withdrawableBalance),
                            AppColors.winningTeal),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          label: 'Add Money',
                          icon: Icons.add,
                          variant: ButtonVariant.green,
                          height: 44,
                          onPressed: () => Get.toNamed(AppRoutes.deposit),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: PrimaryButton(
                          label: 'Withdraw',
                          icon: Icons.arrow_upward,
                          variant: ButtonVariant.red,
                          height: 44,
                          onPressed: () => Get.toNamed(AppRoutes.withdraw),
                        ),
                      ),
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

  Widget _circle(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  Widget _pill(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.9)),
            const SizedBox(width: 4),
            Text(label,
                style: AppTextStyles.label.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w700)),
          ],
        ),
      );

  // Metallic EMV-style chip.
  Widget _chip() => Container(
        width: 34,
        height: 25,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF3D58A), Color(0xFFC79A3F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        ),
        child: Center(
          child: Container(
            width: 22,
            height: 16,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              border:
                  Border.all(color: const Color(0xFF8A6A1E), width: 1),
            ),
          ),
        ),
      );

  Widget _subTile(IconData icon, String label, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: accent),
              const SizedBox(width: 6),
              Text(label,
                  style: AppTextStyles.label
                      .copyWith(color: Colors.white.withValues(alpha: 0.75))),
            ],
          ),
          const SizedBox(height: 5),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.title
                  .copyWith(color: Colors.white, fontSize: 15.5)),
        ],
      ),
    );
  }
}

/// A compact transaction row for the wallet's recent-activity preview.
class _MiniTxRow extends StatelessWidget {
  final TransactionModel tx;
  const _MiniTxRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    final credit = tx.isCredit;
    final color = credit ? AppColors.winningTeal : AppColors.danger;
    return AppCard(
      padding: const EdgeInsets.all(11),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(credit ? Icons.south_west : Icons.north_east,
                color: color, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.description.isEmpty ? tx.type.name : tx.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body1
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('${tx.method} • ${shortDateTime(tx.date)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body2.copyWith(color: context.cTextDim)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('${credit ? '+' : '-'}${taka(tx.amount)}',
              style: AppTextStyles.title.copyWith(color: color, fontSize: 14.5)),
        ],
      ),
    );
  }
}
