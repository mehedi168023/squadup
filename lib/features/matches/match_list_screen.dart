import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/core/app_toast.dart';
import '../../app/widgets/premium_back_button.dart';
import 'package:get/get.dart';
import '../../app/data/models/match_model.dart';
import '../../app/data/services/session_service.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/widgets/common_widgets.dart';
import '../../app/widgets/responsive.dart';
import 'widgets/match_card.dart';

/// Lists the matches for the tapped game mode, or an empty state.
class MatchListScreen extends StatefulWidget {
  const MatchListScreen({super.key});

  @override
  State<MatchListScreen> createState() => _MatchListScreenState();
}

class _MatchListScreenState extends State<MatchListScreen> {
  // Read the route argument exactly ONCE. `Get.arguments` is global, mutable
  // state that holds the *latest* navigation's arguments — so re-reading it in
  // build() would return the next route's args (e.g. an FfMatch) whenever this
  // kept-alive page rebuilds under a child (viewport/MediaQuery changes), and
  // the `as GameMode` cast would crash. Capturing it here pins the correct value.
  final GameMode mode = Get.arguments as GameMode;
  final session = SessionService.to;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const PremiumBackButton(), title: Text(mode.title)),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: session.refreshMatches,
        child: ResponsiveCenter(
          child: Obx(() {
            final list = session.matchesForMode(mode.key);
            if (list.isEmpty) {
              // Fills the viewport so the empty state stays centered on any screen
              // size while keeping pull-to-refresh available.
              return LayoutBuilder(
                builder: (context, constraints) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: const Center(
                        child: EmptyState(
                          icon: Icons.videogame_asset_outlined,
                          title: 'No matches available right now',
                          hint: 'Pull down to refresh',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: EdgeInsets.fromLTRB(
                  12, 12, 12, MediaQuery.of(context).padding.bottom + 24),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (_, i) => MatchListCard(
                match: list[i],
                onTap: () =>
                    Get.toNamed(AppRoutes.matchInfo, arguments: list[i]),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Compact match row used in the list.
class MatchListCard extends StatelessWidget {
  final FfMatch match;
  final VoidCallback onTap;
  const MatchListCard({super.key, required this.match, required this.onTap});

  void _showPrizeDistribution(BuildContext context) {
    final isLudo = match.modeLabel.toLowerCase().contains('ludo');
    final firstPrize = match.prize1 > 0 ? match.prize1.toInt() : (match.prize * 0.40).toInt();
    final secondPrize = match.prize2 > 0 ? match.prize2.toInt() : (match.prize * 0.25).toInt();
    final thirdPrize = match.prize3 > 0 ? match.prize3.toInt() : (match.prize * 0.15).toInt();
    final fourthPrize = match.prize4 > 0 ? match.prize4.toInt() : (match.prize * 0.10).toInt();
    final fifthPrize = match.prize5 > 0 ? match.prize5.toInt() : (match.prize * 0.05).toInt();

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.cSurface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          border: Border(top: BorderSide(color: context.cBorder)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.cBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.emoji_events_outlined, color: AppColors.gold, size: 24),
                const SizedBox(width: 8),
                Text('Prize Distribution', style: AppTextStyles.h2.copyWith(fontSize: 20)),
              ],
            ),
            const SizedBox(height: 8),
            Text(match.title, style: AppTextStyles.body2.copyWith(color: context.cTextDim)),
            const Divider(height: 30),
            _prizeRow(context, '🏆 Total Prize Pool', '${match.prize.toInt()} TK', isTotal: true),
            if (!isLudo) ...[
              const SizedBox(height: 12),
              _prizeRow(context, '🥇 1st Prize', '$firstPrize TK'),
              _prizeRow(context, '🥈 2nd Prize', '$secondPrize TK'),
              _prizeRow(context, '🥉 3rd Prize', '$thirdPrize TK'),
              _prizeRow(context, '4th Prize', '$fourthPrize TK'),
              _prizeRow(context, '5th Prize', '$fifthPrize TK'),
              const Divider(height: 30),
              _prizeRow(context, '🎯 Per Kill', '${match.perKill.toInt()} TK', isPerKill: true),
            ],
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _prizeRow(BuildContext context, String label, String value, {bool isTotal = false, bool isPerKill = false}) {
    final isBold = isTotal || isPerKill;
    final color = isTotal ? AppColors.gold : (isPerKill ? AppColors.killRed : context.cText);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: isBold ? AppTextStyles.title.copyWith(fontSize: 15) : AppTextStyles.body1.copyWith(fontSize: 14)),
          Text(value, style: AppTextStyles.title.copyWith(fontSize: isBold ? 16 : 14, color: color)),
        ],
      ),
    );
  }

  void _showRoomDetails(BuildContext context) {
    final roomId = match.roomId ?? '';
    final roomPass = match.roomPassword ?? '';
    final isLudo = match.modeLabel.toLowerCase().contains('ludo');

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.cSurface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          border: Border(top: BorderSide(color: context.cBorder)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.cBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.vpn_key_outlined, color: isLudo ? AppColors.matchesGreen : AppColors.winningTeal, size: 24),
                const SizedBox(width: 8),
                Text(isLudo ? 'Room Code' : 'Room Details', style: AppTextStyles.h2.copyWith(fontSize: 20)),
              ],
            ),
            const SizedBox(height: 8),
            Text(isLudo ? 'Use this room code to join the Ludo match.' : 'Enter these details in Custom Room to join.', style: AppTextStyles.body2.copyWith(color: context.cTextDim)),
            const Divider(height: 30),
            _roomField(context, isLudo ? 'Room Code' : 'Room ID', roomId.isEmpty ? 'Not Available Yet' : roomId, isCopyable: roomId.isNotEmpty),
            if (!isLudo) ...[
              const SizedBox(height: 16),
              _roomField(context, 'Password', roomPass.isEmpty ? 'Not Available Yet' : roomPass, isCopyable: roomPass.isNotEmpty),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _roomField(BuildContext context, String label, String value, {bool isCopyable = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label.copyWith(color: context.cTextDim)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: context.cBgAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.cBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  value,
                  style: AppTextStyles.title.copyWith(
                    fontSize: 16,
                    color: isCopyable ? context.cText : context.cTextMuted,
                    letterSpacing: isCopyable ? 1.1 : 0.0,
                  ),
                ),
              ),
              if (isCopyable)
                IconButton(
                  icon: const Icon(Icons.copy, size: 20, color: AppColors.primary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: value));
                    AppToast.success('$label Copied!');
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLudo = match.modeLabel.toLowerCase().contains('ludo');
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(match.title,
                      style: AppTextStyles.title.copyWith(fontSize: 17))),
              StatusPill(
                  text: match.isJoined ? 'Joined' : 'Active',
                  color: AppColors.success),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _chip(context, Icons.emoji_events, AppColors.gold,
                  '${match.prize.toInt()} TK'),
              const SizedBox(width: 10),
              _chip(context, Icons.my_location, AppColors.killRed,
                  '${match.perKill.toInt()} TK'),
            ],
          ),
          const SizedBox(height: 14),
          MatchProgressBar(match: match),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _showPrizeDistribution(context),
                  icon: const Icon(Icons.emoji_events_outlined, size: 18),
                  label: const Text('Prize Pool'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.gold,
                    backgroundColor: AppColors.gold.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: match.isJoined
                    ? TextButton.icon(
                        onPressed: () => _showRoomDetails(context),
                        icon: Icon(Icons.vpn_key_outlined, size: 18, color: isLudo ? AppColors.matchesGreen : AppColors.winningTeal),
                        label: Text(isLudo ? 'Room Code' : 'Room Info'),
                        style: TextButton.styleFrom(
                          foregroundColor: isLudo ? AppColors.matchesGreen : AppColors.winningTeal,
                          backgroundColor: (isLudo ? AppColors.matchesGreen : AppColors.winningTeal).withValues(alpha: 0.1),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      )
                    : TextButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: const Text('Join Match'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, IconData icon, Color color, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: context.cBgAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.cBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(text, style: AppTextStyles.label.copyWith(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
