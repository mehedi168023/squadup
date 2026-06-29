import 'package:flutter/material.dart';
import '../../app/widgets/premium_back_button.dart';
import 'package:get/get.dart';
import '../../app/core/app_constants.dart';
import '../../app/core/app_loader.dart';
import '../../app/core/app_sheets.dart';
import '../../app/core/app_toast.dart';
import '../../app/data/models/misc_models.dart';
import '../../app/data/services/session_service.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/widgets/primary_button.dart';
import '../../app/widgets/responsive.dart';

/// Step-based top-up screen (Enter UID → Select Pack → Payment), driven by a
/// [TopupCategory] (Free Fire diamonds / Ludo Kingpass coins).
class TopupScreen extends StatefulWidget {
  const TopupScreen({super.key});

  @override
  State<TopupScreen> createState() => _TopupScreenState();
}

class _TopupScreenState extends State<TopupScreen> {
  final TopupCategory cat = Get.arguments as TopupCategory;
  final _userId = TextEditingController();
  int _pack = -1;
  int _payment = 0; // 0 = SquadUp, 1 = Direct Gateway

  List<(String, String, bool)> get _paymentsList => [
    ('SquadUp Wallet', 'Winnings Balance: ৳${SessionService.to.wallet.value.winningBalance.toStringAsFixed(2)}', true),
    ('Direct Gateway', 'Secure • Instant • Easy', false),
  ];

  @override
  void dispose() {
    _userId.dispose();
    super.dispose();
  }

  Future<void> _buy() async {
    if (_userId.text.trim().isEmpty) {
      AppToast.warning('Enter your ${cat.idLabel} first');
      return;
    }
    if (_pack < 0) {
      AppToast.warning('Select a pack');
      return;
    }
    final p = cat.packs[_pack];

    if (_payment == 0) {
      // SquadUp Wallet payment: check winning balance
      final winningBal = SessionService.to.wallet.value.winningBalance;
      if (winningBal < p.price) {
        AppToast.warning('ইনসাফিসিয়েন্ট উইনিং ব্যালেন্স (মিনিমাম ৳${p.price.toStringAsFixed(2)} লাগবে)');
        return;
      }
      
      AppLoader.show();
      final ok = await SessionService.to.submitTopupOrder(
        categoryKey: cat.key,
        packId: _pack,
        gameUserId: _userId.text.trim(),
        price: p.price,
        amount: p.amount,
        unit: p.unit,
        paymentMethod: 'wallet',
      );
      AppLoader.dismiss();
      if (!ok || !mounted) return;
      AppToast.success('Order placed successfully using SquadUp Wallet!');
    } else {
      // Direct Gateway: open payment webview screen
      Get.toNamed(
        AppRoutes.depositWebview,
        arguments: {
          'amount': p.price,
          'closeDouble': false,
          'isOrderPayment': true,
        },
      )?.then((completed) async {
        if (completed == true) {
          AppLoader.show();
          final ok = await SessionService.to.submitTopupOrder(
            categoryKey: cat.key,
            packId: _pack,
            gameUserId: _userId.text.trim(),
            price: p.price,
            amount: p.amount,
            unit: p.unit,
            paymentMethod: 'gateway',
          );
          AppLoader.dismiss();
          if (ok) {
            AppToast.success('Order placed successfully via Gateway!');
          }
        }
      });
    }
  }

  void _openHowTo() {
    AppSheet.show(
      title: 'Help & Guide',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final s in cat.howTo) ...[
            Text(s.title,
                style: AppTextStyles.title
                    .copyWith(color: AppColors.primary, fontSize: 15)),
            const SizedBox(height: AppSpacing.sm),
            for (int i = 0; i < s.steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('${i + 1}. ${s.steps[i]}',
                    style: AppTextStyles.body1.copyWith(height: 1.5)),
              ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (cat.guideImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Image.asset(cat.guideImage!,
                  width: double.infinity, fit: BoxFit.contain, cacheWidth: 900),
            ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF081026),
      appBar: AppBar(
        leading: const PremiumBackButton(),
        title: Text(cat.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF081026),
        elevation: 0,
        centerTitle: true,
      ),
      body: ResponsiveCenter(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          children: [
            // STEP 01 — Enter UID.
            _StepCard(
              step: '01',
              lead: 'ENTER ',
              accent: 'GAME UID',
              subtitle: 'Enter your ${cat.idLabel} to top-up',
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _userId,
                              textInputAction: TextInputAction.done,
                              style: AppTextStyles.body1.copyWith(fontSize: 15, color: const Color(0xFF0D2C54)),
                              decoration: InputDecoration(
                                hintText: 'Enter your ${cat.idLabel}',
                                hintStyle: TextStyle(color: const Color(0xFF5C728D).withValues(alpha: 0.6)),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF1976D2)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFD4E3F7), width: 1.2),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFF1976D2), width: 1.6),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 80), // Reserve space for chest graphic overlay
                        ],
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _openHowTo,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.help_outline_rounded,
                                size: 16, color: Color(0xFF1976D2)),
                            const SizedBox(width: 6),
                            Text('How to find UID?',
                                style: AppTextStyles.label
                                    .copyWith(color: const Color(0xFF1976D2), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    right: -10,
                    bottom: -20,
                    child: Image.asset(
                      cat.key.contains('ludo')
                          ? 'assets/images/kingpass/coin6.webp'
                          : 'assets/images/topup/diamond6.webp',
                      width: 90,
                      height: 90,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // STEP 02 — Select pack.
            _StepCard(
              step: '02',
              lead: 'SELECT ',
              accent: 'PACK',
              subtitle: 'Choose the best pack for you',
              trailing: const _BigSavingBadge(),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cat.packs.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.52,
                ),
                itemBuilder: (_, i) => _PackCard(
                  pack: cat.packs[i],
                  index: i,
                  icon: cat.packIcon,
                  selected: _pack == i,
                  categoryKey: cat.key,
                  onTap: () => setState(() => _pack = i),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // STEP 03 — Payment.
            _StepCard(
              step: '03',
              lead: 'SELECT ',
              accent: 'PAYMENT METHOD',
              subtitle: 'Choose your preferred payment method',
              child: Column(
                children: [
                  for (int i = 0; i < _paymentsList.length; i++) ...[
                    _PaymentTile(
                      name: _paymentsList[i].$1,
                      subtitle: _paymentsList[i].$2,
                      recommended: _paymentsList[i].$3,
                      selected: _payment == i,
                      onTap: () => setState(() => _payment = i),
                    ),
                    if (i != _paymentsList.length - 1)
                      const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: _pack < 0
                  ? 'PROCEED TO PAY'
                  : 'PROCEED TO PAY  ${taka(cat.packs[_pack].price)}',
              icon: Icons.lock_outline,
              variant: ButtonVariant.green,
              onPressed: _buy,
            ),
            const SizedBox(height: AppSpacing.xl),
            if (cat.perks.isNotEmpty) _Perks(perks: cat.perks),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String step;
  final String lead;
  final String accent;
  final String subtitle;
  final Widget child;
  final Widget? trailing;
  const _StepCard({
    required this.step,
    required this.lead,
    required this.accent,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEDF4FC), Color(0xFFFFFFFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4E3F7), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A1E3D).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _StepBadge(step: step),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: AppTextStyles.h2.copyWith(
                            color: const Color(0xFF0D2C54), fontSize: 18, height: 1.1),
                        children: [
                          TextSpan(text: lead),
                          TextSpan(
                              text: accent,
                              style: const TextStyle(color: Color(0xFF1976D2), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: AppTextStyles.body2
                            .copyWith(color: const Color(0xFF5C728D), fontSize: 11)),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  final String step;
  const _StepBadge({required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2196F3), Color(0xFF0D47A1)],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D47A1).withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        children: [
          Text('STEP',
              style: AppTextStyles.caption
                  .copyWith(color: Colors.white.withValues(alpha: 0.9), fontSize: 7, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          Text(step,
              style:
                  AppTextStyles.h2.copyWith(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _BigSavingBadge extends StatelessWidget {
  const _BigSavingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFD32F2F),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFFFCDD2), width: 1.0),
      ),
      child: const Column(
        children: [
          Text(
            'SAVE UP TO',
            style: TextStyle(
              color: Colors.white,
              fontSize: 7,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '৳90',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          Text(
            'ON BIG PACKS!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 6,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _PackCard extends StatelessWidget {
  final TopupPack pack;
  final int index;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final String categoryKey;

  const _PackCard({
    required this.pack,
    required this.index,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.categoryKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = PackTheme.getForIndex(index);
    final clampIdx = (index + 1).clamp(1, 9);
    final isLudo = categoryKey.contains('ludo');
    final String imagePath = isLudo
        ? 'assets/images/kingpass/coin$clampIdx.webp'
        : 'assets/images/topup/diamond$clampIdx.webp';

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: AppDurations.fast,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: theme.bgGradient,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? theme.borderSelectedColor : const Color(0xFFD4E3F7),
                width: selected ? 2.0 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: selected
                      ? theme.borderSelectedColor.withValues(alpha: 0.25)
                      : const Color(0xFF0A1E3D).withValues(alpha: 0.04),
                  blurRadius: selected ? 10 : 6,
                  spreadRadius: selected ? 1 : 0,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Header badge "PACK N"
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.headerColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Text(
                    'PACK ${index + 1}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                
                // Pack Graphic Image
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // Amount Text
                Text(
                  pack.amount,
                  style: const TextStyle(
                    color: Color(0xFF0D2C54),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                Text(
                  pack.unit.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF5C728D),
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),

                // Pricing
                Text(
                  taka(pack.regularPrice),
                  style: const TextStyle(
                    color: Color(0xFFD32F2F),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(height: 2),

                // Taka Price yellow button
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFA000), width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFA000).withValues(alpha: 0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Center(
                    child: Text(
                      taka(pack.price),
                      style: const TextStyle(
                        color: Color(0xFF4E3400),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Save footer banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  color: theme.footerColor,
                  child: Text(
                    'SAVE ${taka(pack.save)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // BEST VALUE Badge (Only for index == 1 / Pack 2)
          if (index == 1)
            Positioned(
              top: -6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD32F2F).withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: const Text(
                  'BEST VALUE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final bool recommended;
  final bool selected;
  final VoidCallback onTap;
  const _PaymentTile({
    required this.name,
    required this.subtitle,
    required this.recommended,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFE8F5E9)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF2E7D32) : const Color(0xFFD4E3F7),
            width: selected ? 1.6 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A1E3D).withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2196F3), Color(0xFF0D47A1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                name.split(' ').map((w) => w[0]).take(2).join(),
                style: AppTextStyles.h3.copyWith(color: Colors.white, fontSize: 14),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.title.copyWith(fontSize: 14, color: const Color(0xFF0D2C54)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.body2.copyWith(color: const Color(0xFF5C728D), fontSize: 11),
                  ),
                  if (recommended) ...[
                    const SizedBox(height: 2),
                    const Text(
                      'RECOMMENDED',
                      style: TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected ? const Color(0xFF2E7D32) : const Color(0xFF5C728D),
            ),
          ],
        ),
      ),
    );
  }
}

class _Perks extends StatelessWidget {
  final List<String> perks;
  const _Perks({required this.perks});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final p in perks)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEDF4FC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD4E3F7), width: 1.0),
            ),
            child: Text(
              p,
              style: AppTextStyles.label.copyWith(color: const Color(0xFF0D2C54), fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}

class PackTheme {
  final List<Color> bgGradient;
  final Color headerColor;
  final Color footerColor;
  final Color borderSelectedColor;

  const PackTheme({
    required this.bgGradient,
    required this.headerColor,
    required this.footerColor,
    required this.borderSelectedColor,
  });

  static PackTheme getForIndex(int index) {
    switch (index % 6) {
      case 0: // Blue
        return const PackTheme(
          bgGradient: [Color(0xFFEBF3FC), Color(0xFFFFFFFF)],
          headerColor: Color(0xFF1E88E5),
          footerColor: Color(0xFF0D47A1),
          borderSelectedColor: Color(0xFF1565C0),
        );
      case 1: // Green (Best Value)
        return const PackTheme(
          bgGradient: [Color(0xFFEEF9F1), Color(0xFFFFFFFF)],
          headerColor: Color(0xFF43A047),
          footerColor: Color(0xFF1B5E20),
          borderSelectedColor: Color(0xFF2E7D32),
        );
      case 2: // Purple
        return const PackTheme(
          bgGradient: [Color(0xFFF7EFFB), Color(0xFFFFFFFF)],
          headerColor: Color(0xFF8E24AA),
          footerColor: Color(0xFF4A148C),
          borderSelectedColor: Color(0xFF6A1B9A),
        );
      case 3: // Orange
        return const PackTheme(
          bgGradient: [Color(0xFFFFF3E0), Color(0xFFFFFFFF)],
          headerColor: Color(0xFFF57C00),
          footerColor: Color(0xFFE65100),
          borderSelectedColor: Color(0xFFEF6C00),
        );
      case 4: // Pink
        return const PackTheme(
          bgGradient: [Color(0xFFFCE4EC), Color(0xFFFFFFFF)],
          headerColor: Color(0xFFD81B60),
          footerColor: Color(0xFF880E4F),
          borderSelectedColor: Color(0xFFC2185B),
        );
      case 5: // Golden
        return const PackTheme(
          bgGradient: [Color(0xFFFFFDE7), Color(0xFFFFFFFF)],
          headerColor: Color(0xFFFBC02D),
          footerColor: Color(0xFFF57F17),
          borderSelectedColor: Color(0xFFF9A825),
        );
      default:
        return const PackTheme(
          bgGradient: [Color(0xFFEBF3FC), Color(0xFFFFFFFF)],
          headerColor: Color(0xFF1E88E5),
          footerColor: Color(0xFF0D47A1),
          borderSelectedColor: Color(0xFF1565C0),
        );
    }
  }
}
