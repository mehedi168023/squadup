import 'package:flutter/material.dart';
import '../../core/app_constants.dart';
import '../models/match_model.dart';
import '../models/misc_models.dart';
import '../models/user_model.dart';
import '../models/wallet_model.dart';

/// Static dummy data backing the demo (no real backend).
class MockData {
  MockData._();

  static const UserModel user = UserModel(
    id: 824,
    name: 'FHBB',
    email: 'ygg@gmail.com',
    phone: '01708090809',
    referCode: 'WZ824',
    totalMatchesPlayed: 0,
    totalMatchesWon: 0,
  );

  static const WalletModel wallet = WalletModel(
    availableBalance: 0,
    winningBalance: 0,
    withdrawableBalance: 0,
  );

  static const String brRules = '''🌻 BR Rules 👇
১. ম্যাচে কোনো প্রকার গাড়ি চালানো যাবে না।
২. ম্যাচ শুরু হওয়ার পর থেকে স্ক্রিন রেকর্ডিং করতে হবে, প্লেন এ উঠার পর রেকর্ডিং বন্ধ করে দিতে পারেন। যেকোনো সময় এডমিন আপনার কাছ থেকে রেকর্ডিং চাইতে পারে।
৩. ম্যাচে কোনো প্রকার হ্যাক বা পেনেল ব্যবহার করার চেষ্টা করলে এপ থেকে ব্যান করে দেওয়া হবে।
৪. ৪০ লেভেল এর নিচে কোনো প্লেয়ার ম্যাচ এ জয়েন করতে পারবে না।
৫. Room এ কেউ বাইরে থেকে প্লেয়ার এড দিলে তাকে প্রাইজ মানি দেওয়া হবে না।
৬. ম্যাচে কোনো প্রকার স্নাইপার ব্যবহার করা যাবে না।
৭. কেউ ৬ টা কিল করলে বা তার চেয়ে বেশি করলে তাকে ৬ কিলের টাকা এবং পজিশন অনুযায়ী টাকা দেওয়া হবে।

🌻❤️ আপনারা আমাদের সাথে থাকুন, আশা করি ভালো কিছু করতে পারবেন। 🌻❤️''';

  static const String csRules = '''🌻 CS Rules 👇
১. CS ম্যাচে শুধুমাত্র ক্লাশ স্কোয়াড মোড খেলা হবে।
২. প্রতি রাউন্ডে গান লেভেল সবার জন্য সমান থাকবে।
৩. কোনো প্রকার ক্যারেক্টার স্কিল ব্যবহার করা যাবে না।
৪. গ্রেনেড ও স্পন বল ব্যবহার করা যাবে।
৫. টিম যত রাউন্ড জিতবে সেই অনুযায়ী প্রাইজ দেওয়া হবে।
৬. ম্যাচ শুরুর ৫ মিনিট আগে রুমে জয়েন করতে হবে।

🌻❤️ ভালো খেলুন, জিতে নিন! 🌻❤️''';

  static const String loneWolfRules = '''🌻 Lone Wolf Rules 👇
১. Lone Wolf শুধু Solo অথবা Duo মোডে খেলা হয়।
২. শুধুমাত্র AWM এবং স্নাইপার ব্যবহার করা যাবে।
৩. কোনো গ্লু ওয়াল বা মেডকিট ব্যবহার করা যাবে না।
৪. ফ্যাক্টরি রুফ এ ফাইট করতে হবে।
৫. যে বেশি কিল করবে সে অনুযায়ী প্রাইজ পাবে।

🌻❤️ বেস্ট অফ লাক! 🌻❤️''';

  static const String freeRules = '''🌻 Free Match Rules 👇
১. এই ম্যাচ সম্পূর্ণ ফ্রি, কোনো এন্ট্রি ফি নেই।
২. সবাই ম্যাচে জয়েন করতে পারবে।
৩. টপ প্লেয়ারদের বোনাস রিওয়ার্ড দেওয়া হবে।
৪. হ্যাক/চিট করলে সাথে সাথে ব্যান।
৫. মজা করে খেলুন, প্র্যাকটিস করুন।

🌻❤️ এনজয় করুন! 🌻❤️''';

  /// Returns the rules text for a given game-mode key.
  static String rulesForMode(String key) => switch (key) {
        'cs' => csRules,
        'lone_wolf' => loneWolfRules,
        'free' => freeRules,
        _ => brRules,
      };

  /// Top-level Home categories. Tap → that category's screen.
  static const List<GameCategory> categories = [
    GameCategory(
      key: 'freefire',
      title: 'Free Fire',
      subtitle: 'JOIN THE BATTLE',
      icon: Icons.local_fire_department_rounded,
      image: AppConstants.freefireLogo,
      colors: [Color(0xFF3A1A14), Color(0xFF131C2B)],
      modeKeys: ['br', 'cs', 'lone_wolf', 'free'],
    ),
    GameCategory(
      key: 'ludo',
      title: 'Ludo Game',
      subtitle: 'ROLL & WIN',
      icon: Icons.casino_rounded,
      image: AppConstants.ludoClassic,
      colors: [Color(0xFF15294D), Color(0xFF101826)],
      modeKeys: ['ludo_king', 'auto_ludo'],
    ),
  ];

  static const List<GameMode> gameModes = [
    GameMode(
        key: 'br',
        title: 'BR MATCH',
        image: AppConstants.freefireLogo,
        matchesFound: 1),
    GameMode(
        key: 'cs',
        title: 'CS MATCH',
        image: AppConstants.freefireLogo,
        matchesFound: 0),
    GameMode(
        key: 'lone_wolf',
        title: 'LONE WOLF',
        image: AppConstants.freefireLogo,
        matchesFound: 4),
    GameMode(
        key: 'free',
        title: 'FREE MATCH',
        image: AppConstants.freefireLogo,
        matchesFound: 0),
  ];

  /// Ludo games (icon-based tiles). Tap → match list (empty for now).
  static const List<GameMode> ludoGames = [
    GameMode(
      key: 'ludo_king',
      title: 'Ludo King',
      image: AppConstants.ludoClassic,
      icon: Icons.casino_rounded,
      subtitle: 'Regular 1 vs 1',
      matchesFound: 0,
    ),
    GameMode(
      key: 'auto_ludo',
      title: 'Auto Ludo',
      image: AppConstants.ludoAuto,
      icon: Icons.smart_toy_rounded,
      subtitle: 'Fast auto-play',
      matchesFound: 0,
    ),
  ];

  static final List<FfMatch> matches = [
    FfMatch(
      id: 138,
      title: 'BR Solo Time 👑',
      modeKey: 'br',
      modeLabel: 'BR MATCH',
      startTime: DateTime.now().add(const Duration(minutes: 52, seconds: 14)),
      status: 'active',
      map: 'Bermuda',
      type: 'Solo',
      prize: 160,
      perKill: 6,
      entryFee: 10,
      slotsTaken: 5,
      slotsTotal: 20,
      rules: brRules,
      participants: const [
        Participant(slot: 1, ign: 'DRP-Tenzoo!'),
        Participant(slot: 2, ign: 'AstraaMvp.'),
        Participant(slot: 3, ign: '『FӾ』SIᗩMㄖYT'),
        Participant(slot: 4, ign: 'miss ueen'),
        Participant(slot: 5, ign: 'Bunny 444'),
      ],
    ),
    FfMatch(
      id: 142,
      title: 'Lone Wolf 2vs2 😋😋',
      modeKey: 'lone_wolf',
      modeLabel: 'LONE WOLF',
      startTime: DateTime.now().add(const Duration(hours: 1, minutes: 30)),
      status: 'active',
      map: 'Bermuda',
      type: 'Duo',
      prize: 100,
      perKill: 0,
      entryFee: 30,
      slotsTaken: 0,
      slotsTotal: 4,
      rules: brRules,
    ),
    FfMatch(
      id: 143,
      title: 'Lone Wolf Solo 🔥',
      modeKey: 'lone_wolf',
      modeLabel: 'LONE WOLF',
      startTime: DateTime.now().add(const Duration(hours: 2)),
      status: 'active',
      map: 'Bermuda',
      type: 'Solo',
      prize: 80,
      perKill: 5,
      entryFee: 15,
      slotsTaken: 2,
      slotsTotal: 8,
      rules: brRules,
    ),
    // ── Ludo matches ──────────────────────────────────────────────
    FfMatch(
      id: 546263,
      title: 'Ludo Classic 1V1',
      modeKey: 'ludo_king',
      modeLabel: 'LUDO',
      startTime: DateTime.now().add(const Duration(minutes: 20)),
      type: '1 vs 1',
      prize: 50,
      entryFee: 30,
      slotsTaken: 1,
      slotsTotal: 2,
    ),
    FfMatch(
      id: 546264,
      title: 'Ludo Classic 1V1',
      modeKey: 'ludo_king',
      modeLabel: 'LUDO',
      startTime: DateTime.now().add(const Duration(minutes: 45)),
      type: '1 vs 1',
      prize: 90,
      entryFee: 50,
      slotsTaken: 0,
      slotsTotal: 2,
    ),
    FfMatch(
      id: 546265,
      title: 'Ludo Classic 1V1',
      modeKey: 'ludo_king',
      modeLabel: 'LUDO',
      startTime: DateTime.now().add(const Duration(hours: 1)),
      type: '1 vs 1',
      prize: 180,
      entryFee: 100,
      slotsTaken: 1,
      slotsTotal: 2,
    ),
    FfMatch(
      id: 778101,
      title: 'Auto Ludo 1V1',
      modeKey: 'auto_ludo',
      modeLabel: 'AUTO LUDO',
      startTime: DateTime.now().add(const Duration(minutes: 30)),
      type: '1 vs 1',
      prize: 36,
      entryFee: 20,
      slotsTaken: 0,
      slotsTotal: 2,
    ),
    FfMatch(
      id: 778102,
      title: 'Auto Ludo 1V1',
      modeKey: 'auto_ludo',
      modeLabel: 'AUTO LUDO',
      startTime: DateTime.now().add(const Duration(minutes: 55)),
      type: '1 vs 1',
      prize: 95,
      entryFee: 50,
      slotsTaken: 1,
      slotsTotal: 2,
    ),
  ];

  static const List<LeaderboardEntry> leaderboard = [
    LeaderboardEntry(rank: 1, name: 'Rayhan', wonAmount: 770),
    LeaderboardEntry(rank: 2, name: 'Rakinislam', wonAmount: 360),
    LeaderboardEntry(rank: 3, name: 'SMG RIFAT YT', wonAmount: 235),
    LeaderboardEntry(rank: 4, name: 'Alamin1100', wonAmount: 230),
    LeaderboardEntry(rank: 5, name: 'Alamin1100', wonAmount: 200),
    LeaderboardEntry(rank: 6, name: 'Mdmuhin', wonAmount: 185),
    LeaderboardEntry(rank: 7, name: 'MD SOBIF', wonAmount: 160),
    LeaderboardEntry(rank: 8, name: 'Tanvir99', wonAmount: 140),
  ];

  static const int yourRank = 44;

  // Image banners. `route` opens an in-app screen, `url` opens an external link.
  static const List<BannerItem> homeBanners = [
    BannerItem(
      title: 'How to add money',
      image: AppConstants.bannerAddMoney,
      route: '/deposit',
      colors: [Color(0xFF0E1A2C), Color(0xFF15356B)],
    ),
    BannerItem(
      title: 'How to play games',
      image: AppConstants.bannerHowToPlay,
      route: '/match-rules',
      colors: [Color(0xFF2A2300), Color(0xFF161616)],
    ),
    BannerItem(
      title: 'Join our Telegram community',
      image: AppConstants.bannerJoinGroup,
      url: 'https://t.me/squadup',
      colors: [Color(0xFF0E1A2C), Color(0xFF15356B)],
    ),
  ];

  static const List<BannerItem> shopBanners = [
    BannerItem(
      title: 'Gaming Products',
      image: AppConstants.shopProductsBanner,
      route: '/products',
      colors: [Color(0xFF2A0A40), Color(0xFF120A26)],
    ),
    BannerItem(
      title: 'Top-Up Center',
      image: AppConstants.shopTopupBanner,
      colors: [Color(0xFF0E1A2C), Color(0xFF15356B)],
    ),
  ];

  /// Launch / bell notices (image-only swipeable popup). Each notice is a full
  /// promo image that links somewhere on tap. Set [image] to an asset path
  /// (add it to pubspec assets) or an https URL; set [route] for in-app
  /// navigation (e.g. `AppRoutes.ludo`) or [url] for an external link.
  static const List<NoticeItem> notices = [
    // Example: image links to the Free Fire screen.
    NoticeItem(
      image: AppConstants.freefireLogo,
      route: '/free-fire',
      colors: [Color(0xFF3A1A14), Color(0xFF131C2B)],
    ),
    // Example: image links to the Ludo screen.
    NoticeItem(
      image: AppConstants.logo,
      route: '/ludo',
      colors: [Color(0xFF15294D), Color(0xFF101826)],
    ),
    // Example: image links to an external URL (Telegram).
    NoticeItem(
      image: AppConstants.freefireLogo,
      url: 'https://t.me/squadup',
      colors: [Color(0xFF6D28D9), Color(0xFF2F6BFF)],
    ),
  ];

  /// Shop top-up categories: Free Fire diamonds & Ludo Kingpass coins/gems.
  static const List<TopupCategory> topupCategories = [
    TopupCategory(
      key: 'ff',
      title: 'Free Fire Topup',
      subtitle: 'Diamonds · Instant delivery',
      image: AppConstants.ffTopup,
      colors: [Color(0xFF15356B), Color(0xFF0E1A2C)],
      idLabel: 'Free Fire Player ID',
      packIcon: Icons.diamond_rounded,
      promo: '🔥 SPECIAL DISCOUNT TOP-UP 🔥',
      packs: [
        TopupPack(amount: '25', unit: 'Diamonds', price: 22, regularPrice: 25),
        TopupPack(amount: '50', unit: 'Diamonds', price: 40, regularPrice: 46),
        TopupPack(amount: '115', unit: 'Diamonds', price: 85, regularPrice: 95),
        TopupPack(
            amount: '240', unit: 'Diamonds', price: 170, regularPrice: 190),
        TopupPack(
            amount: '610', unit: 'Diamonds', price: 420, regularPrice: 470),
        TopupPack(
            amount: '1,240', unit: 'Diamonds', price: 820, regularPrice: 910),
      ],
      howTo: [
        HowToSection(
          title: 'How to top-up Free Fire Diamonds?',
          steps: [
            'Select a diamond pack.',
            'Enter your Free Fire Player ID.',
            'Choose your payment method & check out.',
            'Diamonds will be credited to your account shortly.',
          ],
        ),
        HowToSection(
          title: 'How to find your Player ID?',
          steps: [
            'Open Free Fire and tap your avatar / profile.',
            'Your Player ID is shown below your in-game name.',
            'Copy it and paste it here.',
          ],
        ),
      ],
      perks: [
        '⚡ Instant Delivery',
        '🔒 Safe & Secure',
        '💬 24/7 Support',
      ],
    ),
    TopupCategory(
      key: 'ludo_kingpass',
      title: 'Ludo Kingpass Topup',
      subtitle: 'Coins · Special discount',
      image: AppConstants.ludoKingpass,
      colors: [Color(0xFF7A1320), Color(0xFF2A0A10)],
      idLabel: 'Ludo King User ID',
      packIcon: Icons.monetization_on_rounded,
      promo: '🔥 SPECIAL DISCOUNT TOP-UP 🔥',
      perks: [
        '⚡ Instant Delivery',
        '🔒 Safe & Secure',
        '💬 24/7 Support',
        '🎁 Best Value Guaranteed',
      ],
      packs: [
        TopupPack(
            amount: '32,500', unit: 'Coins', price: 139, regularPrice: 159),
        TopupPack(
            amount: '130,000', unit: 'Coins', price: 249, regularPrice: 289),
        TopupPack(
            amount: '650,000', unit: 'Coins', price: 649, regularPrice: 749),
        TopupPack(
            amount: '1,300,000', unit: 'Coins', price: 929, regularPrice: 1049),
        TopupPack(
            amount: '6,500,000',
            unit: 'Coins',
            price: 2399,
            regularPrice: 2699),
        TopupPack(
            amount: '13,000,000',
            unit: 'Coins',
            price: 3999,
            regularPrice: 4499),
        TopupPack(
            amount: '65,000,000',
            unit: 'Coins',
            price: 11999,
            regularPrice: 13499),
        TopupPack(
            amount: '130,000,000',
            unit: 'Coins',
            price: 19299,
            regularPrice: 21999),
      ],
      guideImage: AppConstants.ludoUidGuide,
      howTo: [
        HowToSection(
          title: 'How to top-up Ludo King Coins or Gems?',
          steps: [
            'Select the Coins or Gems denomination.',
            'Enter your User ID.',
            'Check out and select your payment method.',
            'Once payment made, Ludo King Coins or Gems will be credited to your account shortly.',
          ],
        ),
        HowToSection(
          title: 'How to find Ludo King User ID?',
          steps: [
            'Log in to the game using your account.',
            'Tap for the "Avatar" icon. It\'s positioned at the Top-left corner of the game screen.',
            'Your Ludo King User ID will be displayed.',
          ],
        ),
      ],
    ),
  ];

  /// Gaming-store products (e-commerce section).
  static const List<Product> products = [
    Product(
      name: 'Fantech Crypto VX7 Gaming Mouse',
      icon: Icons.mouse,
      price: 1290,
      oldPrice: 1650,
      image: AppConstants.productMouseVx7,
      colors: ['Black', 'White'],
    ),
    Product(
      name: 'Razer Kraken X Gaming Headset',
      icon: Icons.headset_mic,
      price: 3200,
      oldPrice: 3900,
      image: AppConstants.productHeadsetKraken,
      colors: ['Black'],
    ),
    Product(
      name: 'Fantech Kanata VX9 Gaming Mouse',
      icon: Icons.mouse,
      price: 1150,
      oldPrice: 1450,
      image: AppConstants.productMouseVx9,
      colors: ['Black'],
    ),
    Product(
      name: 'Fantech Atom 63 Mechanical Keyboard',
      icon: Icons.keyboard,
      price: 4500,
      oldPrice: 5200,
      image: AppConstants.productKeyboardAtom63,
      colors: ['Blue', 'White'],
    ),
    Product(
      name: 'Fantech Shooter III Gamepad',
      icon: Icons.sports_esports,
      price: 3800,
      oldPrice: 4400,
      image: AppConstants.productGamepadShooter3,
      colors: ['Black', 'White'],
    ),
    Product(
        name: 'Gaming Headset',
        icon: Icons.headset_mic,
        price: 1450,
        oldPrice: 1800),
    Product(
        name: 'Mechanical Keyboard',
        icon: Icons.keyboard,
        price: 2900,
        oldPrice: 3500),
    Product(
        name: 'Gaming Mouse', icon: Icons.mouse, price: 950, oldPrice: 1200),
    Product(
        name: 'Controller',
        icon: Icons.sports_esports,
        price: 3200,
        oldPrice: 3800),
    Product(
        name: 'Gaming Chair',
        icon: Icons.chair_alt,
        price: 12500,
        oldPrice: 15000),
    Product(
        name: 'RGB Mouse Pad',
        icon: Icons.crop_landscape,
        price: 350,
        oldPrice: 450),
    Product(name: 'Streaming Webcam', icon: Icons.videocam, price: 2100),
    Product(
        name: 'Power Bank',
        icon: Icons.battery_charging_full,
        price: 1600,
        oldPrice: 1900),
  ];

  static const List<ShopFeature> shopFeatures = [
    ShopFeature(
        icon: Icons.lock_outline,
        title: 'Secure Payment',
        subtitle: 'Encrypted transactions for complete peace of mind.'),
    ShopFeature(
        icon: Icons.bolt_outlined,
        title: 'Fastest Deal',
        subtitle: 'Lightning fast delivery on all your purchases.'),
    ShopFeature(
        icon: Icons.headset_mic_outlined,
        title: '24/7 Support',
        subtitle: 'Our team is online all day to help instantly.'),
  ];

  static const List<PaymentChannel> withdrawChannels = [
    PaymentChannel(key: 'bkash', label: 'bKash', color: Color(0xFFE2136E)),
    PaymentChannel(key: 'nagad', label: 'Nagad', color: Color(0xFFEE6123)),
    PaymentChannel(key: 'rocket', label: 'Rocket', color: Color(0xFF8C3494)),
  ];

  /// Deposit (Add Money) channels — manual mobile wallets (send money to the
  /// listed number, then submit the TRX) plus an automated card/gateway.
  static const List<PaymentChannel> depositChannels = [
    PaymentChannel(
        key: 'bkash',
        label: 'bKash',
        color: Color(0xFFE2136E),
        number: '01710000001',
        accountType: 'Personal'),
    PaymentChannel(
        key: 'nagad',
        label: 'Nagad',
        color: Color(0xFFEE6123),
        number: '01810000002',
        accountType: 'Personal'),
    PaymentChannel(
        key: 'rocket',
        label: 'Rocket',
        color: Color(0xFF8C3494),
        number: '019100000033',
        accountType: 'Personal'),
    PaymentChannel(
        key: 'gateway', label: 'Card / Gateway', color: Color(0xFF2F6BFF)),
  ];

  /// Gaming-store courier charges. Divisions/districts are fetched live from the
  /// free BD geo API (see `BdLocationApi`).
  static const double deliveryInsideDhaka = 60;
  static const double deliveryOutsideDhaka = 120;

  static const double minWithdraw = 105;
  static const double maxWithdraw = 10000;
  static const String withdrawNotice =
      'সর্বনিম্ন উত্তোলন পরিমাণ ৳105 টাকা এবং সর্বোচ্চ উত্তোলন পরিমাণ ৳10000 টাকা।';

  /// Demo wallet transactions shown on the Transactions screen (mock backend).
  static final List<TransactionModel> demoTransactions = [
    TransactionModel(
      id: 1001,
      type: TxType.deposit,
      amount: 500,
      status: 'success',
      method: 'Gateway',
      date: DateTime.now().subtract(const Duration(hours: 5)),
      description: 'Wallet deposit',
    ),
    TransactionModel(
      id: 1002,
      type: TxType.join,
      amount: 10,
      status: 'success',
      method: 'System',
      date: DateTime.now().subtract(const Duration(hours: 4)),
      description: 'Joined BR Solo Time 👑',
    ),
    TransactionModel(
      id: 1003,
      type: TxType.prize,
      amount: 60,
      status: 'success',
      method: 'System',
      date: DateTime.now().subtract(const Duration(hours: 3)),
      description: 'Prize — BR Solo Time 👑',
    ),
    TransactionModel(
      id: 1004,
      type: TxType.deposit,
      amount: 200,
      status: 'success',
      method: 'bKash',
      date: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      description: 'Wallet deposit',
    ),
    TransactionModel(
      id: 1005,
      type: TxType.withdraw,
      amount: 105,
      status: 'pending',
      method: 'Nagad',
      date: DateTime.now().subtract(const Duration(days: 2)),
      description: 'Withdraw to Nagad',
    ),
  ];
}
