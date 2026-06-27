import 'package:flutter/material.dart';
import '../../../app/data/models/match_model.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/widgets/common_widgets.dart';

/// Slots/registration progress bar with a "taken / total" label.
class MatchProgressBar extends StatelessWidget {
  final FfMatch match;
  final String label;
  const MatchProgressBar(
      {super.key, required this.match, this.label = 'Registration'});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.groups_outlined, size: 18, color: context.cTextDim),
            const SizedBox(width: 8),
            Text(label, style: AppTextStyles.title.copyWith(fontSize: 14)),
            const Spacer(),
            Text('${match.slotsTaken} / ${match.slotsTotal}',
                style: AppTextStyles.title
                    .copyWith(fontSize: 14, color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: match.slotProgress,
            minHeight: 8,
            backgroundColor: context.cBgAlt,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      ],
    );
  }
}

/// The match header card with a stat grid. [compact] shows 6 cells (Join
/// screen); otherwise the full 3×3 grid with VERSION/DEVICE/SLOTS (Match Info).
class MatchInfoCard extends StatelessWidget {
  final FfMatch match;
  final bool showSlots;
  final bool compact;
  const MatchInfoCard({
    super.key,
    required this.match,
    this.showSlots = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cells = <Widget>[
      StatCell(
          icon: Icons.map_outlined,
          iconColor: AppColors.primary,
          value: match.map,
          label: 'MAP'),
      StatCell(
          icon: Icons.sports_esports,
          iconColor: AppColors.primary,
          value: match.modeLabel,
          label: 'MODE'),
      StatCell(
          icon: Icons.person_outline,
          iconColor: AppColors.primary,
          value: match.type,
          label: 'TYPE'),
      StatCell(
          icon: Icons.emoji_events,
          iconColor: AppColors.gold,
          value: '${match.prize.toInt()} TK',
          label: 'PRIZE'),
      StatCell(
          icon: Icons.my_location,
          iconColor: AppColors.killRed,
          value: '${match.perKill.toInt()} TK',
          label: 'PER KILL'),
      StatCell(
          icon: Icons.payments_outlined,
          iconColor: AppColors.winningTeal,
          value: '${match.entryFee.toInt()} TK',
          label: 'ENTRY'),
      if (!compact) ...[
        StatCell(
            icon: Icons.layers_outlined,
            iconColor: AppColors.primary,
            value: match.version,
            label: 'VERSION'),
        StatCell(
            icon: Icons.smartphone,
            iconColor: AppColors.primary,
            value: match.device,
            label: 'DEVICE'),
        StatCell(
            icon: Icons.groups,
            iconColor: AppColors.gold,
            value: '${match.slotsTaken}/${match.slotsTotal}',
            label: 'SLOTS'),
      ],
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(match.title, style: AppTextStyles.h3)),
              const StatusPill(text: 'Active', color: AppColors.success),
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 14, color: AppColors.winningTeal),
                const SizedBox(width: 6),
                Text(_formatDate(match.startTime),
                    style: AppTextStyles.label
                        .copyWith(color: AppColors.winningTeal)),
              ],
            ),
          ] else
            Text('${match.version} · ${match.device}',
                style: AppTextStyles.body2),
          const SizedBox(height: 11),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.92,
            children: cells,
          ),
          if (showSlots) ...[
            const SizedBox(height: 14),
            if (compact) ...[
              Row(
                children: [
                  Icon(Icons.groups_outlined,
                      size: 17, color: context.cTextDim),
                  const SizedBox(width: 8),
                  Text('Slots',
                      style: AppTextStyles.title.copyWith(fontSize: 13)),
                  const Spacer(),
                  Text('${match.slotsTaken} / ${match.slotsTotal}',
                      style: AppTextStyles.title
                          .copyWith(fontSize: 13, color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 7),
            ],
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: match.slotProgress,
                minHeight: 8,
                backgroundColor: context.cBgAlt,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour < 12 ? 'AM' : 'PM';
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} ${d.year} · $h:$m $ampm';
  }
}
