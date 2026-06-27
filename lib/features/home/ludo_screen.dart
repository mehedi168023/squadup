import 'package:flutter/material.dart';
import '../../app/widgets/premium_back_button.dart';
import 'package:get/get.dart';
import '../../app/data/mock/mock_data.dart';
import '../../app/data/services/session_service.dart';
import '../../app/routes/app_routes.dart';
import '../../app/widgets/common_widgets.dart';
import '../../app/widgets/responsive.dart';
import 'game_mode_card.dart';

/// Ludo category — the Ludo King / Auto Ludo games, shown as Free-Fire-style
/// image grid tiles.
class LudoScreen extends StatelessWidget {
  const LudoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionService.to;
    return Scaffold(
      appBar: AppBar(leading: const PremiumBackButton(), title: const Text('Ludo Game')),
      body: ResponsiveCenter(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
              12, 12, 12, MediaQuery.of(context).padding.bottom + 24),
          children: [
            const SectionHeader('ALL GAMES & MODES'),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: MockData.ludoGames.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.82,
              ),
              itemBuilder: (_, i) {
                final game = MockData.ludoGames[i];
                return Obx(() => GameModeCard(
                      mode: game,
                      matchesFound: session.matchesForMode(game.key).length,
                      onTap: () =>
                          Get.toNamed(AppRoutes.ludoMatchList, arguments: game),
                    ));
              },
            ),
          ],
        ),
      ),
    );
  }
}
