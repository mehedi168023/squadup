import 'package:get/get.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/edit_profile/edit_profile_screen.dart';
import '../../features/home/free_fire_screen.dart';
import '../../features/home/ludo_join_screen.dart';
import '../../features/home/ludo_match_list_screen.dart';
import '../../features/home/ludo_screen.dart';
import '../../features/home/upload_evidence_screen.dart';
import '../../features/shop/order_history_screen.dart';
import '../../features/shop/product_buy_screen.dart';
import '../../features/shop/products_screen.dart';
import '../../features/shop/topup_screen.dart';
import '../../features/matches/join_match_screen.dart';
import '../../features/matches/match_info_screen.dart';
import '../../features/matches/match_list_screen.dart';
import '../../features/matches/match_rules_screen.dart';
import '../../features/misc/info_screens.dart';
import '../../features/my_matches/my_matches_screen.dart';
import '../../features/shell/shell_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/top_players/top_players_screen.dart';
import '../../features/wallet/deposit_screen.dart';
import '../../features/wallet/deposit_webview_screen.dart';
import '../../features/wallet/manual_deposit_screen.dart';
import '../../features/wallet/transactions_screen.dart';
import '../../features/wallet/wallet_screen.dart';
import '../../features/wallet/withdraw_screen.dart';
import 'app_routes.dart';
import 'app_transitions.dart';

/// All GetX named routes.
///
/// The app-wide DEFAULT navigation motion is a premium [AppTransitions.zoom]
/// (Material shared-axis Z — scale + fade). A few clearly-distinct route
/// categories override it with a transition that better communicates the kind
/// of navigation happening:
///
///   • Auth + Settings/Info/Result  → Fade Through   (unrelated content swap)
///   • Checkout / wallet money flow  → Shared Axis X  (forward steps)
///   • Login → Home                  → Shared Axis X  (forward into the app)
///   • Payment gateway surface       → Shared Axis Y  (modal rises up)
///
/// Ordinary game screens, match list/detail, lobby/join and normal drill-downs
/// use the default Zoom. Only PAGE transitions are affected here — buttons,
/// cards, dialogs, sheets and list-item animations are untouched. The
/// Splash→Login Hero and Login→Home Shared Axis flow is preserved.
class AppPages {
  AppPages._();

  /// Routes that override the default zoom transition. Anything not listed
  /// uses [AppTransitions.zoom].
  static final Map<String, CustomTransition> _special = {
    // Auth — unrelated context.
    AppRoutes.login: AppTransitions.fadeThrough,
    AppRoutes.register: AppTransitions.fadeThrough,
    // Settings / info / result — static content swap.
    AppRoutes.editProfile: AppTransitions.fadeThrough,
    AppRoutes.matchRules: AppTransitions.fadeThrough,
    AppRoutes.topPlayers: AppTransitions.fadeThrough,
    AppRoutes.terms: AppTransitions.fadeThrough,
    AppRoutes.developer: AppTransitions.fadeThrough,
    AppRoutes.orders: AppTransitions.fadeThrough,
    AppRoutes.transactions: AppTransitions.fadeThrough,
    // Login → Home + checkout / wallet money flow — forward navigation.
    AppRoutes.shell: AppTransitions.sharedAxisX,
    AppRoutes.wallet: AppTransitions.sharedAxisX,
    AppRoutes.deposit: AppTransitions.sharedAxisX,
    AppRoutes.manualDeposit: AppTransitions.sharedAxisX,
    AppRoutes.withdraw: AppTransitions.sharedAxisX,
    AppRoutes.topup: AppTransitions.sharedAxisX,
    AppRoutes.productBuy: AppTransitions.sharedAxisX,
    // Payment gateway — modal surface that rises up.
    AppRoutes.depositWebview: AppTransitions.sharedAxisY,
  };

  /// Per-category duration, all inside the 250–300ms premium band.
  static Duration _durationFor(CustomTransition t) {
    // Zoom + payment slide-up read best a touch longer (300ms); the lateral
    // fade-through / shared-axis-X swaps stay crisp at 260ms.
    if (identical(t, AppTransitions.zoom) ||
        identical(t, AppTransitions.sharedAxisY)) {
      return AppMotion.emphasized; // 300
    }
    return AppMotion.drill; // 260 — fade through + shared axis X
  }

  static final routes = _pages.map((p) {
    final t = _special[p.name] ?? AppTransitions.zoom;
    return p.copy(customTransition: t, transitionDuration: _durationFor(t));
  }).toList();

  static final _pages = <GetPage>[
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
    GetPage(name: AppRoutes.login, page: () => const LoginScreen()),
    GetPage(name: AppRoutes.register, page: () => const RegisterScreen()),
    GetPage(name: AppRoutes.shell, page: () => const ShellScreen()),
    GetPage(name: AppRoutes.freeFire, page: () => const FreeFireScreen()),
    GetPage(name: AppRoutes.ludo, page: () => const LudoScreen()),
    GetPage(
        name: AppRoutes.ludoMatchList, page: () => const LudoMatchListScreen()),
    GetPage(name: AppRoutes.ludoJoin, page: () => const LudoJoinScreen()),
    GetPage(name: AppRoutes.topup, page: () => const TopupScreen()),
    GetPage(name: AppRoutes.products, page: () => const ProductsScreen()),
    GetPage(name: AppRoutes.productBuy, page: () => const ProductBuyScreen()),
    GetPage(name: AppRoutes.orders, page: () => const OrderHistoryScreen()),
    GetPage(
        name: AppRoutes.uploadEvidence,
        page: () => const UploadEvidenceScreen()),
    GetPage(name: AppRoutes.matchList, page: () => const MatchListScreen()),
    GetPage(name: AppRoutes.matchInfo, page: () => const MatchInfoScreen()),
    GetPage(name: AppRoutes.joinMatch, page: () => const JoinMatchScreen()),
    GetPage(name: AppRoutes.matchRules, page: () => const MatchRulesScreen()),
    GetPage(name: AppRoutes.myMatches, page: () => const MyMatchesScreen()),
    GetPage(name: AppRoutes.wallet, page: () => const WalletScreen()),
    GetPage(name: AppRoutes.deposit, page: () => const DepositScreen()),
    GetPage(
        name: AppRoutes.manualDeposit,
        page: () => const ManualDepositScreen()),
    GetPage(
        name: AppRoutes.depositWebview,
        page: () => const DepositWebviewScreen()),
    GetPage(name: AppRoutes.withdraw, page: () => const WithdrawScreen()),
    GetPage(
        name: AppRoutes.transactions, page: () => const TransactionsScreen()),
    GetPage(name: AppRoutes.editProfile, page: () => const EditProfileScreen()),
    GetPage(name: AppRoutes.topPlayers, page: () => const TopPlayersScreen()),
    GetPage(name: AppRoutes.terms, page: () => const TermsScreen()),
    GetPage(name: AppRoutes.developer, page: () => const DeveloperScreen()),
  ];
}
