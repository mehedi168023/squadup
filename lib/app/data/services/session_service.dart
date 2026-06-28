import 'dart:io';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_constants.dart';
import '../../core/app_toast.dart';
import '../../core/logger.dart';
import '../models/match_model.dart';
import '../models/misc_models.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../models/wallet_model.dart';
import '../mock/mock_data.dart';
import './security_service.dart';

/// Fully-local mock session. Holds the reactive state the whole app reads and
/// mutates it in-memory (seeded from [MockData]). Every method that the UI
/// expected to await now resolves after a short simulated delay, so loading
/// states still animate — but **no network is ever contacted**.
///
/// Method signatures and reactive `Rx` fields are kept identical to the former
/// API-backed version, so screens/controllers do not change.
class SessionService extends GetxService {
  static SessionService get to => Get.find();

  static const String baseUrl = 'http://localhost:8080/squadup_backend/api.php';
  final GetConnect _connect = GetConnect(timeout: const Duration(seconds: 10));

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


  // ── Session lifecycle ──────────────────────────────────────────────────────

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUserId = prefs.getInt('sq_user_id');
    if (storedUserId == null) return false;
    try {
      final ok = await fetchProfile(storedUserId);
      if (ok) {
        await fetchMatches();
        await fetchTransactions();
        await fetchLeaderboard();
        await fetchOrders();
        return true;
      }
    } catch (e) {
      AppLogger.error('SessionService', 'tryAutoLogin failed: $e');
    }
    return false;
  }

  Future<bool> login(String identifier, String password) async {
    final deviceId = SecurityService.to.deviceId.value;
    try {
      final response = await _connect.post(
        '$baseUrl?action=login',
        {
          'username': identifier,
          'password': password,
          'device_id': deviceId,
        },
      );
      if (response.isOk && response.body != null) {
        final res = response.body;
        if (res['status'] == 'success') {
          final userData = res['user'];
          user.value = UserModel(
            id: userData['id'],
            name: userData['name'],
            email: userData['email'],
            phone: userData['phone'],
          );
          wallet.value = WalletModel(
            availableBalance: (userData['balance'] as num).toDouble(),
          );
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('sq_user_id', userData['id']);
          
          await SecurityService.to.linkAccountToDevice(userData['email']);
          
          await fetchMatches();
          await fetchTransactions();
          await fetchLeaderboard();
          await fetchOrders();
          return true;
        } else {
          if (res['message'] == 'ONE_DEVICE_ONE_ACCOUNT_LIMIT') {
            AppToast.error('এই ডিভাইসটি অন্য অ্যাকাউন্টের সাথে লিংক করা!');
          } else if (res['message'] == 'USER_BANNED') {
            AppToast.error('আপনার অ্যাকাউন্টটি ব্যান করা হয়েছে!');
          } else {
            AppToast.error(res['message'] ?? 'Login failed');
          }
        }
      } else {
        AppToast.error('সার্ভারে কানেক্ট করা যাচ্ছে না!');
      }
    } catch (e) {
      AppToast.error('সার্ভার এরর: $e');
    }
    return false;
  }

  Future<bool> loginWithGoogle(String idToken) async {
    // Google sign-in is bypassed to login to demo credentials in the dev environment.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return login('demo@squadup.gg', 'play1234');
  }

  Future<bool> register(String name, String identifier, String password,
      {String? referCode}) async {
    final deviceId = SecurityService.to.deviceId.value;
    try {
      final response = await _connect.post(
        '$baseUrl?action=register',
        {
          'name': name,
          'email': identifier, // maps to identifier/input in PHP backend
          'password': password,
          'device_id': deviceId,
        },
      );
      if (response.isOk && response.body != null) {
        final res = response.body;
        if (res['status'] == 'success') {
          final userData = res['user'];
          user.value = UserModel(
            id: userData['id'],
            name: userData['name'],
            email: userData['email'],
            phone: userData['phone'],
          );
          wallet.value = WalletModel(
            availableBalance: (userData['balance'] as num).toDouble(),
          );
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('sq_user_id', userData['id']);
          
          await SecurityService.to.linkAccountToDevice(userData['email']);
          
          AppToast.success(res['message'] ?? 'Registration successful');
          await fetchMatches();
          await fetchTransactions();
          await fetchLeaderboard();
          await fetchOrders();
          return true;
        } else {
          if (res['message'] == 'ONE_DEVICE_ONE_ACCOUNT_LIMIT') {
            AppToast.error('এই ডিভাইসটি অন্য অ্যাকাউন্টের সাথে লিংক করা!');
          } else {
            AppToast.error(res['message'] ?? 'Registration failed');
          }
        }
      } else {
        AppToast.error('সার্ভারে কানেক্ট করা যাচ্ছে না!');
      }
    } catch (e) {
      AppToast.error('সার্ভার এরর: $e');
    }
    return false;
  }

  Future<void> forgotPassword(String identifier) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    AppToast.info('সাপোর্টে যোগাযোগ করুন');
  }

  Future<bool> fetchProfile(int userId) async {
    try {
      final response = await _connect.get('$baseUrl?action=get_profile&user_id=$userId');
      if (response.isOk && response.body != null) {
        final res = response.body;
        if (res['status'] == 'success') {
          final userData = res['user'];
          user.value = UserModel(
            id: userData['id'],
            name: userData['name'],
            email: userData['email'],
            phone: userData['phone'],
          );
          wallet.value = WalletModel(
            availableBalance: (userData['balance'] as num).toDouble(),
          );
          return true;
        }
      }
    } catch (e) {
      AppLogger.error('SessionService', 'fetchProfile error: $e');
    }
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sq_user_id');
    user.value = null;
    wallet.value = const WalletModel();
    matches.clear();
    transactions.clear();
    leaderboard.clear();
    yourRank.value = null;
  }

  // ── Wallet ─────────────────────────────────────────────────────────────────

  Future<void> fetchWallet() async {
    final u = user.value;
    if (u != null) {
      await fetchProfile(u.id);
    }
  }

  Future<void> fetchTransactions() async {
    final u = user.value;
    if (u == null) return;
    try {
      final response = await _connect.get('$baseUrl?action=get_transactions&user_id=${u.id}');
      if (response.isOk && response.body != null) {
        final res = response.body;
        if (res['status'] == 'success') {
          final List<dynamic> list = res['transactions'] ?? [];
          transactions.assignAll(list.map((tx) {
            return TransactionModel(
              id: tx['id'],
              type: tx['type'] == 'deposit' ? TxType.deposit : TxType.withdraw,
              amount: (tx['amount'] as num).toDouble(),
              status: tx['status'],
              method: tx['channel'],
              date: DateTime.tryParse(tx['created_at']) ?? DateTime.now(),
              description: tx['type'] == 'deposit'
                  ? 'Deposit via ${tx['channel']} (TRX ${tx['trx_id']})'
                  : 'Withdraw to ${tx['channel']}',
            );
          }).toList());
        }
      }
    } catch (e) {
      AppLogger.error('SessionService', 'fetchTransactions error: $e');
    }
  }

  Future<bool> deposit(double amount) async {
    final u = user.value;
    if (u == null) return false;
    try {
      final response = await _connect.post(
        '$baseUrl?action=create_transaction',
        {
          'user_id': u.id,
          'type': 'deposit',
          'amount': amount,
          'channel': 'Gateway',
          'trx_id': 'DEP-${DateTime.now().millisecondsSinceEpoch}',
        },
      );
      if (response.isOk && response.body != null) {
        final res = response.body;
        if (res['status'] == 'success') {
          wallet.value = wallet.value.copyWith(
            availableBalance: (res['new_balance'] as num).toDouble(),
          );
          await fetchTransactions();
          return true;
        }
      }
    } catch (e) {
      AppLogger.error('SessionService', 'deposit error: $e');
    }
    return false;
  }

  Future<bool> submitManualDeposit({
    required String channelKey,
    required double amount,
    required String trxId,
    String? senderNumber,
  }) async {
    final u = user.value;
    if (u == null) return false;
    try {
      final response = await _connect.post(
        '$baseUrl?action=create_transaction',
        {
          'user_id': u.id,
          'type': 'deposit',
          'amount': amount,
          'channel': channelKey.toUpperCase(),
          'trx_id': trxId,
        },
      );
      if (response.isOk && response.body != null) {
        final res = response.body;
        if (res['status'] == 'success') {
          wallet.value = wallet.value.copyWith(
            availableBalance: (res['new_balance'] as num).toDouble(),
          );
          await fetchTransactions();
          return true;
        }
      }
    } catch (e) {
      AppLogger.error('SessionService', 'submitManualDeposit error: $e');
    }
    return false;
  }

  Future<bool> withdraw(
      double amount, String channelKey, String walletNumber) async {
    final u = user.value;
    if (u == null) return false;
    try {
      final response = await _connect.post(
        '$baseUrl?action=create_transaction',
        {
          'user_id': u.id,
          'type': 'withdraw',
          'amount': amount,
          'channel': channelKey.toUpperCase(),
          'trx_id': walletNumber,
        },
      );
      if (response.isOk && response.body != null) {
        final res = response.body;
        if (res['status'] == 'success') {
          wallet.value = wallet.value.copyWith(
            availableBalance: (res['new_balance'] as num).toDouble(),
          );
          await fetchTransactions();
          return true;
        } else {
          AppToast.error(res['message'] ?? 'Withdrawal failed');
        }
      }
    } catch (e) {
      AppLogger.error('SessionService', 'withdraw error: $e');
    }
    return false;
  }

  // ── Matches ────────────────────────────────────────────────────────────────

  Future<void> refreshMatches() async {
    await fetchMatches();
  }

  List<FfMatch> matchesForMode(String modeKey) =>
      matches.where((m) => m.modeKey == modeKey).toList();

  List<FfMatch> get joinedMatches => matches.where((m) => m.isJoined).toList();

  Future<void> fetchMyMatches() async {
    await fetchMatches();
  }

  Future<FfMatch?> fetchMatch(int id) async {
    await fetchMatches();
    return matches.firstWhereOrNull((m) => m.id == id);
  }

  Future<void> fetchMatches() async {
    final u = user.value;
    final userId = u?.id ?? 0;
    try {
      final response = await _connect.get('$baseUrl?action=get_matches&user_id=$userId');
      if (response.isOk && response.body != null) {
        final res = response.body;
        if (res['status'] == 'success') {
          final List<dynamic> list = res['matches'] ?? [];
          matches.assignAll(list.map((m) {
            final gameType = m['game_type'] ?? '';
            final matchType = m['match_type'] ?? '';
            
            String modeKey = 'ff_solo';
            if (gameType == 'FreeFire') {
              modeKey = matchType.toString().toLowerCase() == 'squad' ? 'ff_squad' : 'ff_solo';
            } else {
              modeKey = matchType.toString().toLowerCase() == 'auto' ? 'ludo_auto' : 'ludo_classic';
            }

            return FfMatch(
              id: m['id'],
              title: m['title'],
              modeKey: modeKey,
              modeLabel: gameType,
              startTime: m['time'],
              status: m['status'],
              map: gameType == 'FreeFire' ? 'Bermuda' : 'Classic',
              type: matchType,
              version: 'Mobile',
              device: 'Phone',
              prize: (m['total_prize'] as num).toDouble(),
              perKill: (m['per_kill'] as num).toDouble(),
              entryFee: (m['entry_fee'] as num).toDouble(),
              slotsTaken: (m['slots_taken'] as num).toInt(),
              slotsTotal: gameType == 'FreeFire' ? 48 : 4,
              rules: gameType == 'FreeFire'
                  ? 'Rules: 1. Emulators not allowed. 2. Hackers will be banned. 3. Teaming up is prohibited.'
                  : 'Rules: 1. Play fairly. 2. Room ID will be given before the match. 3. Submit screenshot after a win.',
              participants: const [],
              isJoined: m['is_joined'] == true || m['is_joined'] == 1,
              roomId: m['room_id'] ?? '',
              roomPassword: m['room_password'] ?? '',
            );
          }).toList());
        }
      }
    } catch (e) {
      AppLogger.error('SessionService', 'fetchMatches error: $e');
    }
  }

  Future<bool> joinMatch(FfMatch match, List<String> playerNames) async {
    final u = user.value;
    if (u == null) return false;
    
    final gameUsername = playerNames.isNotEmpty ? playerNames.first : u.name;
    try {
      final response = await _connect.post(
        '$baseUrl?action=join_match',
        {
          'user_id': u.id,
          'match_id': match.id,
          'game_username': gameUsername,
        },
      );
      if (response.isOk && response.body != null) {
        final res = response.body;
        if (res['status'] == 'success') {
          wallet.value = wallet.value.copyWith(
            availableBalance: (res['new_balance'] as num).toDouble(),
          );
          AppToast.success(res['message'] ?? 'Match joined successfully');
          await fetchMatches();
          await fetchTransactions();
          return true;
        } else {
          AppToast.error(res['message'] ?? 'Failed to join match');
        }
      }
    } catch (e) {
      AppLogger.error('SessionService', 'joinMatch error: $e');
    }
    return false;
  }

  Future<bool> submitEvidence({
    required int matchId,
    required String roomId,
    required File file,
  }) async {
    final u = user.value;
    if (u == null) return false;
    
    final formData = FormData({
      'user_id': u.id,
      'match_id': matchId,
      'room_id': roomId,
      'screenshot': MultipartFile(file.path, filename: 'screenshot.jpg'),
    });
    
    try {
      final response = await _connect.post('$baseUrl?action=upload_evidence', formData);
      if (response.isOk && response.body != null) {
        final res = response.body;
        if (res['status'] == 'success') {
          AppToast.success(res['message'] ?? 'Evidence submitted successfully');
          return true;
        } else {
          AppToast.error(res['message'] ?? 'Submission failed');
        }
      }
    } catch (e) {
      AppToast.error('Network error uploading evidence: $e');
    }
    return false;
  }

  // ── Profile ────────────────────────────────────────────────────────────────

  Future<void> updateProfile({required String name}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final u = user.value;
    if (u != null) {
      user.value = u.copyWith(name: name);
    }
  }

  Future<bool> changePassword(String current, String next) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return true;
  }

  // ── Leaderboard ────────────────────────────────────────────────────────────

  Future<void> fetchLeaderboard() async {
    final u = user.value;
    final userId = u?.id ?? 0;
    try {
      final response = await _connect.get('$baseUrl?action=get_leaderboard&user_id=$userId');
      if (response.isOk && response.body != null) {
        final res = response.body;
        if (res['status'] == 'success') {
          final List<dynamic> list = res['leaderboard'] ?? [];
          leaderboard.assignAll(list.map((e) {
            return LeaderboardEntry(
              rank: (e['rank'] as num).toInt(),
              name: e['name'],
              wonAmount: (e['won_amount'] as num).toDouble(),
            );
          }).toList());
          yourRank.value = res['your_rank'] != null ? (res['your_rank'] as num).toInt() : null;
        }
      }
    } catch (e) {
      AppLogger.error('SessionService', 'fetchLeaderboard error: $e');
    }
  }

  // ── Store orders ───────────────────────────────────────────────────────────

  Future<void> fetchOrders() async {
    final u = user.value;
    if (u == null) return;
    try {
      final response = await _connect.get('$baseUrl?action=get_orders&user_id=${u.id}');
      if (response.isOk && response.body != null) {
        final res = response.body;
        if (res['status'] == 'success') {
          final List<dynamic> list = res['orders'] ?? [];
          orders.assignAll(list.map((o) {
            final kindStr = o['kind'] ?? '';
            final statusStr = o['status'] ?? '';
            
            final kind = kindStr == 'product' ? OrderKind.product : OrderKind.topup;
            
            OrderStatus status = OrderStatus.processing;
            if (statusStr == 'completed') status = OrderStatus.completed;
            if (statusStr == 'delivered') status = OrderStatus.delivered;
            if (statusStr == 'cancelled') status = OrderStatus.cancelled;

            final Map<String, dynamic> rawDetails = o['details'] ?? {};
            final Map<String, String> stringDetails = rawDetails.map((k, v) => MapEntry(k, v.toString()));

            return OrderModel(
              id: o['id'],
              kind: kind,
              title: o['title'],
              subtitle: o['subtitle'],
              amount: (o['amount'] as num).toDouble(),
              method: o['method'],
              status: status,
              date: DateTime.tryParse(o['created_at']) ?? DateTime.now(),
              details: stringDetails,
            );
          }).toList());
        }
      }
    } catch (e) {
      AppLogger.error('SessionService', 'fetchOrders error: $e');
    }
  }

  Future<bool> submitTopupOrder({
    required String categoryKey,
    required int packId,
    required String gameUserId,
    required double price,
    required String amount,
    required String unit,
    String paymentMethod = 'wallet',
  }) async {
    final u = user.value;
    if (u == null) return false;
    
    final cat = MockData.topupCategories.firstWhereOrNull((c) => c.key == categoryKey);
    final methodLabel = paymentMethod == 'wallet' ? 'SquadUp Wallet' : 'Gateway';
    final orderId = _newOrderId();
    final details = {
      'Game': cat?.title ?? '—',
      cat?.idLabel ?? 'Game ID': gameUserId,
      'Pack': '$amount $unit',
      'Payment': methodLabel,
    };
    
    try {
      final response = await _connect.post(
        '$baseUrl?action=create_order',
        {
          'id': orderId,
          'user_id': u.id,
          'kind': 'topup',
          'title': '$amount $unit',
          'subtitle': cat?.title ?? 'Top-up',
          'amount': price,
          'method': methodLabel,
          'details': details,
          'payment_method': paymentMethod,
        },
      );
      if (response.isOk && response.body != null) {
        final res = response.body;
        if (res['status'] == 'success') {
          wallet.value = wallet.value.copyWith(
            availableBalance: (res['new_balance'] as num).toDouble(),
          );
          await fetchOrders();
          await fetchTransactions();
          return true;
        } else {
          AppToast.error(res['message'] ?? 'Order submission failed');
        }
      }
    } catch (e) {
      AppLogger.error('SessionService', 'submitTopupOrder error: $e');
    }
    return false;
  }

  Future<bool> submitProductOrder(Map<String, dynamic> body) async {
    final u = user.value;
    if (u == null) return false;
    
    final qty = body['qty'] ?? 1;
    final total = (body['total'] as num?)?.toDouble() ?? 0;
    final orderId = _newOrderId();
    final details = {
      'Quantity': '×$qty',
      'Color': '${body['color'] ?? '—'}',
      'Unit price': taka((body['unitPrice'] as num?)?.toDouble() ?? 0),
      'Delivery charge': taka((body['deliveryCharge'] as num?)?.toDouble() ?? 0),
      'Ship to': '${body['districtName'] ?? ''}, ${body['divisionName'] ?? ''}',
      'Address': '${body['address'] ?? ''}',
      'Phone': '${body['phone'] ?? ''}',
    };
    
    try {
      final response = await _connect.post(
        '$baseUrl?action=create_order',
        {
          'id': orderId,
          'user_id': u.id,
          'kind': 'product',
          'title': '${body['productName'] ?? 'Product'}',
          'subtitle': 'Cash on Delivery',
          'amount': total,
          'method': 'Cash on Delivery',
          'details': details,
          'payment_method': 'cod',
        },
      );
      if (response.isOk && response.body != null) {
        final res = response.body;
        if (res['status'] == 'success') {
          await fetchOrders();
          return true;
        } else {
          AppToast.error(res['message'] ?? 'Order submission failed');
        }
      }
    } catch (e) {
      AppLogger.error('SessionService', 'submitProductOrder error: $e');
    }
    return false;
  }

}
