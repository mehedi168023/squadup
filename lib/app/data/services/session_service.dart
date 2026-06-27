import 'package:get/get.dart';
import '../../core/app_constants.dart';
import '../models/match_model.dart';
import '../models/misc_models.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../models/wallet_model.dart';
import '../mock/mock_data.dart';

/// Fully-local mock session. Holds the reactive state the whole app reads and
/// mutates it in-memory (seeded from [MockData]). Every method that the UI
/// expected to await now resolves after a short simulated delay, so loading
/// states still animate — but **no network is ever contacted**.
///
/// Method signatures and reactive `Rx` fields are kept identical to the former
/// API-backed version, so screens/controllers do not change.
class SessionService extends GetxService {
  static SessionService get to => Get.find();

  final Rxn<UserModel> user = Rxn<UserModel>();
  final Rx<WalletModel> wallet = const WalletModel().obs;
  final RxList<FfMatch> matches = <FfMatch>[].obs;
  final RxList<TransactionModel> transactions = <TransactionModel>[].obs;
  final RxList<OrderModel> orders = <OrderModel>[].obs;
  final RxList<LeaderboardEntry> leaderboard = <LeaderboardEntry>[].obs;
  final RxnInt yourRank = RxnInt();

  bool get isLoggedIn => user.value != null;

  @override
  void onInit() {
    super.onInit();
    _seedDemoTransactions();
    _seedDemoOrders();
  }

  /// A few seeded demo transactions so the history screen isn't empty on a
  /// fresh login (mirrors what a real backend would return).
  void _seedDemoTransactions() {
    transactions.assignAll(MockData.demoTransactions);
  }

  /// Seeds a couple of past orders so the Order History reads as a real,
  /// trustworthy purchase record from the first launch.
  void _seedDemoOrders() {
    final now = DateTime.now();
    orders.assignAll([
      OrderModel(
        id: 'SQ-482193',
        kind: OrderKind.topup,
        title: '115 Diamonds',
        subtitle: 'Free Fire Top-up',
        amount: 85,
        method: 'SquadUp Wallet',
        status: OrderStatus.completed,
        date: now.subtract(const Duration(days: 1, hours: 4)),
        details: {
          'Game': 'Free Fire',
          'Free Fire Player ID': '8842016773',
          'Pack': '115 Diamonds',
          'Payment': 'SquadUp Wallet',
        },
      ),
      OrderModel(
        id: 'SQ-479820',
        kind: OrderKind.product,
        title: 'Gaming Headset Kraken',
        subtitle: 'Cash on Delivery',
        amount: 1390,
        method: 'Cash on Delivery',
        status: OrderStatus.delivered,
        date: now.subtract(const Duration(days: 6, hours: 2)),
        details: {
          'Quantity': '×1',
          'Color': 'Black',
          'Ship to': 'Dhaka, Dhaka',
          'Phone': '01708090809',
        },
      ),
    ]);
  }

  /// A short, human-readable order id (e.g. `SQ-481234`).
  String _newOrderId() =>
      'SQ-${(DateTime.now().millisecondsSinceEpoch % 900000) + 100000}';

  void _addOrder(OrderModel o) => orders.insert(0, o);

  // ── Session lifecycle ──────────────────────────────────────────────────────

  /// Mock auto-login: always returns false (no stored session in local mode).
  /// Splash routes to login as expected.
  Future<bool> tryAutoLogin() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return false;
  }

  /// Mock login — any credentials succeed after a short delay. Seeds the user
  /// + wallet + matches + leaderboard from [MockData].
  Future<bool> login(String identifier, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    _hydrate();
    return true;
  }

  /// Mock Google login — always succeeds locally (no real Google SDK).
  Future<bool> loginWithGoogle(String idToken) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    _hydrate();
    return true;
  }

  /// Mock register — creates the in-memory user and enters the app.
  Future<bool> register(String name, String identifier, String password,
      {String? referCode}) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    user.value = MockData.user.copyWith(name: name.isEmpty ? null : name);
    _hydrateWalletAndMatches();
    return true;
  }

  Future<void> forgotPassword(String identifier) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  /// Hydrate the full demo session (user, wallet, matches, leaderboard).
  void _hydrate() {
    user.value = MockData.user;
    _hydrateWalletAndMatches();
  }

  void _hydrateWalletAndMatches() {
    wallet.value = MockData.wallet;
    matches.assignAll(MockData.matches.map((m) => FfMatch(
          id: m.id,
          title: m.title,
          modeKey: m.modeKey,
          modeLabel: m.modeLabel,
          startTime: m.startTime,
          status: m.status,
          map: m.map,
          type: m.type,
          version: m.version,
          device: m.device,
          prize: m.prize,
          perKill: m.perKill,
          entryFee: m.entryFee,
          slotsTaken: m.slotsTaken,
          slotsTotal: m.slotsTotal,
          rules: m.rules,
          participants: m.participants,
          isJoined: m.isJoined,
          roomId: m.roomId,
          roomPassword: m.roomPassword,
        )));
    _seedDemoTransactions();
    leaderboard.assignAll(MockData.leaderboard);
    yourRank.value = MockData.yourRank;
  }

  Future<void> logout() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    user.value = null;
    wallet.value = const WalletModel();
    matches.clear();
    transactions.clear();
    leaderboard.clear();
    yourRank.value = null;
  }

  // ── Wallet ─────────────────────────────────────────────────────────────────

  Future<void> fetchWallet() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  Future<void> fetchTransactions() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  /// Simulates a deposit: credits the wallet and records a transaction.
  Future<bool> deposit(double amount) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final w = wallet.value;
    wallet.value = w.copyWith(
      availableBalance: w.availableBalance + amount,
    );
    _addTransaction(TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch,
      type: TxType.deposit,
      amount: amount,
      status: 'success',
      method: 'Gateway',
      date: DateTime.now(),
      description: 'Wallet deposit',
    ));
    return true;
  }

  /// Submits a manual deposit request (bKash/Nagad/Rocket): the user already
  /// sent money to the agent/personal number, so we record a *pending* deposit
  /// keyed by the TRX id. Balance is credited after verification (not here).
  Future<bool> submitManualDeposit({
    required String channelKey,
    required double amount,
    required String trxId,
    String? senderNumber,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final ch = MockData.depositChannels
        .firstWhereOrNull((c) => c.key == channelKey);
    final from = (senderNumber == null || senderNumber.isEmpty)
        ? ''
        : ' from $senderNumber';
    _addTransaction(TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch,
      type: TxType.deposit,
      amount: amount,
      status: 'pending',
      method: ch?.label ?? 'Manual',
      date: DateTime.now(),
      description: 'Deposit request • TRX $trxId$from',
    ));
    return true;
  }

  /// Simulates a withdrawal: debits the wallet and records a pending tx.
  Future<bool> withdraw(
      double amount, String channelKey, String walletNumber) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    final w = wallet.value;
    wallet.value = w.copyWith(
      availableBalance: (w.availableBalance - amount).clamp(0, double.infinity),
    );
    final label = MockData.withdrawChannels
        .firstWhere((c) => c.key == channelKey,
            orElse: () => MockData.withdrawChannels.first)
        .label;
    _addTransaction(TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch,
      type: TxType.withdraw,
      amount: amount,
      status: 'pending',
      method: label,
      date: DateTime.now(),
      description: 'Withdraw to $label',
    ));
    return true;
  }

  // ── Matches ────────────────────────────────────────────────────────────────

  Future<void> refreshMatches() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  List<FfMatch> matchesForMode(String modeKey) =>
      matches.where((m) => m.modeKey == modeKey).toList();

  List<FfMatch> get joinedMatches => matches.where((m) => m.isJoined).toList();

  /// No-op refresh of joined matches (mock data is already in-memory).
  Future<void> fetchMyMatches() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  Future<FfMatch?> fetchMatch(int id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return matches.firstWhereOrNull((m) => m.id == id);
  }

  /// Simulates joining a match: marks it joined, debits the entry fee and
  /// records a join transaction. Allocates a fake room id/password so the
  /// "My Matches" room card shows.
  Future<bool> joinMatch(FfMatch match, List<String> playerNames) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    final idx = matches.indexWhere((m) => m.id == match.id);
    if (idx >= 0) {
      final m = matches[idx];
      matches[idx] = m.copyWith(
        isJoined: true,
        slotsTaken: (m.slotsTaken + 1).clamp(0, m.slotsTotal),
      );
      matches.refresh();
    }
    final w = wallet.value;
    wallet.value = w.copyWith(
      availableBalance:
          (w.availableBalance - match.entryFee).clamp(0, double.infinity),
    );
    _addTransaction(TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch,
      type: TxType.join,
      amount: match.entryFee,
      status: 'success',
      method: 'System',
      date: DateTime.now(),
      description: 'Joined ${match.title}',
    ));
    return true;
  }

  // ── Profile ────────────────────────────────────────────────────────────────

  Future<void> updateProfile({required String name}) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final u = user.value;
    if (u != null) user.value = u.copyWith(name: name);
  }

  Future<bool> changePassword(String current, String next) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return true;
  }

  // ── Leaderboard ────────────────────────────────────────────────────────────

  Future<void> fetchLeaderboard() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    leaderboard.assignAll(MockData.leaderboard);
    yourRank.value = MockData.yourRank;
  }

  // ── Store orders ───────────────────────────────────────────────────────────

  /// Simulates placing a top-up order. Wallet payments deduct from the balance
  /// and record a transaction; gateway payments just record it.
  Future<bool> submitTopupOrder({
    required String categoryKey,
    required int packId,
    required String gameUserId,
    required double price,
    required String amount,
    required String unit,
    String paymentMethod = 'wallet',
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (paymentMethod == 'wallet') {
      final w = wallet.value;
      wallet.value = w.copyWith(
        availableBalance:
            (w.availableBalance - price).clamp(0, double.infinity),
      );
    }
    final methodLabel = paymentMethod == 'wallet' ? 'SquadUp Wallet' : 'Gateway';
    _addTransaction(TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch,
      type: TxType.join,
      amount: price,
      status: 'success',
      method: paymentMethod == 'wallet' ? 'SquadUp' : 'Gateway',
      date: DateTime.now(),
      description: '$amount $unit top-up',
    ));
    final cat =
        MockData.topupCategories.firstWhereOrNull((c) => c.key == categoryKey);
    _addOrder(OrderModel(
      id: _newOrderId(),
      kind: OrderKind.topup,
      title: '$amount $unit',
      subtitle: cat?.title ?? 'Top-up',
      amount: price,
      method: methodLabel,
      status: OrderStatus.completed,
      date: DateTime.now(),
      details: {
        'Game': cat?.title ?? '—',
        cat?.idLabel ?? 'Game ID': gameUserId,
        'Pack': '$amount $unit',
        'Payment': methodLabel,
      },
    ));
    return true;
  }

  /// Simulates placing a product (e-commerce) order and records it in the
  /// Order History so the user can always see what they bought.
  Future<bool> submitProductOrder(Map<String, dynamic> body) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final qty = body['qty'] ?? 1;
    final total = (body['total'] as num?)?.toDouble() ?? 0;
    _addOrder(OrderModel(
      id: _newOrderId(),
      kind: OrderKind.product,
      title: '${body['productName'] ?? 'Product'}',
      subtitle: 'Cash on Delivery',
      amount: total,
      method: 'Cash on Delivery',
      status: OrderStatus.processing,
      date: DateTime.now(),
      details: {
        'Quantity': '×$qty',
        'Color': '${body['color'] ?? '—'}',
        'Unit price': taka((body['unitPrice'] as num?)?.toDouble() ?? 0),
        'Delivery charge': taka((body['deliveryCharge'] as num?)?.toDouble() ?? 0),
        'Ship to':
            '${body['districtName'] ?? ''}, ${body['divisionName'] ?? ''}',
        'Address': '${body['address'] ?? ''}',
        'Phone': '${body['phone'] ?? ''}',
      },
    ));
    return true;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _addTransaction(TransactionModel tx) {
    transactions.insert(0, tx);
  }
}
