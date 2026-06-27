import 'package:flutter/material.dart';
import '../../app/widgets/premium_back_button.dart';
import 'package:get/get.dart';
import '../../app/core/app_constants.dart';
import '../../app/data/models/wallet_model.dart';
import '../../app/data/services/session_service.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/widgets/common_widgets.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionService.to;
    return Scaffold(
      appBar: AppBar(leading: const PremiumBackButton(), title: const Text('All Transactions')),
      body: Obx(() {
        final txs = session.transactions;
        if (txs.isEmpty) {
          return const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No transactions yet',
            hint: 'Pull down to refresh',
          );
        }
        return ListView.separated(
          padding: EdgeInsets.fromLTRB(
              12, 12, 12, MediaQuery.of(context).padding.bottom + 24),
          itemCount: txs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => RepaintBoundary(child: _TxRow(tx: txs[i])),
        );
      }),
    );
  }
}

class _TxRow extends StatelessWidget {
  final TransactionModel tx;
  const _TxRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    final credit = tx.isCredit;
    final color = credit ? AppColors.winningTeal : AppColors.danger;
    return AppCard(
      padding: const EdgeInsets.all(11),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(credit ? Icons.south_west : Icons.north_east,
                color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.description.isEmpty ? tx.type.name : tx.description,
                    style: AppTextStyles.body1
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('${tx.method} • ${shortDateTime(tx.date)}',
                    style: AppTextStyles.body2),
              ],
            ),
          ),
          Text('${credit ? '+' : '-'}${taka(tx.amount)}',
              style: AppTextStyles.title.copyWith(color: color, fontSize: 15)),
        ],
      ),
    );
  }
}
