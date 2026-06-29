import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/data/services/session_service.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/widgets/brand_app_bar.dart';
import '../../app/widgets/common_widgets.dart';
import '../../app/widgets/promo_banner.dart';
import '../../app/widgets/responsive.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionService.to;
    return Scaffold(
      appBar: const BrandAppBar(),
      body: ResponsiveCenter(
        child: ListView(
          // Clear the floating bottom nav bar (shell uses extendBody: true).
          padding: EdgeInsets.fromLTRB(
              12, 12, 12, MediaQuery.of(context).padding.bottom + 84),
          children: [
            Obx(() => PromoBanner(banners: session.shopBanners.toList())),
            const SizedBox(height: 14),
            const SectionHeader('STORE'),
            const SizedBox(height: 14),
            const _StoreGrid(),
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
    final session = SessionService.to;
    return Obx(() {
      final list = session.storeCategories;
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
        children: [
          for (final cat in list)
            _StoreTile(
              image: cat.image,
              title: cat.title,
              subtitle: cat.subtitle,
              colors: cat.colors,
              onTap: () {
                if (cat.key == 'gaming_store') {
                  Get.toNamed(AppRoutes.products);
                } else {
                  Get.toNamed(AppRoutes.topup, arguments: cat);
                }
              },
            ),
        ],
      );
    });
  }
}

/// A single store tile: circular card layout with centered typography overlay.
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
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: colors.first.withValues(alpha: 0.3),
              blurRadius: 12,
              spreadRadius: -4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Hero image covers the tile; the gradient shows through any
            // transparent areas and stands in if the asset fails to load.
            image.startsWith('http')
                ? Image.network(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  )
                : Image.asset(
                    image,
                    fit: BoxFit.cover,
                    cacheWidth: 360,
                    filterQuality: FilterQuality.low,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
            // Overall darker overlay for readability inside a circle
            const DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black38,
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.h3
                            .copyWith(color: Colors.white, fontSize: 13)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 9)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
