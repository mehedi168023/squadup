import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/core/app_constants.dart';
import '../../app/data/mock/mock_data.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/widgets/brand_app_bar.dart';
import '../../app/widgets/common_widgets.dart';
import '../../app/widgets/promo_banner.dart';
import '../../app/widgets/responsive.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BrandAppBar(),
      body: ResponsiveCenter(
        child: ListView(
          // Clear the floating bottom nav bar (shell uses extendBody: true).
          padding: EdgeInsets.fromLTRB(
              12, 12, 12, MediaQuery.of(context).padding.bottom + 84),
          children: const [
            PromoBanner(banners: MockData.shopBanners),
            SizedBox(height: 14),
            // Free Fire Topup · Ludo Kingpass · Gaming Store as a 2-column grid.
            SectionHeader('STORE'),
            SizedBox(height: 14),
            _StoreGrid(),
          ],
        ),
      ),
    );
  }
}

/// The three store entry points laid out as image tiles in a 2-column grid
/// (two on the top row, the third on the bottom-left).
class _StoreGrid extends StatelessWidget {
  const _StoreGrid();

  @override
  Widget build(BuildContext context) {
    final ff = MockData.topupCategories[0];
    final kingpass = MockData.topupCategories[1];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.95,
      children: [
        _StoreTile(
          image: ff.image,
          title: 'Free Fire Topup',
          subtitle: 'Diamonds · Instant',
          colors: ff.colors,
          onTap: () => Get.toNamed(AppRoutes.topup, arguments: ff),
        ),
        _StoreTile(
          image: kingpass.image,
          title: 'Ludo Kingpass',
          subtitle: 'Coins · Discount',
          colors: kingpass.colors,
          onTap: () => Get.toNamed(AppRoutes.topup, arguments: kingpass),
        ),
        _StoreTile(
          image: AppConstants.shopGamingLogo,
          title: 'Gaming Store',
          subtitle: 'Gadgets & gear',
          colors: const [Color(0xFF2A0A40), Color(0xFF120A26)],
          onTap: () => Get.toNamed(AppRoutes.products),
        ),
      ],
    );
  }
}

/// A single store tile: full-bleed hero image with a readable title overlay.
class _StoreTile extends StatelessWidget {
  final String image;
  final String title;
  final String subtitle;
  final List<Color> colors;
  final VoidCallback onTap;
  const _StoreTile({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: colors.first.withValues(alpha: 0.5),
              blurRadius: 16,
              spreadRadius: -8,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Hero image covers the tile; the gradient shows through any
            // transparent areas and stands in if the asset fails to load.
            Image.asset(
              image,
              fit: BoxFit.cover,
              cacheWidth: 360,
              filterQuality: FilterQuality.low,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
            // Bottom scrim keeps the title legible over any image.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC000000)],
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.h3
                          .copyWith(color: Colors.white, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
