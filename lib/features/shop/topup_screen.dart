import 'package:flutter/material.dart';
import '../../app/widgets/premium_back_button.dart';
import 'package:get/get.dart';
import '../../app/core/app_constants.dart';
import '../../app/core/app_loader.dart';
import '../../app/core/app_sheets.dart';
import '../../app/core/app_toast.dart';
import '../../app/data/models/misc_models.dart';
import '../../app/data/services/session_service.dart';
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

  static const _payments = [
    ('SquadUp', 'Fast • Secure • Reliable', true),
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
    final method = _payment == 0 ? 'wallet' : 'gateway';

    AppLoader.show();
    final ok = await SessionService.to.submitTopupOrder(
      categoryKey: cat.key,
      packId: _pack,
      gameUserId: _userId.text.trim(),
      price: p.price,
      amount: p.amount,
      unit: p.unit,
      paymentMethod: method,
    );
    AppLoader.dismiss();
    if (!ok || !mounted) return;
    AppToast.success(
        'Order #${SessionService.to.orders.first.id} placed: ${p.amount} ${p.unit} via ${_payments[_payment].$1}');
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
      appBar: AppBar(leading: const PremiumBackButton(), title: Text(cat.title)),
      body: ResponsiveCenter(
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            // STEP 01 — Enter UID.
            _StepCard(
              step: '01',
              lead: 'ENTER ',
              accent: 'GAME UID',
              subtitle: 'Enter your ${cat.idLabel} to top-up',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _userId,
                    textInputAction: TextInputAction.done,
                    style: AppTextStyles.body1.copyWith(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Enter your ${cat.idLabel}',
                      prefixIcon: const Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  GestureDetector(
                    onTap: _openHowTo,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info_outline,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text('How to find UID?',
                            style: AppTextStyles.label
                                .copyWith(color: AppColors.primary)),
                      ],
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
              trailing: const _SafeBadge(),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cat.packs.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.56,
                ),
                itemBuilder: (_, i) => _PackCard(
                  pack: cat.packs[i],
                  index: i,
                  icon: cat.packIcon,
                  selected: _pack == i,
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
                  for (int i = 0; i < _payments.length; i++) ...[
                    _PaymentTile(
                      name: _payments[i].$1,
                      subtitle: _payments[i].$2,
                      recommended: _payments[i].$3,
                      selected: _payment == i,
                      onTap: () => setState(() => _payment = i),
                    ),
                    if (i != _payments.length - 1)
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.cBorder),
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
                            color: context.cText, fontSize: 18, height: 1.1),
                        children: [
                          TextSpan(text: lead),
                          TextSpan(
                              text: accent,
                              style: const TextStyle(color: AppColors.gold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: AppTextStyles.body2
                            .copyWith(color: context.cTextDim)),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
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
      width: 44,
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3B7BF0), Color(0xFF16357D)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        children: [
          Text('STEP',
              style: AppTextStyles.caption
                  .copyWith(color: Colors.white, fontSize: 8)),
          Text(step,
              style:
                  AppTextStyles.h2.copyWith(color: Colors.white, fontSize: 20)),
        ],
      ),
    );
  }
}

class _SafeBadge extends StatelessWidget {
  const _SafeBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.matchesGreen.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border:
            Border.all(color: AppColors.matchesGreen.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_user_rounded,
              size: 13, color: AppColors.matchesGreen),
          const SizedBox(width: 5),
          Text('SAFE',
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.matchesGreen, fontWeight: FontWeight.w800)),
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
  const _PackCard({
    required this.pack,
    required this.index,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.fromLTRB(5, 8, 5, 9),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.14)
              : context.cBgAlt,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.primary : context.cBorder,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // PACK N
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text('PACK ${index + 1}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w800)),
            ),
            Icon(icon, color: AppColors.gold, size: 30),
            Column(
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(pack.amount,
                      style: AppTextStyles.h3.copyWith(fontSize: 15)),
                ),
                Text(pack.unit.toUpperCase(),
                    style: AppTextStyles.caption
                        .copyWith(color: context.cTextMuted, fontSize: 8)),
              ],
            ),
            Column(
              children: [
                Text(taka(pack.regularPrice),
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.danger,
                      fontSize: 9.5,
                      decoration: TextDecoration.lineThrough,
                    )),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(taka(pack.price),
                        style: AppTextStyles.title.copyWith(
                            color: const Color(0xFF1A1500), fontSize: 13)),
                  ),
                ),
              ],
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('SAVE ${taka(pack.save)}',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.matchesGreen,
                      fontWeight: FontWeight.w800,
                      fontSize: 9)),
            ),
          ],
        ),
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
              ? AppColors.matchesGreen.withValues(alpha: 0.1)
              : context.cBgAlt,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.matchesGreen : context.cBorder,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(name.split(' ').map((w) => w[0]).take(2).join(),
                  style: AppTextStyles.h3.copyWith(color: Colors.white)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.title.copyWith(fontSize: 15)),
                  Text(subtitle, style: AppTextStyles.body2),
                  if (recommended)
                    Text('RECOMMENDED',
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.matchesGreen,
                            fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? AppColors.matchesGreen : context.cTextMuted),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: context.cSurface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: context.cBorder),
            ),
            child: Text(p,
                style: AppTextStyles.label.copyWith(color: context.cTextDim)),
          ),
      ],
    );
  }
}
