import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// A bordered surface card used across the app.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double radius;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(13),
    this.color,
    this.radius = 14,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          padding: padding,
          decoration: BoxDecoration(
            color: gradient == null ? (color ?? theme.cardColor) : null,
            gradient: gradient,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: theme.dividerColor),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Uppercase section header with a blue accent bar ("ALL GAMES & MODES").
class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: AppTextStyles.caption.copyWith(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.w800,
            fontSize: 13.5,
          ),
        ),
      ],
    );
  }
}

/// A single stat cell. Default order (match cells): icon → label → value.
/// With [valueFirst] (profile stats): icon → value(big) → label.
class StatCell extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final bool valueFirst;

  const StatCell({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.valueFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;
    final valueText = Text(value,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.title
            .copyWith(fontSize: valueFirst ? 17 : 12.5, color: textColor));
    final labelText = Text(label,
        textAlign: TextAlign.center,
        style: AppTextStyles.caption
            .copyWith(color: context.cTextDim, fontSize: valueFirst ? 11 : 9));

    return Container(
      padding:
          EdgeInsets.symmetric(vertical: valueFirst ? 13 : 10, horizontal: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: valueFirst
            ? [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(height: 6),
                valueText,
                const SizedBox(height: 3),
                labelText,
              ]
            : [
                Icon(icon, color: iconColor, size: 18),
                const SizedBox(height: 5),
                labelText,
                const SizedBox(height: 3),
                valueText,
              ],
      ),
    );
  }
}

/// A tappable list row: icon tile + label + chevron (Profile menu, quick actions).
class ListNavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color iconColor;
  final VoidCallback? onTap;

  const ListNavTile({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    this.iconColor = AppColors.primary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(11),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyLarge?.color)),
                if (subtitle != null)
                  Text(subtitle!, style: AppTextStyles.body2),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: context.cTextDim),
        ],
      ),
    );
  }
}

/// Centered empty placeholder with optional pull-to-refresh hint.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? hint;
  const EmptyState(
      {super.key, required this.icon, required this.title, this.hint});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              size: 80, color: context.cTextMuted.withValues(alpha: 0.6)),
          const SizedBox(height: 18),
          Text(title,
              style: AppTextStyles.title.copyWith(color: context.cTextDim)),
          if (hint != null) ...[
            const SizedBox(height: 6),
            Text(hint!,
                style: AppTextStyles.body2.copyWith(color: context.cTextMuted)),
          ],
        ],
      ),
    );
  }
}

/// Small colored status pill ("Active", "N matches found").
class StatusPill extends StatelessWidget {
  final String text;
  final Color color;
  final bool showDot;
  const StatusPill(
      {super.key,
      required this.text,
      required this.color,
      this.showDot = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
                width: 7,
                height: 7,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
          ],
          Text(text,
              style: AppTextStyles.label
                  .copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
