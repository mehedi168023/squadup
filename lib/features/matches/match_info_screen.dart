import 'dart:async';
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

class MatchInfoController extends GetxController {
  final FfMatch match;
  MatchInfoController(this.match);

  final tab = 0.obs; // 0 = Rules, 1 = Participants
  final rulesExpanded = false.obs;
  final remaining = Duration.zero.obs;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final diff = match.startTime.difference(DateTime.now());
    remaining.value = diff.isNegative ? Duration.zero : diff;
  }

  String get countdownLabel {
    final d = remaining.value;
    if (d == Duration.zero) return 'Started';
    final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
    if (h > 0) return '${h}h ${m}m ${s}s';
    return '${m}m ${s}s';
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}

class MatchInfoScreen extends StatefulWidget {
  const MatchInfoScreen({super.key});

  @override
  State<MatchInfoScreen> createState() => _MatchInfoScreenState();
}

class _MatchInfoScreenState extends State<MatchInfoScreen> {
  // Capture the route argument once (see MatchListScreen for why re-reading
  // `Get.arguments` in build() is unsafe).
  late final FfMatch match = Get.arguments as FfMatch;
  late final MatchInfoController c = Get.put(MatchInfoController(match));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const PremiumBackButton(), 
        centerTitle: true,
        title: Text(match.title, overflow: TextOverflow.ellipsis),
      ),
      bottomNavigationBar: _BottomBar(controller: c),
      body: ResponsiveCenter(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            _HeaderCard(controller: c),
            const SizedBox(height: AppSpacing.lg),
            _SegmentedTabs(controller: c),
            const SizedBox(height: AppSpacing.lg),
            Obx(() => c.tab.value == 0
                ? _RulesContent(controller: c)
                : _ParticipantsContent(match: match)),
          ],
        ),
      ),
    );
  }
}

/// Compact iOS-style card: status + live countdown, three money stats, slots bar.
class _HeaderCard extends StatelessWidget {
  final MatchInfoController controller;
  const _HeaderCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final match = controller.match;
    return _IosCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Pill(text: match.modeLabel, color: AppColors.primary),
              const Spacer(),
              Obx(() => _Pill(
                    icon: Icons.schedule_rounded,
                    text: controller.countdownLabel,
                    color: AppColors.winningTeal,
                  )),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _money(context, Icons.emoji_events_rounded, AppColors.gold,
                  'PRIZE', match.prize),
              const SizedBox(width: AppSpacing.sm),
              _money(context, Icons.my_location_rounded, AppColors.killRed,
                  'PER KILL', match.perKill),
              const SizedBox(width: AppSpacing.sm),
              _money(context, Icons.confirmation_num_rounded,
                  AppColors.winningTeal, 'ENTRY', match.entryFee),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Text('Slots filled',
                  style: AppTextStyles.label.copyWith(color: context.cTextDim)),
              const Spacer(),
              Text('${match.slotsTaken}/${match.slotsTotal}',
                  style:
                      AppTextStyles.title.copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: match.slotProgress,
              minHeight: 7,
              backgroundColor: context.cBgAlt,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _money(BuildContext context, IconData icon, Color color, String label,
      double value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
        decoration: BoxDecoration(
          color: context.cSurfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(taka(value),
                  style: AppTextStyles.title.copyWith(fontSize: 14)),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: AppTextStyles.caption
                    .copyWith(color: context.cTextMuted, fontSize: 9)),
          ],
        ),
      ),
    );
  }
}

/// iOS-style sliding segmented control.
class _SegmentedTabs extends StatelessWidget {
  final MatchInfoController controller;
  const _SegmentedTabs({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.cBgAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Obx(() {
        final sel = controller.tab.value;
        return LayoutBuilder(builder: (context, constraints) {
          final segW = constraints.maxWidth / 2;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: AppDurations.base,
                curve: AppCurves.standard,
                left: sel * segW,
                top: 0,
                bottom: 0,
                width: segW,
                child: Container(
                  decoration: BoxDecoration(
                    color: context.cSurface,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  _seg(context, 'Rules', 0, sel == 0),
                  _seg(context, 'Participants', 1, sel == 1),
                ],
              ),
            ],
          );
        });
      }),
    );
  }

  Widget _seg(BuildContext context, String label, int index, bool active) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => controller.tab.value = index,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: AppDurations.fast,
            style: AppTextStyles.title.copyWith(
              fontSize: 13.5,
              color: active ? context.cText : context.cTextDim,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

class _RulesContent extends StatelessWidget {
  final MatchInfoController controller;
  const _RulesContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    final match = controller.match;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // iOS grouped detail list.
        _IosGroup(
          rows: [
            _DetailRow(label: 'Map', value: match.map),
            _DetailRow(label: 'Mode', value: match.modeLabel),
            _DetailRow(label: 'Type', value: match.type),
            _DetailRow(label: 'Version', value: match.version),
            _DetailRow(label: 'Device', value: match.device),
            _DetailRow(label: 'Starts', value: _formatDate(match.startTime)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const _SectionLabel('MATCH RULES'),
        const SizedBox(height: AppSpacing.sm),
        _IosCard(
          child: Obx(() {
            final expanded = controller.rulesExpanded.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.rules,
                  maxLines: expanded ? null : 6,
                  overflow:
                      expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  style: AppTextStyles.body1.copyWith(height: 1.7),
                ),
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: TextButton.icon(
                    onPressed: controller.rulesExpanded.toggle,
                    icon: Icon(
                        expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.primary),
                    label: Text(expanded ? 'Show Less' : 'Show Full Rules',
                        style: AppTextStyles.title.copyWith(
                            color: AppColors.primary, fontSize: 13.5)),
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  static String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour < 12 ? 'AM' : 'PM';
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]}, $h:$m $ampm';
  }
}

class _ParticipantsContent extends StatelessWidget {
  final FfMatch match;
  const _ParticipantsContent({required this.match});

  @override
  Widget build(BuildContext context) {
    if (match.participants.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: AppSpacing.xxxl),
        child: EmptyState(
          icon: Icons.groups_outlined,
          title: 'No participants yet',
          hint: 'Be the first to join',
        ),
      );
    }
    return _IosGroup(
      rows: [
        for (final p in match.participants)
          _DetailRow(
            leading: _SlotBadge(slot: p.slot),
            value: p.ign,
            valueIsTitle: true,
          ),
      ],
    );
  }
}

// ── Reusable iOS building blocks ──────────────────────────────────────────

/// A rounded "inset grouped" surface card.
class _IosCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _IosCard(
      {required this.child, this.padding = const EdgeInsets.all(14)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: context.cSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.cBorder),
      ),
      child: child,
    );
  }
}

/// An iOS grouped list: rows separated by inset hairline dividers.
class _IosGroup extends StatelessWidget {
  final List<_DetailRow> rows;
  const _IosGroup({required this.rows});

  @override
  Widget build(BuildContext context) {
    return _IosCard(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i != rows.length - 1)
              Divider(height: 1, thickness: 1, color: context.cBorder),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String? label;
  final String value;
  final Widget? leading;
  final bool valueIsTitle;
  const _DetailRow({
    this.label,
    required this.value,
    this.leading,
    this.valueIsTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          if (label != null)
            Text(label!,
                style: AppTextStyles.body1.copyWith(color: context.cTextDim)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: valueIsTitle
                  ? AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600)
                  : AppTextStyles.title
                      .copyWith(fontSize: 13.5, color: context.cText),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotBadge extends StatelessWidget {
  final int slot;
  const _SlotBadge({required this.slot});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: 0.15),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Text('$slot',
          style: AppTextStyles.title
              .copyWith(color: AppColors.primary, fontSize: 13)),
    );
  }
}

/// A compact accent pill with optional leading icon.
class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  const _Pill({required this.text, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
          ],
          Text(text,
              style: AppTextStyles.label
                  .copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// iOS-style uppercase grey section caption.
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(text,
          style: AppTextStyles.caption.copyWith(color: context.cTextMuted)),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final MatchInfoController controller;
  const _BottomBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final session = SessionService.to;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Obx(() {
          // Observe the live match from the session list so "Already Joined"
          // updates reactively after a successful join.
          final live = session.matches.firstWhere(
            (m) => m.id == controller.match.id,
            orElse: () => controller.match,
          );
          final joined = live.isJoined;
          return PrimaryButton(
            label: joined ? 'Already Joined' : 'Join Match',
            icon: joined ? Icons.check_circle : Icons.add_circle_outline,
            variant: ButtonVariant.green,
            onPressed: joined
                ? null
                : () => Get.toNamed(AppRoutes.joinMatch, arguments: live),
          );
        }),
      ),
    );
  }
}
