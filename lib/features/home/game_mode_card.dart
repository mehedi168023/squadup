import 'package:flutter/material.dart';
import '../../app/data/models/match_model.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/widgets/common_widgets.dart';

/// Image-dominant grid tile used for Free Fire modes and Ludo games:
/// cover image (or icon fallback) with a title + "N matches found" pill.
class GameModeCard extends StatelessWidget {
  final GameMode mode;
  final int matchesFound;
  final VoidCallback onTap;
  const GameModeCard({
    super.key,
    required this.mode,
    required this.matchesFound,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final has = matchesFound > 0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.cSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.cBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image-dominant top with a soft bottom fade into the strip.
            Expanded(
              flex: 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (mode.image.isNotEmpty)
                    Image.asset(mode.image,
                        fit: BoxFit.cover,
                        cacheWidth: 360,
                        filterQuality: FilterQuality.low)
                  else
                    Container(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      alignment: Alignment.center,
                      child:
                          Icon(mode.icon, size: 54, color: AppColors.primary),
                    ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.center,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          context.cSurface.withValues(alpha: 0.95),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Solid bottom strip: title + matches pill.
            Container(
              width: double.infinity,
              color: context.cSurface,
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
              child: Column(
                children: [
                  Text(mode.title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.title.copyWith(fontSize: 14)),
                  const SizedBox(height: 8),
                  StatusPill(
                    text: '$matchesFound matches found',
                    color: has ? AppColors.matchesGreen : AppColors.textMuted,
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
