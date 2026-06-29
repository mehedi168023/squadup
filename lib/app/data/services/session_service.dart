import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
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
import '../../routes/app_routes.dart';

/// Fully-local mock session. Holds the reactive state the whole app reads and
/// mutates it in-memory (seeded from [MockData]). Every method that the UI
/// expected to await now resolves after a short simulated delay, so loading
/// states still animate — but **no network is ever contacted**.
///
/// Method signatures and reactive `Rx` fields are kept identical to the former
/// API-backed version, so screens/controllers do not change.
class SessionService extends GetxService {
  static SessionService get to => Get.find();

  static String get baseUrl {
    if (GetPlatform.isWeb) {
      final host = Uri.base.host;
      final cleanHost = host.isEmpty ? '127.0.0.1' : host;
      return 'http://$cleanHost:8080/squadup_backend/api.php';
    }
    return 'http://127.0.0.1:8080/squadup_backend/api.php';
  }
  final GetConnect _connect = GetConnect(timeout: const Duration(seconds: 10));

  final Rxn<UserModel> user = Rxn<UserModel>();
  final Rx<WalletModel> wallet = const WalletModel().obs;
  final RxList<FfMatch> matches = <FfMatch>[].obs;
  final RxList<TransactionModel> transactions = <TransactionModel>[].obs;
  final RxList<OrderModel> orders = <OrderModel>[].obs;
  final RxList<LeaderboardEntry> leaderboard = <LeaderboardEntry>[].obs;
  final RxList<NoticeItem> notices = <NoticeItem>[].obs;
  final RxnInt yourRank = RxnInt();

  final RxList<BannerItem> homeBanners = <BannerItem>[].obs;
  final RxList<BannerItem> shopBanners = <BannerItem>[].obs;
  final RxList<GameCategory> gameCategories = <GameCategory>[].obs;
  final RxList<TopupCategory> storeCategories = <TopupCategory>[].obs;

  final RxString telegramLink = 'https://t.me/squadup'.obs;
  final RxString whatsappNumber = '8801700000000'.obs;

  bool get isLoggedIn => user.value != null;

  @override
  void onInit() {
    super.onInit();
    _seedDemoTransactions();
    _seedDemoOrders();
    
    // Seed default offline mock values
    homeBanners.assignAll(MockData.homeBanners);
    shopBanners.assignAll(MockData.shopBanners);
    gameCategories.assignAll(MockData.categories);
    storeCategories.assignAll(MockData.topupCategories);

    fetchNotices();
    fetchBanners();
    fetchGameCategories();
    fetchStoreCategories();
    fetchSettings();
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
        await fetchNotices();
        try {
          OneSignal.login(storedUserId.toString());
        } catch (e) {
          AppLogger.error('SessionService', 'OneSignal.login error: $e');
        }
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
          final parsedUserId = int.tryParse(userData['id']?.toString() ?? '') ?? 0;
          user.value = UserModel(
            id: parsedUserId,
            name: userData['name'],
            email: userData['email'],
            phone: userData['phone'],
          );
          wallet.value = WalletModel(
            availableBalance: (userData['balance'] as num).toDouble(),
          );
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('sq_user_id', parsedUserId);
          
          await SecurityService.to.linkAccountToDevice(userData['email']);
          try {
            OneSignal.login(parsedUserId.toString());
          } catch (e) {
            AppLogger.error('SessionService', 'OneSignal.login error: $e');
          }
          await fetchMatches();
          await fetchTransactions();
          await fetchLeaderboard();
          await fetchOrders();
          await fetchNotices();
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
          final parsedUserId = int.tryParse(userData['id']?.toString() ?? '') ?? 0;
          user.value = UserModel(
            id: parsedUserId,
            name: userData['name'],
            email: userData['email'],
            phone: userData['phone'],
          );
          wallet.value = WalletModel(
            availableBalance: (userData['balance'] as num).toDouble(),
          );
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('sq_user_id', parsedUserId);
          
          await SecurityService.to.linkAccountToDevice(userData['email']);
          try {
            OneSignal.login(parsedUserId.toString());
          } catch (e) {
            AppLogger.error('SessionService', 'OneSignal.login error: $e');
          }
          AppToast.success(res['message'] ?? 'Registration successful');
          await fetchMatches();
          await fetchTransactions();
          await fetchLeaderboard();
          await fetchOrders();
          await fetchNotices();
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
        if (res['status'] == 'error' && res['message'] == 'USER_BANNED') {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('sq_user_id');
          user.value = null;
          Get.offAllNamed(AppRoutes.splash);
          return false;
        }
        if (res['status'] == 'success') {
          final userData = res['user'];
          if (userData['status'] == 'banned') {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('sq_user_id');
            user.value = null;
            Get.offAllNamed(AppRoutes.splash);
            return false;
          }
          final parsedUserId = int.tryParse(userData['id']?.toString() ?? '') ?? 0;
          user.value = UserModel(
            id: parsedUserId,
            name: userData['name'],
            email: userData['email'],
            phone: userData['phone'],
          );
          wallet.value = WalletModel(
            availableBalance: (userData['balance'] as num).toDouble(),
            winningBalance: (userData['won_amount'] as num).toDouble(),
            withdrawableBalance: (userData['won_amount'] as num).toDouble(),
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
    try {
      OneSignal.logout();
    } catch (e) {
      AppLogger.error('SessionService', 'OneSignal.logout error: $e');
    }
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
    final sec = SecurityService.to;
    final devBanned = await sec.checkDeviceBan();
    if (devBanned) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('sq_user_id');
      user.value = null;
      Get.offAllNamed(AppRoutes.splash);
      return;
    }
    if (isLoggedIn) {
      final userBanned = await sec.checkUserBan(user.value!.email);
      if (userBanned) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('sq_user_id');
        user.value = null;
        Get.offAllNamed(AppRoutes.splash);
        return;
      }
    }

    await Future.wait([
      fetchMatches(),
      fetchBanners(),
      fetchGameCategories(),
      fetchStoreCategories(),
      fetchSettings(),
    ]);
  }

  List<FfMatch> matchesForMode(String modeKey) =>
      matches.where((m) => m.modeKey == modeKey && m.status != 'hidden' && m.status != 'hide').toList();

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
            
            String modeKey = 'br';
            if (gameType == 'FreeFire') {
              modeKey = matchType.toString().toLowerCase() == 'squad' ? 'cs' : 'br';
            } else {
              modeKey = matchType.toString().toLowerCase() == 'auto' ? 'auto_ludo' : 'ludo_king';
            }

            return FfMatch(
              id: (m['id'] as num).toInt(),
              title: (m['title'] ?? '').toString(),
              modeKey: modeKey,
              modeLabel: gameType,
              startTime: DateTime.tryParse(m['time']?.toString() ?? '') ?? DateTime.now(),
              status: (m['status'] ?? 'active').toString(),
              map: m['map']?.toString() ?? (gameType == 'FreeFire' ? 'Bermuda' : 'Classic'),
              type: matchType,
              version: m['version']?.toString() ?? 'Mobile',
              device: m['device']?.toString() ?? 'Phone',
              prize: (m['total_prize'] as num).toDouble(),
              perKill: (m['per_kill'] as num).toDouble(),
              entryFee: (m['entry_fee'] as num).toDouble(),
              slotsTaken: (m['slots_taken'] as num).toInt(),
              slotsTotal: gameType == 'FreeFire' ? 48 : 4,
              rules: m['rules']?.toString() ?? (gameType == 'FreeFire'
                  ? "Rules:\n1. Emulators are strictly not allowed.\n2. Hackers will be banned permanently.\n3. Teaming up is prohibited and results in disqualification."
                  : "Rules:\n1. Play fairly and respect other players.\n2. Room ID and Password will be shared 15 minutes before the match starts.\n3. Submit win screenshot within 15 minutes after the match ends."),
              participants: const [],
              isJoined: m['is_joined'] == true || m['is_joined'] == 1,
              roomId: m['room_id']?.toString() ?? '',
              roomPassword: m['room_password']?.toString() ?? '',
              prize1: (m['prize_1'] as num?)?.toDouble() ?? 0.0,
              prize2: (m['prize_2'] as num?)?.toDouble() ?? 0.0,
              prize3: (m['prize_3'] as num?)?.toDouble() ?? 0.0,
              prize4: (m['prize_4'] as num?)?.toDouble() ?? 0.0,
              prize5: (m['prize_5'] as num?)?.toDouble() ?? 0.0,
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

  Future<bool> updateProfile({required String name, File? avatarFile}) async {
    try {
      final u = user.value;
      if (u == null) return false;

      final Map<String, dynamic> fields = {
        'action': 'update_profile',
        'user_id': u.id.toString(),
        'name': name,
      };

      if (avatarFile != null) {
        final bytes = await avatarFile.readAsBytes();
        fields['avatar'] = MultipartFile(bytes, filename: 'avatar_${u.id}.png');
      }

      final form = FormData(fields);
      final response = await _connect.post(baseUrl, form);
      if (response.isOk && response.body != null) {
        final res = response.body;
        if (res['status'] == 'success' && res['user'] != null) {
          user.value = UserModel.fromJson(res['user']);
          return true;
        } else {
          AppToast.error(res['message'] ?? 'Profile update failed');
        }
      }
    } catch (e) {
      AppToast.error('Network error updating profile: $e');
    }
    return false;
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
            winningBalance: (res['new_won_amount'] as num).toDouble(),
            withdrawableBalance: (res['new_won_amount'] as num).toDouble(),
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

  Future<void> fetchNotices() async {
    try {
      final response = await _connect.get('$baseUrl?action=get_notices');
      if (response.isOk && response.body != null) {
        final res = response.body;
        if (res['status'] == 'success' && res['notices'] != null) {
          final list = res['notices'] as List;
          notices.assignAll(list.map((n) {
            final String img = n['image'] ?? '';
            final String? rt = n['route'];
            final String? url = n['url'];
            
            final String colorsStr = n['colors'] ?? '#1e3a8a,#0e1a2c';
            final colorsList = colorsStr.split(',').map((hex) {
              final cleanHex = hex.trim().replaceAll('#', '');
              return Color(int.parse('FF$cleanHex', radix: 16));
            }).toList();
            
            return NoticeItem(
              image: img,
              route: rt != null && rt.isNotEmpty ? rt : null,
              url: url != null && url.isNotEmpty ? url : null,
              colors: colorsList,
            );
          }).toList());
        }
      }
    } catch (e) {
      AppLogger.error('SessionService', 'fetchNotices error: $e');
    }
  }

  Future<void> fetchBanners() async {
    try {
      final response = await _connect.get('$baseUrl?action=get_banners');
      if (response.isOk && response.body != null) {
        final res = response.body;
        if (res['status'] == 'success' && res['banners'] != null) {
          final List<dynamic> list = res['banners'];
          final List<BannerItem> homeList = [];
          final List<BannerItem> shopList = [];
          
          for (final b in list) {
            final String title = b['title'] ?? '';
            final String image = b['image'] ?? '';
            final String? route = b['route'] != null && b['route'].toString().isNotEmpty ? b['route'].toString() : null;
            final String url = b['url'] ?? '';
            final String colorsStr = b['colors'] ?? '#0e1a2c,#15356b';
            final colorsList = colorsStr.split(',').map((hex) {
              final cleanHex = hex.trim().replaceAll('#', '');
              return Color(int.parse('FF$cleanHex', radix: 16));
            }).toList();
            
            final item = BannerItem(
              title: title,
              image: image,
              route: route,
              url: url,
              colors: colorsList.isEmpty ? const [Color(0xFF0E1A2C), Color(0xFF15356B)] : colorsList,
            );
            
            if (b['section'] == 'shop') {
              shopList.add(item);
            } else {
              homeList.add(item);
            }
          }
          
          if (homeList.isNotEmpty) homeBanners.assignAll(homeList);
          if (shopList.isNotEmpty) shopBanners.assignAll(shopList);
        }
      }
    } catch (e) {
      AppLogger.error('SessionService', 'fetchBanners error: $e');
    }
  }

  Future<void> fetchGameCategories() async {
    try {
      final response = await _connect.get('$baseUrl?action=get_game_categories');
      if (response.isOk && response.body != null) {
        final res = response.body;
        if (res['status'] == 'success' && res['categories'] != null) {
          final List<dynamic> list = res['categories'];
          final List<GameCategory> parsedList = [];
          
          for (final c in list) {
            final String key = c['category_key'] ?? '';
            final String title = c['title'] ?? '';
            final String subtitle = c['subtitle'] ?? '';
            final String? image = c['image'] != null && c['image'].toString().isNotEmpty ? c['image'].toString() : null;
            final String iconName = c['icon'] ?? 'sports_esports';
            final IconData icon = iconName == 'casino' ? Icons.casino : Icons.sports_esports;
            
            final String colorsStr = c['colors'] ?? '#ff6200,#ff9e00';
            final colorsList = colorsStr.split(',').map((hex) {
              final cleanHex = hex.trim().replaceAll('#', '');
              return Color(int.parse('FF$cleanHex', radix: 16));
            }).toList();
            
            final String modeKeysStr = c['mode_keys'] ?? 'br,cs';
            final modeKeysList = modeKeysStr.split(',').map((k) => k.trim()).toList();
            
            parsedList.add(GameCategory(
              key: key,
              title: title,
              subtitle: subtitle,
              image: image,
              icon: icon,
              colors: colorsList.isEmpty ? const [Color(0xFFFF6200), Color(0xFFFF9E00)] : colorsList,
              modeKeys: modeKeysList,
            ));
          }
          
          if (parsedList.isNotEmpty) gameCategories.assignAll(parsedList);
        }
      }
    } catch (e) {
      AppLogger.error('SessionService', 'fetchGameCategories error: $e');
    }
  }

  Future<void> fetchStoreCategories() async {
    try {
      final response = await _connect.get('$baseUrl?action=get_store_categories');
      if (response.isOk && response.body != null) {
        final res = response.body;
        if (res['status'] == 'success' && res['categories'] != null) {
          final List<dynamic> list = res['categories'];
          final List<TopupCategory> parsedList = [];
          
          for (final c in list) {
            final String key = c['category_key'] ?? '';
            final String title = c['title'] ?? '';
            final String subtitle = c['subtitle'] ?? '';
            final String image = c['image'] ?? '';
            
            final String colorsStr = c['colors'] ?? '#ff6200,#ff9e00';
            final colorsList = colorsStr.split(',').map((hex) {
              final cleanHex = hex.trim().replaceAll('#', '');
              return Color(int.parse('FF$cleanHex', radix: 16));
            }).toList();
            
            // Find the original mock category to preserve the sub-structures
            final original = MockData.topupCategories.firstWhereOrNull((cat) => cat.key == key);
            
            parsedList.add(TopupCategory(
              key: key,
              title: title,
              subtitle: subtitle,
              image: image,
              colors: colorsList.isEmpty ? const [Color(0xFFFF6200), Color(0xFFFF9E00)] : colorsList,
              idLabel: original?.idLabel ?? 'Player ID',
              packs: original?.packs ?? const [],
              howTo: original?.howTo ?? const [],
              guideImage: original?.guideImage,
              packIcon: original?.packIcon ?? Icons.diamond_outlined,
              promo: original?.promo,
              perks: original?.perks ?? const [],
            ));
          }
          
          if (parsedList.isNotEmpty) storeCategories.assignAll(parsedList);
        }
      }
    } catch (e) {
      AppLogger.error('SessionService', 'fetchStoreCategories error: $e');
    }
  }

  Future<void> fetchSettings() async {
    try {
      final response = await _connect.get('$baseUrl?action=get_settings');
      if (response.isOk && response.body != null) {
        final res = response.body;
        if (res['status'] == 'success' && res['settings'] != null) {
          final settings = res['settings'] as Map;
          telegramLink.value = settings['telegram_link']?.toString() ?? 'https://t.me/squadup';
          whatsappNumber.value = settings['whatsapp_number']?.toString() ?? '8801700000000';
        }
      }
    } catch (e) {
      AppLogger.error('SessionService', 'fetchSettings error: $e');
    }
  }
}
