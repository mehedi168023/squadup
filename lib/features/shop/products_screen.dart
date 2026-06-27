import 'package:flutter/material.dart';
import '../../app/widgets/premium_back_button.dart';
import 'package:get/get.dart';
import '../../app/core/app_constants.dart';
import '../../app/data/mock/mock_data.dart';
import '../../app/data/models/misc_models.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/widgets/responsive.dart';

/// Gaming-store (e-commerce) product grid.
class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const PremiumBackButton(), title: const Text('Gaming Products')),
      body: ResponsiveCenter(
        child: GridView.builder(
          padding: EdgeInsets.fromLTRB(
              12, 12, 12, MediaQuery.of(context).padding.bottom + 24),
          itemCount: MockData.products.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.78,
          ),
          itemBuilder: (_, i) => RepaintBoundary(
              child: _ProductCard(product: MockData.products[i])),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  void _openBuy() => Get.toNamed(AppRoutes.productBuy, arguments: product);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openBuy,
      child: Container(
        decoration: BoxDecoration(
          color: context.cSurface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: context.cBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product image (falls back to an icon when no image is set).
            Expanded(
              child: Container(
                color: AppColors.primary.withValues(alpha: 0.08),
                alignment: Alignment.center,
                child: product.image != null
                    ? Image.asset(
                        product.image!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        cacheWidth: 360,
                        errorBuilder: (_, __, ___) => Icon(product.icon,
                            size: 56, color: AppColors.primary),
                      )
                    : Icon(product.icon, size: 56, color: AppColors.primary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.title.copyWith(fontSize: 13.5)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(taka(product.price),
                          style: AppTextStyles.title.copyWith(
                              fontSize: 15, color: AppColors.matchesGreen)),
                      const SizedBox(width: 6),
                      if (product.oldPrice != null)
                        Text(taka(product.oldPrice!),
                            style: AppTextStyles.body2.copyWith(
                              color: context.cTextMuted,
                              decoration: TextDecoration.lineThrough,
                            )),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _BuyButton(product: product),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuyButton extends StatelessWidget {
  final Product product;
  const _BuyButton({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.productBuy, arguments: product),
      child: Container(
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_bag_rounded,
                size: 15, color: AppColors.primary),
            const SizedBox(width: 6),
            Text('Buy Now',
                style: AppTextStyles.label.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
