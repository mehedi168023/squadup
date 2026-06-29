import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/core/app_toast.dart';
import '../../app/widgets/premium_back_button.dart';
import 'package:get/get.dart';
import '../../app/data/services/session_service.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/widgets/common_widgets.dart';
import '../matches/match_list_screen.dart';

/// Shows matches the user has joined.
class MyMatchesScreen extends StatefulWidget {
  const MyMatchesScreen({super.key});

  @override
  State<MyMatchesScreen> createState() => _MyMatchesScreenState();
}

class _MyMatchesScreenState extends State<MyMatchesScreen> {
  final session = SessionService.to;

  @override
  void initState() {
    super.initState();
    // Pull the latest joined matches (carries room id/password + results).
    session.fetchMyMatches();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const PremiumBackButton(), title: const Text('My Matches')),
      body: Obx(() {
        final joined = session.joinedMatches;
        if (joined.isEmpty) {
          return const EmptyState(
            icon: Icons.sports_esports_outlined,
            title: 'Join a match to see it here',
            hint: 'Your joined matches will appear here',
          );
        }
        return ListView.separated(
          padding: EdgeInsets.fromLTRB(
              12, 12, 12, MediaQuery.of(context).padding.bottom + 24),
          itemCount: joined.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (_, i) {
            final m = joined[i];
            final isLudo = m.modeLabel.toLowerCase().contains('ludo');
            final hasRoom = m.roomId != null && m.roomId!.isNotEmpty;
            return Column(
              children: [
                MatchListCard(
                  match: m,
                  onTap: () => Get.toNamed(AppRoutes.matchInfo, arguments: m),
                ),
                if (hasRoom)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Icon(
                            isLudo ? Icons.vpn_key_outlined : Icons.meeting_room_outlined,
                            color: isLudo ? AppColors.matchesGreen : AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isLudo
                                  ? 'Room Code: ${m.roomId}'
                                  : 'Room ID: ${m.roomId}  •  Pass: ${m.roomPassword}',
                              style: AppTextStyles.label.copyWith(
                                color: isLudo ? AppColors.matchesGreen : context.cText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.copy,
                              size: 18,
                              color: isLudo ? AppColors.matchesGreen : AppColors.primary,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              if (isLudo) {
                                Clipboard.setData(ClipboardData(text: m.roomId ?? ''));
                                AppToast.success('Room Code Copied!');
                              } else {
                                final text = 'Room ID: ${m.roomId}\nPassword: ${m.roomPassword}';
                                Clipboard.setData(ClipboardData(text: text));
                                AppToast.success('Room Details Copied!');
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      }),
    );
  }
}
