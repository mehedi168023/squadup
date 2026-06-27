import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// What was ordered — a shop top-up (diamonds/coins) or a physical product.
enum OrderKind { topup, product }

/// Lifecycle of an order, surfaced to the user for transparency/trust.
enum OrderStatus { processing, completed, delivered, cancelled }

/// A persisted record of something the user bought — the backbone of the
/// in-app Order History. Kept separate from [TransactionModel] (wallet money
/// flow) so purchases read as receipts: what, when, how paid, and where it
/// shipped.
class OrderModel {
  final String id; // e.g. SQ-482193 — shown on the receipt
  final OrderKind kind;
  final String title; // "115 Diamonds" / "Gaming Headset Kraken"
  final String subtitle; // short context line under the title
  final double amount; // total paid / payable
  final String method; // "SquadUp Wallet" | "Gateway" | "Cash on Delivery"
  final OrderStatus status;
  final DateTime date;
  final Map<String, String> details; // ordered receipt rows (label → value)

  const OrderModel({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.method,
    required this.status,
    required this.date,
    this.details = const {},
  });

  IconData get icon => switch (kind) {
        OrderKind.topup => Icons.diamond_rounded,
        OrderKind.product => Icons.shopping_bag_rounded,
      };

  Color get accent => switch (kind) {
        OrderKind.topup => AppColors.primary,
        OrderKind.product => AppColors.winningTeal,
      };

  String get kindLabel => switch (kind) {
        OrderKind.topup => 'Top-up',
        OrderKind.product => 'Product',
      };

  String get statusLabel => switch (status) {
        OrderStatus.processing => 'Processing',
        OrderStatus.completed => 'Completed',
        OrderStatus.delivered => 'Delivered',
        OrderStatus.cancelled => 'Cancelled',
      };

  Color get statusColor => switch (status) {
        OrderStatus.processing => AppColors.gold,
        OrderStatus.completed => AppColors.success,
        OrderStatus.delivered => AppColors.winningTeal,
        OrderStatus.cancelled => AppColors.danger,
      };
}
