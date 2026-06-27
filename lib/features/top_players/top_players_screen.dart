import 'package:flutter/material.dart';
import '../../app/widgets/premium_back_button.dart';
import 'package:get/get.dart';
import '../../app/core/app_constants.dart';
import '../../app/data/mock/mock_data.dart';
import '../../app/data/models/misc_models.dart';
import '../../app/data/services/session_service.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/widgets/common_widgets.dart';
import '../../app/widgets/responsive.dart';

class TopPlayersScreen extends StatefulWidget {
  const TopPlayersScreen({super.key});

  @override
  State<TopPlayersScreen> createState() => _TopPlayersScreenState();
}

class _TopPlayersScreenState extends State<TopPlayersScreen> {
  final session = SessionService.to;

  @override
  void initState() {
    super.initState();
    session.fetchLeaderboard();
  }

  Color _rankColor(int rank) => switch (rank) {
        1 => AppColors.gold,
        2 => AppColors.silver,
        3 => AppColors.bronze,
        _ => AppColors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const PremiumBackButton(), title: const Text('Top Players')),
      body: ResponsiveCenter(
        child: Obx(() {
          // Live standings, falling back to bundled demo data until loaded.
          final board = session.leaderboard.isNotEmpty
              ? session.leaderboard.toList()
              : MockData.leaderboard;
          final top3 = board.take(3).toList();
          final user = session.user.value;
          final rank = session.yourRank.value ?? MockData.yourRank;
          final earnings = session.wallet.value.wonAmount;

          return ListView(
            padding: EdgeInsets.fromLTRB(
                12, 12, 12, MediaQuery.of(context).padding.bottom + 24),
            children: [
              // Your position
              AppCard(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.3),
                    context.cSurface
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary,
                      child: Text('#$rank',
                          style: AppTextStyles.title
                              .copyWith(color: Colors.white, fontSize: 14)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Your Position',
                              style: AppTextStyles.body2),
                          Text(user?.name ?? 'Guest', style: AppTextStyles.h3),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Total Earnings',
                            style: AppTextStyles.body2),
                        Text(taka(earnings),
                            style: AppTextStyles.h3
                                .copyWith(color: AppColors.gold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (top3.length == 3) _Podium(top3: top3, rankColor: _rankColor),
              const SizedBox(height: 15),
              const SectionHeader('ALL PLAYERS'),
              const SizedBox(height: 12),
              ...board.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RankRow(entry: e, color: _rankColor(e.rank)),
                  )),
            ],
          );
        }),
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> top3;
  final Color Function(int) rankColor;
  const _Podium({required this.top3, required this.rankColor});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          const Center(
              child: Text('TOP PLAYERS', style: AppTextStyles.caption)),
          const SizedBox(height: 13),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _column(top3[1], 90, rankColor(2))),
              Expanded(child: _column(top3[0], 120, rankColor(1), crown: true)),
              Expanded(child: _column(top3[2], 70, rankColor(3))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _column(LeaderboardEntry e, double height, Color color,
      {bool crown = false}) {
    return Column(
      children: [
        Icon(crown ? Icons.workspace_premium : Icons.emoji_events,
            color: color, size: crown ? 32 : 24),
        const SizedBox(height: 6),
        Text(e.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.title.copyWith(fontSize: 13)),
        Text(taka(e.wonAmount),
            style: AppTextStyles.title.copyWith(color: color, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: 0.3),
                color.withValues(alpha: 0.05)
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          alignment: Alignment.center,
          child: Text('#${e.rank}',
              style: AppTextStyles.h2.copyWith(color: color)),
        ),
      ],
    );
  }
}

class _RankRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final Color color;
  const _RankRow({required this.entry, required this.color});

  @override
  Widget build(BuildContext context) {
    final isTop3 = entry.rank <= 3;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.cSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isTop3 ? color.withValues(alpha: 0.5) : context.cBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text('#${entry.rank}',
                style: AppTextStyles.title
                    .copyWith(color: isTop3 ? color : context.cTextDim)),
          ),
          Expanded(
              child: Text(entry.name,
                  style: AppTextStyles.title.copyWith(fontSize: 16))),
          Icon(Icons.emoji_events, color: color, size: 18),
          const SizedBox(width: 8),
          Text(taka(entry.wonAmount),
              style: AppTextStyles.title.copyWith(color: color)),
        ],
      ),
    );
  }
}
