import 'package:flutter/material.dart';
import '../../app/widgets/premium_back_button.dart';
import 'package:get/get.dart';
import '../../app/core/app_constants.dart';
import '../../app/data/models/match_model.dart';
import '../../app/data/services/session_service.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/widgets/common_widgets.dart';
import '../../app/widgets/primary_button.dart';
import '../../app/widgets/responsive.dart';

enum _LudoFilter { all, mine, lowHigh, highLow }

class LudoMatchListScreen extends StatefulWidget {
  const LudoMatchListScreen({super.key});

  @override
  State<LudoMatchListScreen> createState() => _LudoMatchListScreenState();
}

class _LudoMatchListScreenState extends State<LudoMatchListScreen> {
  final GameMode mode = Get.arguments as GameMode;
  final session = SessionService.to;
  _LudoFilter filter = _LudoFilter.all;

  List<FfMatch> _apply(List<FfMatch> source) {
    final list = [...source];
    switch (filter) {
      case _LudoFilter.mine:
        return list.where((m) => m.isJoined).toList();
      case _LudoFilter.lowHigh:
        list.sort((a, b) => a.entryFee.compareTo(b.entryFee));
      case _LudoFilter.highLow:
        list.sort((a, b) => b.entryFee.compareTo(a.entryFee));
      case _LudoFilter.all:
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const PremiumBackButton(), 
        title: Text(mode.title),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: _WinSsButton(),
          ),
        ],
      ),
      body: ResponsiveCenter(
        child: Column(
          children: [
            _FilterBar(
              current: filter,
              onSelect: (f) => setState(() => filter = f),
            ),
            Expanded(
              child: Obx(() {
                final list = _apply(session.matchesForMode(mode.key));
                if (list.isEmpty) {
                  return const Center(
                    child: EmptyState(
                      icon: Icons.casino_outlined,
                      title: 'No matches here',
                      hint: 'Try another filter or pull to refresh',
                    ),
                  );
                }
                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                      12, 12, 12, MediaQuery.of(context).padding.bottom + 24),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (_, i) =>
                      RepaintBoundary(child: _LudoMatchCard(match: list[i])),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// Header button (right side) → Win-screenshot upload screen.
class _WinSsButton extends StatelessWidget {
  const _WinSsButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.uploadEvidence),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.matchesGreen.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border:
              Border.all(color: AppColors.matchesGreen.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_upload_outlined,
                size: 16, color: AppColors.matchesGreen),
            const SizedBox(width: 6),
            Text('Win SS',
                style: AppTextStyles.label.copyWith(
                    color: AppColors.matchesGreen,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final _LudoFilter current;
  final ValueChanged<_LudoFilter> onSelect;
  const _FilterBar({required this.current, required this.onSelect});

  static const _items = [
    (_LudoFilter.all, Icons.sports_esports, 'All Matches'),
    (_LudoFilter.mine, Icons.person, 'My Match'),
    (_LudoFilter.lowHigh, Icons.trending_up, 'Low to High'),
    (_LudoFilter.highLow, Icons.trending_down, 'High to Low'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final item = _items[i];
          final active = current == item.$1;
          return GestureDetector(
            onTap: () => onSelect(item.$1),
            child: AnimatedContainer(
              duration: AppDurations.fast,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active
                    ? AppColors.matchesGreen.withValues(alpha: 0.16)
                    : context.cSurface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: active ? AppColors.matchesGreen : context.cBorder,
                  width: active ? 1.4 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(item.$2,
                      size: 17,
                      color:
                          active ? AppColors.matchesGreen : context.cTextDim),
                  const SizedBox(width: 7),
                  Text(item.$3,
                      style: AppTextStyles.title.copyWith(
                        fontSize: 13,
                        color:
                            active ? AppColors.matchesGreen : context.cTextDim,
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LudoMatchCard extends StatelessWidget {
  final FfMatch match;
  const _LudoMatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final joined = match.isJoined;
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
            children: [
              const Icon(Icons.emoji_events_rounded,
                  color: AppColors.gold, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('${match.title} MATCH ${match.code}',
                    style: AppTextStyles.title.copyWith(fontSize: 15)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: context.cBorder),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF15294D), Color(0xFF101826)],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                child: const Icon(Icons.casino_rounded,
                    color: AppColors.primary, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _stat(context, 'ENTRY FEE', taka(match.entryFee),
                        AppColors.gold),
                    _stat(context, 'WIN PRIZE', taka(match.prize),
                        AppColors.matchesGreen),
                    _stat(
                        context,
                        'PLAYERS',
                        '${match.slotsTaken}/${match.slotsTotal}',
                        AppColors.matchesGreen),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 78,
                child: PrimaryButton(
                  label: joined ? 'JOINED' : 'JOIN',
                  height: 44,
                  onPressed: joined
                      ? null
                      : () => Get.toNamed(AppRoutes.ludoJoin, arguments: match),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: context.cTextMuted, fontSize: 9)),
        const SizedBox(height: 3),
        Text(value,
            style: AppTextStyles.title.copyWith(fontSize: 14, color: color)),
      ],
    );
  }
}
