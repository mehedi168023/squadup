import 'package:flutter/material.dart';
import '../../app/widgets/premium_back_button.dart';
import 'package:get/get.dart';
import '../../app/data/mock/mock_data.dart';
import '../../app/data/models/match_model.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_shadows.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';

class MatchRulesController extends GetxController {
  final selected = 0.obs;
}

/// Per-mode visual identity (icon + accent + tagline) so each rules page has
/// its own premium colour story instead of one flat blue list.
class _ModeStyle {
  final IconData icon;
  final Color color;
  final String subtitle;
  const _ModeStyle(this.icon, this.color, this.subtitle);
}

_ModeStyle _styleFor(String key) {
  switch (key) {
    case 'br':
      return const _ModeStyle(
          Icons.public_rounded, AppColors.primary, 'Battle Royale · Solo & Squad');
    case 'cs':
      return const _ModeStyle(Icons.shield_moon_rounded, AppColors.winningTeal,
          'Clash Squad · 4 v 4');
    case 'lone_wolf':
      return const _ModeStyle(
          Icons.gps_fixed_rounded, AppColors.gold, 'Sniper Only · 1 v 1 / 2 v 2');
    case 'free':
      return const _ModeStyle(Icons.card_giftcard_rounded,
          AppColors.matchesGreen, 'Free Entry · Practice Match');
    default:
      return const _ModeStyle(
          Icons.sports_esports_rounded, AppColors.primary, 'Tournament Rules');
  }
}

/// The rules string is a single block: a heading line, numbered points (Bengali
/// or western digits) and one or more closing notes. We parse it into structured
/// parts so each point can render as its own premium card.
class _ParsedRules {
  final List<String> items;
  final List<String> notes;
  const _ParsedRules(this.items, this.notes);
}

_ParsedRules _parseRules(String raw) {
  final lines =
      raw.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
  final numbered = RegExp(r'^[০-৯0-9]+[.৷।)]\s*');
  final items = <String>[];
  final notes = <String>[];
  var headerSeen = false;
  for (final line in lines) {
    if (numbered.hasMatch(line)) {
      items.add(line.replaceFirst(numbered, '').trim());
    } else if (!headerSeen) {
      headerSeen = true; // first non-numbered line is the decorative heading
    } else {
      notes.add(line);
    }
  }
  return _ParsedRules(items, notes);
}

/// Standalone Match Rules viewer — premium redesign with per-mode accent hero,
/// animated mode chips and numbered rule cards.
class MatchRulesScreen extends StatelessWidget {
  const MatchRulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(MatchRulesController());
    const modes = MockData.gameModes;

    return Scaffold(
      appBar: AppBar(leading: const PremiumBackButton(), 
        title: const Text('Match Rules'),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
            child: Text('SELECT A MODE',
                style: AppTextStyles.caption.copyWith(
                    color: context.cTextMuted, fontWeight: FontWeight.w800)),
          ),
          SizedBox(
            height: 46,
            child: Obx(() {
              // Read the observable synchronously here so GetX registers the
              // dependency (itemBuilder runs lazily, outside the Obx scope).
              final selected = c.selected.value;
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: modes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) => _chip(
                    context, modes[i], selected == i, () => c.selected.value = i),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: Obx(() {
              final mode = modes[c.selected.value];
              return AnimatedSwitcher(
                duration: AppDurations.base,
                switchInCurve: AppCurves.standard,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween(
                            begin: const Offset(0, 0.03), end: Offset.zero)
                        .animate(anim),
                    child: child,
                  ),
                ),
                child: _content(context, mode),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _chip(
      BuildContext context, GameMode mode, bool active, VoidCallback onTap) {
    final st = _styleFor(mode.key);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppDurations.base,
        curve: AppCurves.standard,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(
          gradient: active
              ? LinearGradient(
                  colors: [st.color, st.color.withValues(alpha: 0.72)])
              : null,
          color: active ? null : context.cSurface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
              color: active ? Colors.transparent : context.cBorder),
          boxShadow: active ? AppShadows.glow(st.color, opacity: 0.35) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(st.icon, size: 16, color: active ? Colors.white : st.color),
            const SizedBox(width: 7),
            Text(mode.title,
                style: AppTextStyles.title.copyWith(
                    fontSize: 12.5,
                    color: active ? Colors.white : context.cTextDim)),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, GameMode mode) {
    final st = _styleFor(mode.key);
    final parsed = _parseRules(MockData.rulesForMode(mode.key));
    return SingleChildScrollView(
      key: ValueKey(mode.key),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _hero(context, mode, st),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Icon(Icons.verified_rounded, size: 16, color: st.color),
              const SizedBox(width: 8),
              Text('RULES & GUIDELINES',
                  style: AppTextStyles.caption.copyWith(
                      color: context.cTextDim, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text('${parsed.items.length} points',
                  style:
                      AppTextStyles.label.copyWith(color: context.cTextMuted)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...List.generate(
            parsed.items.length,
            (i) => _ruleItem(context, i + 1, parsed.items[i], st.color),
          ),
          for (final note in parsed.notes) ...[
            const SizedBox(height: AppSpacing.xs),
            _note(context, note, st.color),
          ],
        ],
      ),
    );
  }

  Widget _hero(BuildContext context, GameMode mode, _ModeStyle st) {
    final matches = mode.matchesFound;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            st.color.withValues(alpha: 0.92),
            st.color.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.glow(st.color, opacity: 0.32),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: Icon(st.icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mode.title,
                    style: AppTextStyles.h2.copyWith(color: Colors.white)),
                const SizedBox(height: 3),
                Text(st.subtitle,
                    style: AppTextStyles.body2.copyWith(
                        color: Colors.white.withValues(alpha: 0.9))),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt_rounded,
                          size: 13, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        matches == 1
                            ? '1 live match'
                            : '$matches live matches',
                        style: AppTextStyles.label.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ruleItem(
      BuildContext context, int index, String text, Color accent) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.cSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.cBorder),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [accent, accent.withValues(alpha: 0.62)]),
              borderRadius: BorderRadius.circular(9),
              boxShadow: AppShadows.glow(accent, opacity: 0.3),
            ),
            child: Text('$index',
                style: AppTextStyles.title
                    .copyWith(color: Colors.white, fontSize: 13)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(text,
                  style: AppTextStyles.body1
                      .copyWith(height: 1.6, color: context.cText)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _note(BuildContext context, String text, Color accent) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Text(text,
          textAlign: TextAlign.center,
          style:
              AppTextStyles.body1.copyWith(color: context.cText, height: 1.5)),
    );
  }
}
