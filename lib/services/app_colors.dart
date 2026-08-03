import 'package:flutter/material.dart';

/// Centralized theme-aware color helper for Premium 2.0 design system.
/// All screens should use `AppColors.of(context)` to get theme-aware colors.
class AppColors {
  final Brightness brightness;

  AppColors._(this.brightness);

  factory AppColors.of(BuildContext context) {
    return AppColors._(Theme.of(context).brightness);
  }

  bool get isDark => brightness == Brightness.dark;

  // --- Core Brand ---
  Color get primaryDarkGreen =>
      isDark ? const Color(0xFF4CAF7D) : const Color(0xFF003527);
  Color get primaryGreen =>
      isDark ? const Color(0xFF2D5A3F) : const Color(0xFF2D5A3F);
  Color get goldAccent => const Color(0xFFC5A059);

  // --- Quran Reader Palette ---
  static const Color quranGold = Color(0xFFC5A059);
  static const Color quranMutedGold = Color(0xFF8C733E);
  static const Color quranBgLight = Color(0xFFFFFDF7);
  static const Color quranTextDark = Color(0xFF2C2C2C);

  // --- Backgrounds ---
  Color get scaffoldBg =>
      isDark ? const Color(0xFF000000) : const Color(0xFFF8FAF9);
  Color get scaffoldBgAlt =>
      isDark ? const Color(0xFF000000) : const Color(0xFFF2F8F5);

  // --- Cards & Surfaces ---
  Color get cardBg =>
      isDark ? const Color(0xFF1A2E25) : const Color(0xFFFFFFFF);
  Color get cardBgElevated =>
      isDark ? const Color(0xFF223D32) : const Color(0xFFFFFFFF);
  Color get mutedBg =>
      isDark ? const Color(0xFF1A2E25) : const Color(0xFFECEEED);

  // --- Borders ---
  Color get borderColor =>
      isDark ? const Color(0xFF2A4A3A) : const Color(0xFFE1E3E2);

  // --- Text ---
  Color get textPrimary =>
      isDark ? const Color(0xFFF0F0F0) : const Color(0xFF003527);
  Color get textSecondary => isDark ? Colors.grey[300]! : Colors.grey[800]!;
  Color get textMuted => isDark ? Colors.grey[400]! : Colors.grey[600]!;
  Color get textSubtle => isDark ? Colors.grey[500]! : Colors.grey[500]!;

  // --- Overlays & Shadows ---
  Color get shadowColor => isDark
      ? Colors.black.withValues(alpha: 0.3)
      : Colors.black.withValues(alpha: 0.03);
  Color get overlayColor => isDark
      ? Colors.black.withValues(alpha: 0.5)
      : Colors.black.withValues(alpha: 0.4);
  Color get glassBarBg => isDark
      ? const Color(0xFF0D1B16).withValues(alpha: 0.85)
      : const Color(0xFFF8FAF9).withValues(alpha: 0.7);

  // --- Interactive ---
  Color get switchActiveThumb => goldAccent;
  Color get switchActiveTrack => goldAccent.withValues(alpha: 0.3);
  Color get switchInactiveThumb =>
      isDark ? Colors.grey[600]! : Colors.grey[400]!;
  Color get switchInactiveTrack =>
      isDark ? Colors.grey[800]! : Colors.grey[200]!;

  // --- Hero Card ---
  Color get heroBgStart =>
      isDark ? const Color(0xFF0A2E1E) : const Color(0xFF003527);
  Color get heroBgEnd =>
      isDark ? const Color(0xFF1A4A35) : const Color(0xFF2D5A3F);

  // --- Friday Hub & Response Card ---
  Color get responseCardBg => isDark
      ? const Color(0xFF1E293B).withValues(alpha: 0.5)
      : const Color(0xFFF0FDF4);
  Color get responseCardBorder => isDark
      ? const Color(0xFF10B981).withValues(alpha: 0.35)
      : const Color(0xFF10B981).withValues(alpha: 0.35);
  Color get responseCardText => const Color(0xFF10B981);

  // --- Adhan Banner ---
  Color get adhanBannerBgStart =>
      isDark ? const Color(0xFF0A3A2A) : const Color(0xFF0D4735);
  Color get adhanBannerBgEnd =>
      isDark ? const Color(0xFF051C14) : const Color(0xFF052B1E);

  // --- Sunnah Shelf ---
  Color get sunnahShelfWood =>
      isDark ? const Color(0xFF4A342E) : const Color(0xFF8D6E63);

  // --- Bottom Nav ---
  Color get bottomNavBg => isDark ? const Color(0xFF0D1B16) : Colors.white;
  Color get bottomNavActive =>
      isDark ? const Color(0xFF4CAF7D) : const Color(0xFF003527);
  Color get bottomNavInactive => isDark ? Colors.grey[600]! : Colors.grey[400]!;

  // --- Danger Zone ---
  Color get dangerBg => isDark
      ? Colors.red.withValues(alpha: 0.1)
      : Colors.red.withValues(alpha: 0.05);
  Color get dangerBorder => isDark
      ? Colors.red.withValues(alpha: 0.3)
      : Colors.red.withValues(alpha: 0.2);
  Color get dangerText => isDark ? Colors.red[400]! : Colors.red[700]!;

  // --- SnackBar ---
  Color get snackBarBg =>
      isDark ? const Color(0xFF1A2E25) : const Color(0xFF2D5A3F);
}
