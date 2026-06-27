import 'package:flutter/material.dart';
import '../../app/widgets/premium_back_button.dart';
import '../../app/core/app_toast.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../app/core/app_constants.dart';
import '../../app/core/validators.dart';
import '../../app/data/mock/mock_data.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/widgets/common_widgets.dart';
import '../../app/widgets/payment_channel_field.dart';
import '../../app/widgets/primary_button.dart';
import '../../app/widgets/responsive.dart';

class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final amount = TextEditingController();
  int _channel = 0;

  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const PremiumBackButton(), title: const Text('Add Money')),
      body: ResponsiveCenter(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            AppCard(
              gradient: LinearGradient(
                colors: [
                  AppColors.success.withValues(alpha: 0.25),
                  context.cSurface
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.account_balance_wallet,
                        color: AppColors.winningTeal),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add Money',
                            style: AppTextStyles.title.copyWith(fontSize: 18)),
                        const SizedBox(height: 2),
                        const Text('Secure payment via gateway',
                            style: AppTextStyles.body2),
                      ],
                    ),
                  ),
                  const StatusPill(
                      text: 'Active',
                      color: AppColors.winningTeal,
                      showDot: false),
                ],
              ),
            ),
            const SizedBox(height: 15),
            const SectionHeader('PAYMENT METHOD'),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _channel,
              isExpanded: true,
              borderRadius: BorderRadius.circular(14),
              dropdownColor: context.cSurface,
              icon: Icon(Icons.keyboard_arrow_down_rounded,
                  color: context.cTextDim),
              decoration: const InputDecoration(
                  labelText: 'Select payment method'),
              selectedItemBuilder: (context) => [
                for (final ch in MockData.depositChannels)
                  PaymentChannelRow(channel: ch),
              ],
              items: [
                for (int i = 0; i < MockData.depositChannels.length; i++)
                  DropdownMenuItem<int>(
                    value: i,
                    child: PaymentChannelRow(
                        channel: MockData.depositChannels[i]),
                  ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _channel = v);
              },
            ),
            const SizedBox(height: 15),
            const SectionHeader('ENTER AMOUNT'),
            const SizedBox(height: 12),
            TextField(
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              style: AppTextStyles.body1,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(left: 16, right: 8),
                  child: Text(AppConstants.currency,
                      style: TextStyle(
                          fontSize: 20, color: AppColors.textSecondary)),
                ),
                prefixIconConstraints: BoxConstraints(minWidth: 0),
              ),
            ),
            const SizedBox(height: 15),
            Builder(builder: (context) {
              final ch = MockData.depositChannels[_channel];
              final isGateway = ch.key == 'gateway';
              return PrimaryButton(
                label: isGateway ? 'PROCEED TO PAYMENT' : 'CONTINUE',
                icon: isGateway
                    ? Icons.lock_outline
                    : Icons.arrow_forward_rounded,
                variant: ButtonVariant.green,
                onPressed: () {
                  final v = double.tryParse(amount.text.trim());
                  if (isGateway) {
                    final err = Validators.amount(amount.text);
                    if (err != null) {
                      AppToast.error(err);
                      return;
                    }
                    Get.toNamed(AppRoutes.depositWebview, arguments: v);
                  } else {
                    // Manual: amount is finalised with the TRX on the next
                    // screen — pass whatever's typed as a prefill.
                    Get.toNamed(AppRoutes.manualDeposit,
                        arguments: {'channel': ch, 'amount': v});
                  }
                },
              );
            }),
            const SizedBox(height: 15),
            AppCard(
              child: Column(
                children: [
                  _info(Icons.verified, AppColors.primary,
                      'Secure payment powered by our gateway'),
                  const SizedBox(height: 14),
                  _info(Icons.bolt, AppColors.gold,
                      'Balance is credited instantly after payment'),
                  const SizedBox(height: 14),
                  _info(Icons.headset_mic, AppColors.winningTeal,
                      'Contact support if payment is not reflected'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
            child: Text(text,
                style: AppTextStyles.body1.copyWith(color: context.cTextDim))),
      ],
    );
  }
}
