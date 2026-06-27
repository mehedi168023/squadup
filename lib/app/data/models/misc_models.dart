import 'package:flutter/material.dart';

/// Leaderboard entry — mirrors `/api/leaderboard`.
class LeaderboardEntry {
  final int rank;
  final String name;
  final double wonAmount;

  const LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.wonAmount,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) => LeaderboardEntry(
        rank: (j['rank'] ?? 0) as int,
        name: (j['name'] ?? '').toString(),
        wonAmount: (j['won_amount'] ?? 0).toDouble(),
      );
}

/// A promo banner in the Home/Shop carousels. Renders [image] when provided
/// (an asset path), otherwise falls back to the [colors] gradient. Tapping the
/// banner opens [url] (Telegram / YouTube / any social link). [title] is kept
/// only as an accessibility label — it is never drawn over the banner.
class BannerItem {
  final String title;
  final List<Color> colors;
  final String url; // external link (used when [route] is null)
  final String? route; // internal app route (AppRoutes.*)
  final String? image; // asset path / URL shown full-bleed
  const BannerItem({
    required this.title,
    required this.colors,
    this.url = '',
    this.route,
    this.image,
  });
}

/// A "Why Choose Us?" feature row on the Shop tab.
class ShopFeature {
  final IconData icon;
  final String title;
  final String subtitle;
  const ShopFeature({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

/// A notice shown in the launch popup / bell carousel. Image-only: the whole
/// card is the [image] (asset path or http/https URL). Tapping it navigates to
/// an internal [route] (an `AppRoutes.*` name) or opens an external [url].
class NoticeItem {
  final String image; // asset path or http(s) URL, shown full-bleed
  final String? route; // internal app route, e.g. AppRoutes.ludo
  final String? url; // external link (used when [route] is null)
  final List<Color> colors; // fallback gradient while loading / on error

  const NoticeItem({
    required this.image,
    this.route,
    this.url,
    this.colors = const [Color(0xFF1E3A8A), Color(0xFF0E1A2C)],
  });
}

/// A purchasable top-up pack (diamonds / coins / gems).
class TopupPack {
  final String amount; // e.g. "32,500"
  final String unit; // e.g. "Coins" / "Diamonds"
  final double price; // discount / current price
  final double regularPrice; // struck-through original price
  const TopupPack({
    required this.amount,
    required this.unit,
    required this.price,
    required this.regularPrice,
  });

  double get save => (regularPrice - price).clamp(0, double.infinity);
}

/// A gaming-store product (e-commerce section). Renders [image] (an asset path)
/// when provided, otherwise falls back to the [icon] glyph.
class Product {
  final String name;
  final IconData icon;
  final double price;
  final double? oldPrice;
  final String? image; // asset path; takes priority over [icon] when set
  final List<String> colors; // selectable colour options on the buy screen
  const Product({
    required this.name,
    required this.icon,
    required this.price,
    this.oldPrice,
    this.image,
    this.colors = const ['Black'],
  });
}

/// A "How to ..." help section in the top-up screen.
class HowToSection {
  final String title;
  final List<String> steps;
  const HowToSection({required this.title, required this.steps});
}

/// A Shop top-up category (Free Fire diamonds / Ludo Kingpass coins).
class TopupCategory {
  final String key;
  final String title;
  final String subtitle;
  final String image; // logo / banner asset
  final List<Color> colors; // card gradient
  final String idLabel; // "Player ID" / "Ludo King User ID"
  final List<TopupPack> packs;
  final List<HowToSection> howTo;
  final String? guideImage; // optional help image (e.g. where to find UID)
  final IconData packIcon; // per-pack glyph (diamond / coin)
  final String? promo; // optional highlight banner above the packs
  final List<String> perks; // footer trust badges

  const TopupCategory({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.colors,
    required this.idLabel,
    required this.packs,
    required this.howTo,
    this.guideImage,
    this.packIcon = Icons.diamond_outlined,
    this.promo,
    this.perks = const [],
  });
}

/// Withdraw payment channel (bKash / Nagad).
class PaymentChannel {
  final String key;
  final String label;
  final Color color;
  final String? number; // receive number for manual deposits
  final String? accountType; // 'Personal' | 'Agent'
  const PaymentChannel({
    required this.key,
    required this.label,
    required this.color,
    this.number,
    this.accountType,
  });

  bool get isManual => number != null && number!.isNotEmpty;
}
