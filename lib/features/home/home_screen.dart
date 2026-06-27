import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/data/mock/mock_data.dart';
import '../../app/data/models/match_model.dart';
import '../../app/data/services/session_service.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/widgets/brand_app_bar.dart';
import '../../app/widgets/common_widgets.dart';
import '../../app/widgets/promo_banner.dart';
import '../../app/widgets/responsive.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionService.to;
    return Scaffold(
      appBar: const BrandAppBar(),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: session.refreshMatches,
        child: ResponsiveCenter(
          child: ListView(
            // Clear the floating bottom nav bar (shell uses extendBody: true).
            padding: EdgeInsets.fromLTRB(
                12, 12, 12, MediaQuery.of(context).padding.bottom + 84),
            children: [
              const PromoBanner(banners: MockData.homeBanners),
              const SizedBox(height: 16),
              const SectionHeader('CHOOSE YOUR GAME'),
              const SizedBox(height: 14),
              for (final cat in MockData.categories) ...[
                _CategoryCard(category: cat),
                const SizedBox(height: 14),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final GameCategory category;
  const _CategoryCard({required this.category});

  void _open() {
    Get.toNamed(category.key == 'ludo' ? AppRoutes.ludo : AppRoutes.freeFire);
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionService.to;
    return GestureDetector(
      onTap: _open,
      child: Container(
        height: 118,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: category.colors,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: category.colors.first.withValues(alpha: 0.5),
              blurRadius: 18,
              spreadRadius: -8,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Faded background watermark glyph.
            Positioned(
              right: -16,
              bottom: -22,
              child: Icon(category.icon,
                  size: 150, color: Colors.white.withValues(alpha: 0.07)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                children: [
                  _IconTile(category: category),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(category.title,
                            style: AppTextStyles.h1
                                .copyWith(color: Colors.white, fontSize: 23)),
                        const SizedBox(height: 5),
                        Text(category.subtitle,
                            style: AppTextStyles.caption.copyWith(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Live count badge (top-right).
            Positioned(
              top: 10,
              right: 12,
              child: Obx(() {
                final count = session.matches
                    .where((m) => category.modeKeys.contains(m.modeKey))
                    .length;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text('$count',
                      style: AppTextStyles.title.copyWith(
                          color: const Color(0xFF1A1500), fontSize: 13)),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  final GameCategory category;
  const _IconTile({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 66,
      height: 66,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: category.image != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Image.asset(category.image!,
                  fit: BoxFit.cover, cacheWidth: 180),
            )
          : Icon(category.icon, color: Colors.white, size: 32),
    );
  }
}
