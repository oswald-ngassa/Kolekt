import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette calquée sur les maquettes "nOVa".
/// Champs mutables (pas const) : AppTheme.build() les réécrit selon le mode
/// clair/sombre choisi, et tous les écrans les lisent directement.
class AppColors {
  static Color background = const Color(0xFF0E0E0E);
  static Color card = const Color(0xFF1C1C1C);
  static Color inputBg = const Color(0xFF1A1A1A);
  static Color inputBorder = const Color(0xFF3A3A3A);
  static const primaryColor = Color(0xFF4E8FF0); // bleu principal des boutons
  static const accentColor = Color(0xFF2F6FE0); // bleu du logo
  static const error = Color(0xFFE05B5B);
  static Color errorBg = const Color(0xFF3A1F1F);
  static Color textPrimary = Colors.white;
  static const textSecondary = Color(0xFFB0B0B0);
}

class AppTheme {
  /// Construit le ThemeData pour le mode demandé ET met à jour AppColors en
  /// conséquence (tous les écrans lisent AppColors directement, pas Theme.of).
  static ThemeData build(ThemeMode mode) {
    if (mode == ThemeMode.light) {
      AppColors.background = const Color(0xFFF5F6F8);
      AppColors.card = Colors.white;
      AppColors.inputBg = const Color(0xFFEFF1F4);
      AppColors.inputBorder = const Color(0xFFDADFE5);
      AppColors.errorBg = const Color(0xFFFBEAEA);
      AppColors.textPrimary = const Color(0xFF14161A);
      return _themeFrom(ThemeData.light(useMaterial3: true));
    }
    AppColors.background = const Color(0xFF0E0E0E);
    AppColors.card = const Color(0xFF1C1C1C);
    AppColors.inputBg = const Color(0xFF1A1A1A);
    AppColors.inputBorder = const Color(0xFF3A3A3A);
    AppColors.errorBg = const Color(0xFF3A1F1F);
    AppColors.textPrimary = Colors.white;
    return _themeFrom(ThemeData.dark(useMaterial3: true));
  }

  static ThemeData get dark => build(ThemeMode.dark);

  static ThemeData _themeFrom(ThemeData base) {
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primaryColor,
        surface: AppColors.card,
        error: AppColors.error,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.black,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBg,
        hintStyle: TextStyle(color: AppColors.textSecondary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primaryColor),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primaryColor
              : AppColors.textSecondary,
        ),
      ),
    );
  }
}
