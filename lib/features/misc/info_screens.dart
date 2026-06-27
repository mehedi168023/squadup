import 'package:flutter/material.dart';
import '../../app/widgets/premium_back_button.dart';
import '../../app/core/app_constants.dart';
import '../../app/core/app_links.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/widgets/common_widgets.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const _terms =
      '''By using ${AppConstants.appName}, you agree to the following terms:

1. You must be 18 years or older to participate in paid tournaments.
2. Entry fees are non-refundable once a match has started.
3. Any form of hacking, cheating, or use of unauthorized panels results in a permanent ban.
4. Winnings are credited to your wallet and can be withdrawn via the supported channels (bKash / Nagad).
5. The minimum withdrawal amount is ৳105 and the maximum is ৳10000.
6. Room IDs and passwords are shared only with registered participants.
7. The decision of match admins is final in all disputes.

For full details visit squadup.gg/privacy''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const PremiumBackButton(), title: const Text('Terms & Conditions')),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            12, 12, 12, MediaQuery.of(context).padding.bottom + 24),
        child: AppCard(
          child: Text(_terms, style: AppTextStyles.body1.copyWith(height: 1.7)),
        ),
      ),
    );
  }
}

class DeveloperScreen extends StatelessWidget {
  const DeveloperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const PremiumBackButton(), title: const Text('Developer Profile')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.code, size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: 13),
            const Text('Mehedi', style: AppTextStyles.h2),
            const SizedBox(height: 6),
            const Text('App Developer & Esports Platform',
                style: AppTextStyles.body2),
            const SizedBox(height: 18),
            // Tappable contact links — replace the URLs with the real handles.
            const _ContactTile(
              icon: Icons.telegram,
              label: 'Telegram',
              value: '@mehedi',
              url: 'https://t.me/mehedi',
            ),
            const SizedBox(height: 12),
            const _ContactTile(
              icon: Icons.mail_outline_rounded,
              label: 'Email',
              value: 'mehedi@squadup.gg',
              url: 'mailto:mehedi@squadup.gg',
            ),
            const SizedBox(height: 12),
            const _ContactTile(
              icon: Icons.public,
              label: 'Website',
              value: 'squadup.gg',
              url: 'https://squadup.gg',
            ),
            const SizedBox(height: 18),
            Text('${AppConstants.appName} v${AppConstants.appVersion}',
                style: AppTextStyles.body2.copyWith(color: context.cTextMuted)),
          ],
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String url;
  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ListNavTile(
          icon: icon,
          label: label,
          subtitle: value,
          onTap: () => AppLinks.open(url),
        ),
      ),
    );
  }
}
