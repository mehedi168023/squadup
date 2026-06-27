import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../app/core/app_constants.dart';
import '../../app/core/app_toast.dart';
import '../../app/core/validators.dart';
import '../../app/data/models/misc_models.dart';
import '../../app/data/services/session_service.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/widgets/common_widgets.dart';
import '../../app/widgets/payment_channel_field.dart';
import '../../app/widgets/premium_back_button.dart';
import '../../app/widgets/primary_button.dart';
import '../../app/widgets/responsive.dart';

/// Manual deposit flow for bKash / Nagad / Rocket: the user sends money to the
/// listed personal/agent number, then submits the Transaction ID + amount (and
/// optionally their own number) to request the top-up.
class ManualDepositScreen extends StatefulWidget {
  const ManualDepositScreen({super.key});

  @override
  State<ManualDepositScreen> createState() => _ManualDepositScreenState();
}

class _ManualDepositScreenState extends State<ManualDepositScreen> {
  late final PaymentChannel channel;
  final amount = TextEditingController();
  final trxId = TextEditingController();
  final senderNumber = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final args = (Get.arguments as Map?) ?? const {};
    channel = (args['channel'] as PaymentChannel?) ??
        const PaymentChannel(
            key: 'bkash',
            label: 'bKash',
            color: Color(0xFFE2136E),
            number: '01710000001',
            accountType: 'Personal');
    final prefill = args['amount'] as double?;
    if (prefill != null && prefill > 0) {
      amount.text = prefill.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    amount.dispose();
    trxId.dispose();
    senderNumber.dispose();
    super.dispose();
  }

  void _copyNumber() {
    Clipboard.setData(ClipboardData(text: channel.number ?? ''));
    AppToast.success('${channel.label} number copied');
  }

  Future<void> _submit() async {
    final aErr = Validators.amount(amount.text, min: 1);
    if (aErr != null) {
      AppToast.error(aErr);
      return;
    }
    final tErr = Validators.trxId(trxId.text);
    if (tErr != null) {
      AppToast.error(tErr);
      return;
    }
    final sn = senderNumber.text.trim();
    if (sn.isNotEmpty) {
      final snErr = Validators.phone(sn);
      if (snErr != null) {
        AppToast.error(snErr);
        return;
      }
    }
    final amt = double.parse(amount.text.trim());
    setState(() => _submitting = true);
    final ok = await SessionService.to.submitManualDeposit(
      channelKey: channel.key,
      amount: amt,
      trxId: trxId.text.trim(),
      senderNumber: senderNumber.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!ok) return;
    Get.back();
    AppToast.success(
        'Deposit request sent! We\'ll verify your TRX and credit ${taka(amt)} shortly.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          leading: const PremiumBackButton(),
          title: Text('${channel.label} Deposit')),
      body: ResponsiveCenter(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _NumberCard(channel: channel, onCopy: _copyNumber),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader('HOW TO DEPOSIT'),
            const SizedBox(height: AppSpacing.md),
            _steps(context),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader('SUBMIT YOUR PAYMENT'),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              style: AppTextStyles.body1,
              decoration: const InputDecoration(
                labelText: 'Amount Sent',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(left: 16, right: 8),
                  child: Text(AppConstants.currency,
                      style: TextStyle(
                          fontSize: 20, color: AppColors.textSecondary)),
                ),
                prefixIconConstraints: BoxConstraints(minWidth: 0),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: trxId,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                LengthLimitingTextInputFormatter(24),
              ],
              style: AppTextStyles.body1,
              decoration: const InputDecoration(
                labelText: 'Transaction ID (TRX)',
                hintText: 'e.g. 9HG7K2LM4P',
                prefixIcon: Icon(Icons.tag_rounded),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: senderNumber,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              onSubmitted: (_) => _submit(),
              style: AppTextStyles.body1,
              decoration: InputDecoration(
                labelText: 'Your ${channel.label} Number (optional)',
                hintText: 'The number you sent money from',
                prefixIcon: const Icon(Icons.phone_rounded),
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'SUBMIT REQUEST',
              icon: Icons.send_rounded,
              variant: ButtonVariant.green,
              loading: _submitting,
              onPressed: _submit,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.gold, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                        'Send money first, then submit. Your balance is added after we verify the Transaction ID.',
                        style: AppTextStyles.body2
                            .copyWith(color: context.cText, height: 1.4)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _steps(BuildContext context) {
    final steps = [
      'Open your ${channel.label} app and choose “Send Money”.',
      'Send the amount to the ${channel.accountType ?? 'Personal'} number above.',
      'Copy the Transaction ID (TRX) from the confirmation message.',
      'Enter the amount & TRX below and submit your request.',
    ];
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: channel.color.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: channel.color.withValues(alpha: 0.4)),
                  ),
                  child: Text('${i + 1}',
                      style: AppTextStyles.title
                          .copyWith(color: channel.color, fontSize: 12)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(steps[i],
                      style: AppTextStyles.body1.copyWith(height: 1.4)),
                ),
              ],
            ),
            if (i != steps.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

/// The prominent "send money to this number" card with a copy action.
class _NumberCard extends StatelessWidget {
  final PaymentChannel channel;
  final VoidCallback onCopy;
  const _NumberCard({required this.channel, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            channel.color.withValues(alpha: 0.9),
            channel.color.withValues(alpha: 0.55),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PaymentChannelRow(channel: channel),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text('${channel.accountType ?? 'Personal'} • Send Money',
                    style: AppTextStyles.label.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Send money to this number',
              style: AppTextStyles.body2
                  .copyWith(color: Colors.white.withValues(alpha: 0.85))),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(channel.number ?? '',
                    style: AppTextStyles.h1.copyWith(
                        color: Colors.white,
                        fontSize: 26,
                        letterSpacing: 1)),
              ),
              GestureDetector(
                onTap: onCopy,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.copy_rounded,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text('Copy',
                          style: AppTextStyles.button.copyWith(
                              color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
