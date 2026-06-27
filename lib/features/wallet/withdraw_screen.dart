import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../app/core/app_constants.dart';
import '../../app/core/app_toast.dart';
import '../../app/core/validators.dart';
import '../../app/widgets/premium_back_button.dart';
import '../../app/data/mock/mock_data.dart';
import '../../app/data/models/heads_up_notification.dart';
import '../../app/data/services/notification_service.dart';
import '../../app/data/services/session_service.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/widgets/common_widgets.dart';
import '../../app/widgets/payment_channel_field.dart';
import '../../app/widgets/primary_button.dart';
import '../../app/widgets/responsive.dart';

class WithdrawController extends GetxController {
  final channel = 0.obs;
  final number = TextEditingController();
  final amount = TextEditingController();
  final loading = false.obs;

  @override
  void onClose() {
    number.dispose();
    amount.dispose();
    super.onClose();
  }

  Future<void> submit() async {
    final pErr = Validators.phone(number.text);
    if (pErr != null) {
      AppToast.error(pErr);
      return;
    }
    final aErr = Validators.amount(amount.text,
        min: MockData.minWithdraw, max: MockData.maxWithdraw);
    if (aErr != null) {
      AppToast.error(aErr);
      return;
    }
    final amt = double.parse(amount.text.trim());
    loading.value = true;
    final ch = MockData.withdrawChannels[channel.value];
    final ok =
        await SessionService.to.withdraw(amt, ch.key, number.text.trim());
    loading.value = false;
    if (!ok) return; // SessionService already surfaced the server message
    Get.back();
    NotificationService.to.showHeadsUp(
      HeadsUpNotification(
        id: 'wd_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Withdraw Requested',
        message: '${taka(amt)} withdrawal to ${ch.label} is being processed.',
        kind: NotifKind.push,
        icon: 'wallet',
      ),
      osNotify: true,
    );
  }
}

class WithdrawScreen extends StatelessWidget {
  const WithdrawScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(WithdrawController());
    const channels = MockData.withdrawChannels;

    return Scaffold(
      appBar: AppBar(leading: const PremiumBackButton(), title: const Text('Withdraw')),
      body: ResponsiveCenter(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Text('PAYMENT CHANNEL',
                style: AppTextStyles.caption.copyWith(color: context.cTextDim)),
            const SizedBox(height: 9),
            Obx(() => DropdownButtonFormField<int>(
                  initialValue: c.channel.value,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(14),
                  dropdownColor: context.cSurface,
                  icon: Icon(Icons.keyboard_arrow_down_rounded,
                      color: context.cTextDim),
                  decoration: const InputDecoration(
                    labelText: 'Select withdraw method',
                  ),
                  selectedItemBuilder: (context) => List.generate(
                    channels.length,
                    (i) => PaymentChannelRow(channel: channels[i]),
                  ),
                  items: List.generate(
                    channels.length,
                    (i) => DropdownMenuItem<int>(
                      value: i,
                      child: PaymentChannelRow(channel: channels[i]),
                    ),
                  ),
                  onChanged: (v) {
                    if (v != null) c.channel.value = v;
                  },
                )),
            const SizedBox(height: 13),
            TextField(
              controller: c.number,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              style: AppTextStyles.body1,
              decoration: const InputDecoration(
                  labelText: 'Wallet Number',
                  hintText: '01XXXXXXXXX'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: c.amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              onSubmitted: (_) => c.submit(),
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
            const SizedBox(height: 8),
            Text(
                'Min: ${taka(MockData.minWithdraw)}  ·  Max: ${taka(MockData.maxWithdraw)}',
                style: AppTextStyles.body2),
            const SizedBox(height: 13),
            Obx(() => PrimaryButton(
                  label: 'WITHDRAW',
                  variant: ButtonVariant.red,
                  loading: c.loading.value,
                  onPressed: c.submit,
                )),
            const SizedBox(height: 12),
            AppCard(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.trending_up,
                        color: AppColors.winningTeal),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                      child: Text('Your Withdrawal Balance is:',
                          style: AppTextStyles.body1)),
                  Obx(() => Text(
                      taka(SessionService.to.wallet.value.withdrawableBalance),
                      style: AppTextStyles.h3
                          .copyWith(color: AppColors.winningTeal))),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Text(MockData.withdrawNotice,
                  style: AppTextStyles.body1.copyWith(height: 1.6)),
            ),
          ],
        ),
      ),
    );
  }
}
