import 'package:flutter/material.dart';
import '../../app/widgets/premium_back_button.dart';
import 'package:get/get.dart';
import '../../app/core/app_constants.dart';
import '../../app/core/app_toast.dart';
import '../../app/data/models/heads_up_notification.dart';
import '../../app/data/models/match_model.dart';
import '../../app/data/services/notification_service.dart';
import '../../app/data/services/session_service.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/widgets/primary_button.dart';
import '../../app/widgets/responsive.dart';

/// Ludo join screen — match header, entry/prize cards and game-name entry.
class LudoJoinScreen extends StatefulWidget {
  const LudoJoinScreen({super.key});

  @override
  State<LudoJoinScreen> createState() => _LudoJoinScreenState();
}

class _LudoJoinScreenState extends State<LudoJoinScreen> {
  final FfMatch match = Get.arguments as FfMatch;
  late final TextEditingController _name =
      TextEditingController(text: SessionService.to.user.value?.name ?? '');
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    if (_name.text.trim().isEmpty) {
      AppToast.warning('আপনার গেম নাম দিন');
      return;
    }
    setState(() => _loading = true);
    final ok = await SessionService.to.joinMatch(match, [_name.text.trim()]);
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      Get.back();
      NotificationService.to.showHeadsUp(
        HeadsUpNotification(
          id: 'ludojoin_${match.id}',
          title: 'জয়েন সফল হয়েছে! 🎲',
          message: '${match.title} ম্যাচে আপনি যুক্ত হয়েছেন।',
          kind: NotifKind.action,
          priority: NotifPriority.high,
          icon: 'match',
          actionText: 'View My Matches',
          actionTarget: 'my_matches',
          sound: 'success',
        ),
        osNotify: true,
      );
    } else {
      AppToast.error('জয়েন ব্যর্থ হয়েছে।');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const PremiumBackButton(), title: const Text('Join Match')),
      body: ResponsiveCenter(
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _IosCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('SPECIAL MATCH ${match.code}',
                            style: AppTextStyles.h2.copyWith(fontSize: 19)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                              color: AppColors.matchesGreen
                                  .withValues(alpha: 0.5)),
                        ),
                        child: Text('MATCH',
                            style: AppTextStyles.label.copyWith(
                                color: AppColors.matchesGreen,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 14, color: AppColors.matchesGreen),
                      const SizedBox(width: 6),
                      Text(fullDateWeekday(match.startTime),
                          style: AppTextStyles.label
                              .copyWith(color: context.cTextDim)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _PrizeCard(
                    label: 'এন্ট্রি ফি',
                    value: taka(match.entryFee),
                    icon: Icons.confirmation_num_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _PrizeCard(
                    label: 'জয়ের পুরস্কার',
                    value: taka(match.prize),
                    icon: Icons.emoji_events_outlined,
                    color: AppColors.matchesGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _IosCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          color: AppColors.matchesGreen, size: 20),
                      const SizedBox(width: 8),
                      Text('আপনার গেম নাম',
                          style: AppTextStyles.h3.copyWith(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _name,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _join(),
                    style: AppTextStyles.body1.copyWith(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'আপনার গেম নাম লিখুন',
                      fillColor: context.cBgAlt,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    label: 'জয়েন করুন',
                    variant: ButtonVariant.green,
                    loading: _loading,
                    onPressed: _join,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'জয়েন করলে এন্ট্রি ফি আপনার ব্যালেন্স/উইন থেকে কাটা হবে।',
                    style:
                        AppTextStyles.body2.copyWith(color: context.cTextMuted),
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

class _PrizeCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _PrizeCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _IosCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        AppTextStyles.label.copyWith(color: context.cTextDim)),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value,
                      style: AppTextStyles.h1
                          .copyWith(fontSize: 24, color: color)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
        ],
      ),
    );
  }
}

class _IosCard extends StatelessWidget {
  final Widget child;
  const _IosCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.cBorder),
      ),
      child: child,
    );
  }
}
