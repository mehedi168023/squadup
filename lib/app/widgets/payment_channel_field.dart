import 'package:flutter/material.dart';
import '../data/models/misc_models.dart';
import '../theme/app_text_styles.dart';

/// A single payment-channel row — a brand-coloured badge with the right glyph
/// plus the channel name. Used as both the dropdown item and the selected value
/// on the Withdraw and Deposit screens.
class PaymentChannelRow extends StatelessWidget {
  final PaymentChannel channel;
  const PaymentChannelRow({super.key, required this.channel});

  IconData get _icon => channel.key == 'gateway'
      ? Icons.credit_card_rounded
      : Icons.account_balance_wallet_rounded;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: channel.color,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(_icon, color: Colors.white, size: 17),
        ),
        const SizedBox(width: 12),
        Text(channel.label, style: AppTextStyles.title.copyWith(fontSize: 15)),
      ],
    );
  }
}
