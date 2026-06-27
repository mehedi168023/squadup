import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Material 3 dark + light themes.
class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ).copyWith(
      surface: AppColors.bg,
      primary: AppColors.primary,
      secondary: AppColors.winningTeal,
      error: AppColors.danger,
    );
    return _build(
      scheme: base,
      scaffold: AppColors.bg,
      card: AppColors.surface,
      border: AppColors.border,
      textPrimary: AppColors.textPrimary,
      textSecondary: AppColors.textSecondary,
    );
  }

  static ThemeData get light {
    final base = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      surface: AppColors.lightBg,
      primary: AppColors.primary,
      secondary: AppColors.successDeep,
      error: AppColors.danger,
    );
    return _build(
      scheme: base,
      scaffold: AppColors.lightBg,
      card: AppColors.lightSurface,
      border: AppColors.lightBorder,
      textPrimary: AppColors.lightTextPrimary,
      textSecondary: AppColors.lightTextSecondary,
    );
  }

  static ThemeData _build({
    required ColorScheme scheme,
    required Color scaffold,
    required Color card,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      visualDensity: VisualDensity.compact,
      fontFamily: AppTextStyles.body,
      cardColor: card,
      dividerColor: border,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: AppTextStyles.h3.copyWith(color: textPrimary),
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.h1.copyWith(color: textPrimary),
        headlineMedium: AppTextStyles.h2.copyWith(color: textPrimary),
        titleLarge: AppTextStyles.title.copyWith(color: textPrimary),
        bodyLarge: AppTextStyles.body1.copyWith(color: textPrimary),
        bodyMedium: AppTextStyles.body2.copyWith(color: textSecondary),
        labelLarge: AppTextStyles.label.copyWith(color: textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        hintStyle:
            AppTextStyles.body1.copyWith(color: textSecondary, fontSize: 14),
        // Floating label: rests inside as a placeholder, animates onto the
        // outline when focused/filled.
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle:
            AppTextStyles.body1.copyWith(color: textSecondary, fontSize: 15),
        floatingLabelStyle: AppTextStyles.title
            .copyWith(color: AppColors.primary, fontSize: 13.5),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
      splashColor: AppColors.primarySoft,
    );
  }
}
