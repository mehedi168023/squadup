import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/app_constants.dart';
import '../core/notice_popup.dart';
import '../data/services/session_service.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Top app bar for the main tabs: brand logo (left) + tappable wallet pill (right).
class BrandAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BrandAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.cBorder)),
        ),
        child: Row(
          children: [
            Image.asset(AppConstants.logo,
                width: 36, height: 36, cacheWidth: 110),
            const SizedBox(width: 8),
            Text(AppConstants.brandName,
                style: AppTextStyles.title.copyWith(
                    color: AppColors.primary,
                    fontSize: 14,
                    letterSpacing: 0.5)),
            const Spacer(),
            const _NotificationBell(),
            const SizedBox(width: 10),
            const _WalletPill(),
          ],
        ),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: NoticePopup.show,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: context.cSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.cBorder),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.notifications_none_rounded,
                size: 22, color: context.cTextDim),
            Positioned(
              top: 9,
              right: 11,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: AppColors.danger, shape: BoxShape.circle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletPill extends StatelessWidget {
  const _WalletPill();

  @override
  Widget build(BuildContext context) {
    final session = SessionService.to;
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.wallet),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: context.cSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_balance_wallet_outlined,
                size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Obx(() => Text(
                  taka(session.wallet.value.availableBalance),
                  style: AppTextStyles.title.copyWith(fontSize: 15),
                )),
          ],
        ),
      ),
    );
  }
}
