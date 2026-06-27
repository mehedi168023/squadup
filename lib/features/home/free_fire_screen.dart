import 'package:flutter/material.dart';
import '../../app/widgets/premium_back_button.dart';
import 'package:get/get.dart';
import '../../app/data/mock/mock_data.dart';
import '../../app/data/services/session_service.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/widgets/common_widgets.dart';
import '../../app/widgets/responsive.dart';
import 'game_mode_card.dart';

/// Free Fire category — the BR / CS / Lone Wolf / Free game modes.
class FreeFireScreen extends StatelessWidget {
  const FreeFireScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionService.to;
    return Scaffold(
      appBar: AppBar(leading: const PremiumBackButton(), title: const Text('Free Fire')),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: session.refreshMatches,
        child: ResponsiveCenter(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
                12, 12, 12, MediaQuery.of(context).padding.bottom + 24),
            children: [
              const SectionHeader('ALL GAMES & MODES'),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: MockData.gameModes.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.82,
                ),
                itemBuilder: (_, i) {
                  final mode = MockData.gameModes[i];
                  return GameModeCard(
                    mode: mode,
                    matchesFound: mode.matchesFound,
                    onTap: () =>
                        Get.toNamed(AppRoutes.matchList, arguments: mode),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
