import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_constants.dart';

/// Production-grade form validators — one source of truth for the rules behind
/// every input (email, phone, password, name, amount, TRX). Each returns `null`
/// when valid or a short, user-facing error string otherwise, so they drop
/// straight into `TextFormField.validator`.
class Validators {
  Validators._();

  // Standard email shape (covers Gmail and any provider).
  static final RegExp _email =
      RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,}$');
  // Bangladesh mobile: 11 digits, 01, operator prefix 3–9.
  static final RegExp _bdPhone = RegExp(r'^01[3-9]\d{8}$');

  static String? required(String? v, {String field = 'This field'}) {
    if (v == null || v.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? email(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Email is required';
    if (s.contains(' ')) return 'Email cannot contain spaces';
    if (!_email.hasMatch(s)) return 'Enter a valid email address';
    return null;
  }

  static String? phone(String? v) {
    final s = (v ?? '').replaceAll(RegExp(r'[\s-]'), '');
    if (s.isEmpty) return 'Phone number is required';
    if (!RegExp(r'^\d+$').hasMatch(s)) return 'Digits only';
    if (!_bdPhone.hasMatch(s)) {
      return 'Enter a valid 11-digit number (01XXXXXXXXX)';
    }
    return null;
  }

  /// Login/register identifier — accepts a phone OR an email.
  static String? identifier(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Phone or email is required';
    if (s.contains('@')) return email(s);
    if (RegExp(r'^\d').hasMatch(s)) return phone(s);
    return 'Enter a valid phone or email';
  }

  /// Strong password: 8+ chars with at least one letter and one number.
  static String? password(String? v) {
    final s = v ?? '';
    if (s.isEmpty) return 'Password is required';
    if (s.length < 8) return 'At least 8 characters';
    if (!RegExp(r'[A-Za-z]').hasMatch(s)) return 'Add at least one letter';
    if (!RegExp(r'\d').hasMatch(s)) return 'Add at least one number';
    return null;
  }

  /// Login password — just required (existing accounts may predate the policy).
  static String? loginPassword(String? v) {
    if ((v ?? '').isEmpty) return 'Password is required';
    return null;
  }

  static String? confirmPassword(String? v, String original) {
    if ((v ?? '').isEmpty) return 'Confirm your password';
    if (v != original) return 'Passwords do not match';
    return null;
  }

  static String? name(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Name is required';
    if (s.length < 2) return 'Name is too short';
    if (!RegExp(r"^[A-Za-z .'-]+$").hasMatch(s)) {
      return 'Letters only (no digits or symbols)';
    }
    return null;
  }

  static String? amount(String? v, {double min = 0, double? max}) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Amount is required';
    final n = double.tryParse(s);
    if (n == null) return 'Enter a valid amount';
    if (n <= 0) return 'Amount must be greater than 0';
    if (n < min) return 'Minimum is ${taka(min)}';
    if (max != null && n > max) return 'Maximum is ${taka(max)}';
    return null;
  }

  static String? trxId(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Transaction ID is required';
    if (s.length < 4) return 'Enter a valid Transaction ID';
    return null;
  }

  /// Password strength → (0..1 score, label, colour) for a live meter.
  static PasswordStrength strength(String s) {
    if (s.isEmpty) return const PasswordStrength(0, '', AppColors.textMuted);
    var score = 0;
    if (s.length >= 8) score++;
    if (s.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(s) && RegExp(r'[a-z]').hasMatch(s)) score++;
    if (RegExp(r'\d').hasMatch(s)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(s)) score++;
    if (score <= 1) {
      return const PasswordStrength(0.25, 'Weak', AppColors.danger);
    }
    if (score == 2) {
      return const PasswordStrength(0.5, 'Fair', AppColors.gold);
    }
    if (score == 3) {
      return const PasswordStrength(0.75, 'Good', AppColors.primary);
    }
    return const PasswordStrength(1, 'Strong', AppColors.winningTeal);
  }
}

class PasswordStrength {
  final double score; // 0..1
  final String label;
  final Color color;
  const PasswordStrength(this.score, this.label, this.color);
}
