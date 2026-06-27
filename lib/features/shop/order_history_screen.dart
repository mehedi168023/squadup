import 'package:flutter/material.dart';
import '../../app/widgets/premium_back_button.dart';
import 'package:get/get.dart';
import '../../app/core/app_constants.dart';
import '../../app/core/app_sheets.dart';
import '../../app/data/models/order_model.dart';
import '../../app/data/services/session_service.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_shadows.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/widgets/common_widgets.dart';

/// Order History — a transparent, trustworthy record of every top-up and
/// product purchase. Premium summary header, kind filters, status-tagged cards
/// and a tappable receipt for each order.
class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  // null = All; otherwise filter by kind.
  OrderKind? _filter;

  @override
  Widget build(BuildContext context) {
    final session = SessionService.to;
    return Scaffold(
      appBar: AppBar(leading: const PremiumBackButton(), title: const Text('My Orders'), centerTitle: true),
      body: Obx(() {
        final all = session.orders;
        if (all.isEmpty) {
          return const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No orders yet',
            hint: 'Your top-ups & purchases will appear here',
          );
        }
        final list = _filter == null
            ? all.toList()
            : all.where((o) => o.kind == _filter).toList();
        return ListView(
          padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md,
              AppSpacing.md, MediaQuery.of(context).padding.bottom + 28),
          children: [
            _StatsHeader(orders: all),
            const SizedBox(height: AppSpacing.lg),
            _Filters(
              current: _filter,
              onChanged: (k) => setState(() => _filter = k),
            ),
            const SizedBox(height: AppSpacing.md),
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Text('No ${_filter == OrderKind.topup ? 'top-ups' : 'products'} yet',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body1
                        .copyWith(color: context.cTextDim)),
              )
            else
              ...list.map((o) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _OrderCard(
                        order: o, onTap: () => _showReceipt(context, o)),
                  )),
            const SizedBox(height: AppSpacing.sm),
            const _TrustFooter(),
          ],
        );
      }),
    );
  }

  void _showReceipt(BuildContext context, OrderModel o) {
    AppSheet.show(
      title: 'Order Receipt',
      subtitle: o.id,
      child: _Receipt(order: o),
    );
  }
}

/// Gradient summary: order count + total spent (social proof of activity).
class _StatsHeader extends StatelessWidget {
  final List<OrderModel> orders;
  const _StatsHeader({required this.orders});

  @override
  Widget build(BuildContext context) {
    final total = orders.fold<double>(0, (s, o) => s + o.amount);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.blueGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.glow(AppColors.primary, opacity: 0.3),
      ),
      child: Row(
        children: [
          _stat('${orders.length}', 'Total orders', Icons.receipt_long_rounded),
          Container(
              width: 1,
              height: 38,
              color: Colors.white.withValues(alpha: 0.25)),
          _stat(taka(total), 'Total spent', Icons.payments_rounded),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 20),
          const SizedBox(height: 6),
          Text(value,
              style: AppTextStyles.h2.copyWith(color: Colors.white, fontSize: 20)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.label
                  .copyWith(color: Colors.white.withValues(alpha: 0.85))),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  final OrderKind? current;
  final ValueChanged<OrderKind?> onChanged;
  const _Filters({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _chip(context, 'All', null),
        const SizedBox(width: 8),
        _chip(context, 'Top-ups', OrderKind.topup),
        const SizedBox(width: 8),
        _chip(context, 'Products', OrderKind.product),
      ],
    );
  }

  Widget _chip(BuildContext context, String label, OrderKind? kind) {
    final active = current == kind;
    return GestureDetector(
      onTap: () => onChanged(kind),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : context.cSurface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
              color: active ? AppColors.primary : context.cBorder),
        ),
        child: Text(label,
            style: AppTextStyles.label.copyWith(
                color: active ? Colors.white : context.cTextDim,
                fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;
  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = order.accent;
    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Icon(order.icon, color: accent, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.cText)),
                const SizedBox(height: 3),
                Text('${order.method} • ${shortDateTime(order.date)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body2.copyWith(color: context.cTextDim)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(taka(order.amount),
                  style: AppTextStyles.title
                      .copyWith(fontSize: 15, color: context.cText)),
              const SizedBox(height: 6),
              StatusPill(
                  text: order.statusLabel,
                  color: order.statusColor,
                  showDot: false),
            ],
          ),
        ],
      ),
    );
  }
}

class _Receipt extends StatelessWidget {
  final OrderModel order;
  const _Receipt({required this.order});

  @override
  Widget build(BuildContext context) {
    final accent = order.accent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Amount + status hero.
        Row(
          children: [
            Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accent.withValues(alpha: 0.35)),
              ),
              child: Icon(order.icon, color: accent, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.title,
                      style: AppTextStyles.title
                          .copyWith(fontSize: 16, color: context.cText)),
                  const SizedBox(height: 3),
                  Text('${order.kindLabel} • ${order.subtitle}',
                      style: AppTextStyles.body2
                          .copyWith(color: context.cTextDim)),
                ],
              ),
            ),
            StatusPill(text: order.statusLabel, color: order.statusColor),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: accent.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              Text('Amount', style: AppTextStyles.label.copyWith(color: context.cTextDim)),
              const SizedBox(height: 2),
              Text(taka(order.amount),
                  style: AppTextStyles.h1.copyWith(color: accent, fontSize: 26)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ...order.details.entries.map((e) => _row(context, e.key, e.value)),
        _row(context, 'Order ID', order.id),
        _row(context, 'Date', fullDateWeekday(order.date)),
        const SizedBox(height: AppSpacing.lg),
        // Trust line.
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_rounded,
                  color: AppColors.success, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Verified & recorded by SquadUp. Keep this receipt for your reference.',
                    style: AppTextStyles.body2.copyWith(color: context.cText)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: AppTextStyles.body2.copyWith(color: context.cTextDim)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.right,
                style: AppTextStyles.body1.copyWith(
                    color: context.cText, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

/// A reassurance strip at the bottom of the history — reinforces that purchases
/// are safe and traceable.
class _TrustFooter extends StatelessWidget {
  const _TrustFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.cSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.cBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.shield_rounded,
                color: AppColors.success, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Every order is safe & traceable',
                    style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.w700, color: context.cText)),
                const SizedBox(height: 2),
                Text('Secure payments • Instant top-ups • Real support',
                    style:
                        AppTextStyles.body2.copyWith(color: context.cTextDim)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
