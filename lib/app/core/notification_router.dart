import 'package:get/get.dart';
import '../../features/shell/shell_screen.dart';
import '../data/models/match_model.dart';
import '../data/services/session_service.dart';
import '../routes/app_routes.dart';

/// Maps a backend `action_target_screen` key to an in-app navigation. This is
/// the single deep-link table used by both notification taps and action
/// buttons, so the backend never needs to know route paths — just stable keys.
class NotificationRouter {
  NotificationRouter._();

  /// Open the screen for [target]. [args] carries optional ids (e.g. matchId).
  static void open(String? target, [Map<String, dynamic> args = const {}]) {
    if (target == null || target.isEmpty) return;
    switch (target) {
      case 'wallet':
        Get.toNamed(AppRoutes.wallet);
      case 'transactions':
        Get.toNamed(AppRoutes.transactions);
      case 'deposit':
      case 'add_money':
        Get.toNamed(AppRoutes.deposit);
      case 'withdraw':
        Get.toNamed(AppRoutes.withdraw);
      case 'my_matches':
      case 'match_room':
      case 'room':
        Get.toNamed(AppRoutes.myMatches);
      case 'results':
      case 'winners':
      case 'top_players':
      case 'leaderboard':
        Get.toNamed(AppRoutes.topPlayers);
      case 'free_fire':
        Get.toNamed(AppRoutes.freeFire);
      case 'ludo':
        Get.toNamed(AppRoutes.ludo);
      case 'products':
      case 'store':
        Get.toNamed(AppRoutes.products);
      case 'match':
      case 'tournament':
      case 'tournament_details':
        _openMatch(args);
      case 'topup':
      case 'shop':
        _tab(0);
      case 'home':
        _tab(1);
      case 'profile':
        _tab(2);
      default:
        break;
    }
  }

  /// Open a specific match's info screen when `matchId` is known, otherwise fall
  /// back to the joined-matches list.
  static void _openMatch(Map<String, dynamic> args) {
    final raw = args['matchId'] ?? args['match_id'];
    final id = raw is int ? raw : int.tryParse('${raw ?? ''}');
    FfMatch? match;
    if (id != null) {
      for (final m in SessionService.to.matches) {
        if (m.id == id) {
          match = m;
          break;
        }
      }
    }
    if (match != null) {
      Get.toNamed(AppRoutes.matchInfo, arguments: match);
    } else {
      Get.toNamed(AppRoutes.myMatches);
    }
  }

  /// Switch the shell bottom-nav tab (0 Shop · 1 Home · 2 Profile), popping any
  /// stacked screens first so the tab is actually visible.
  static void _tab(int index) {
    if (Get.isRegistered<ShellController>()) {
      Get.until((route) => route.isFirst);
      ShellController.to.go(index);
    } else {
      Get.offAllNamed(AppRoutes.shell);
    }
  }
}
