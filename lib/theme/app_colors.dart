import 'package:flutter/material.dart';

/// Centralized color system for CekLabel.
///
/// Every color used in the app should be accessed through this class so that
/// dark ↔ light mode switching works automatically.  Widgets call
/// `AppColors.scaffold(context)` (etc.) and get the correct variant based on
/// the current brightness.
class AppColors {
  AppColors._();

  // ── helpers ────────────────────────────────────────────────────────────────
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // ── brand / accent (same in both modes) ────────────────────────────────────
  static const primary = Color(0xFF4ECDC4);
  static const primaryDark = Color(0xFF44A08D);
  static const error = Color(0xFFFF6B6B);
  static const errorDark = Color(0xFFE63E11);
  static const gold = Color(0xFFFFAD00);
  static const purple = Color(0xFF9B59B6);
  static const purpleAccent = Color(0xFFAD7BFF);

  // ── scaffold / page background ─────────────────────────────────────────────
  static Color scaffold(BuildContext context) =>
      isDark(context) ? const Color(0xFF0A0A0F) : const Color(0xFFF2F4F7);

  // ── surface (cards, raised containers) ─────────────────────────────────────
  static Color surface(BuildContext context) =>
      isDark(context) ? const Color(0xFF1A1A2E) : Colors.white;

  // ── bottom sheet / modal ───────────────────────────────────────────────────
  static Color bottomSheet(BuildContext context) =>
      isDark(context) ? const Color(0xFF12121F) : Colors.white;

  // ── nav bar ────────────────────────────────────────────────────────────────
  static Color navBarBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF0D0D1A) : Colors.white;

  static Color navBarBorder(BuildContext context) =>
      isDark(context)
          ? Colors.white.withValues(alpha: 0.07)
          : Colors.black.withValues(alpha: 0.08);

  // ── app bar ────────────────────────────────────────────────────────────────
  static Color appBar(BuildContext context) =>
      isDark(context) ? const Color(0xFF0A0A0F) : Colors.white;

  static Color appBarForeground(BuildContext context) =>
      isDark(context) ? Colors.white : const Color(0xFF1A1A2E);

  // ── card ───────────────────────────────────────────────────────────────────
  static Color cardBg(BuildContext context) =>
      isDark(context)
          ? Colors.white.withValues(alpha: 0.04)
          : const Color(0xFFF5F7FA);

  static Color cardBorder(BuildContext context) =>
      isDark(context)
          ? Colors.white.withValues(alpha: 0.07)
          : Colors.black.withValues(alpha: 0.07);

  // ── text ───────────────────────────────────────────────────────────────────
  static Color textPrimary(BuildContext context) =>
      isDark(context) ? Colors.white : const Color(0xFF1A1A2E);

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? Colors.white54 : const Color(0xFF5A5A6E);

  static Color textTertiary(BuildContext context) =>
      isDark(context) ? Colors.white38 : const Color(0xFF8A8A9E);

  static Color textQuaternary(BuildContext context) =>
      isDark(context) ? Colors.white24 : const Color(0xFFB0B0C0);

  static Color textOnPrimary(BuildContext context) =>
      isDark(context) ? Colors.white : Colors.white;

  // ── text on surface (for paragraphs / body text) ───────────────────────────
  static Color textBody(BuildContext context) =>
      isDark(context) ? Colors.white70 : const Color(0xFF3A3A4E);

  // ── input fields ───────────────────────────────────────────────────────────
  static Color inputFill(BuildContext context) =>
      isDark(context)
          ? Colors.white.withValues(alpha: 0.06)
          : const Color(0xFFF0F2F5);

  static Color inputBorder(BuildContext context) =>
      isDark(context)
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.black.withValues(alpha: 0.1);

  // ── icon (inactive) ────────────────────────────────────────────────────────
  static Color iconInactive(BuildContext context) =>
      isDark(context) ? Colors.white38 : const Color(0xFF8A8A9E);

  static Color iconDefault(BuildContext context) =>
      isDark(context) ? Colors.white : const Color(0xFF1A1A2E);

  // ── divider ────────────────────────────────────────────────────────────────
  static Color divider(BuildContext context) =>
      isDark(context) ? Colors.white12 : Colors.black12;

  // ── overlay (camera screen, modal backdrop) ────────────────────────────────
  static Color overlayLight(BuildContext context) =>
      isDark(context)
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.03);

  static Color overlayMedium(BuildContext context) =>
      isDark(context)
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.04);

  // ── gradient backgrounds (intake summary, etc.) ────────────────────────────
  static List<Color> intakeGradient(BuildContext context) =>
      isDark(context)
          ? const [Color(0xFF0D2B2B), Color(0xFF12121F)]
          : const [Color(0xFFE8F8F5), Color(0xFFF0F2F5)];

  // ── user chat bubble ───────────────────────────────────────────────────────
  static Color userBubble(BuildContext context) =>
      isDark(context) ? const Color(0xFF1A3A3A) : const Color(0xFFE0F5F3);

  // ── switch / toggle inactive ───────────────────────────────────────────────
  static Color switchInactiveThumb(BuildContext context) =>
      isDark(context) ? Colors.white38 : Colors.grey;

  static Color switchInactiveTrack(BuildContext context) =>
      isDark(context) ? Colors.white12 : Colors.grey.shade300;

  // ── dropdown ───────────────────────────────────────────────────────────────
  static Color dropdownBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF1A1A2E) : Colors.white;

  // ── popup menu ─────────────────────────────────────────────────────────────
  static Color popupMenuBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF1A1A2E) : Colors.white;

  // ── disabled button ────────────────────────────────────────────────────────
  static Color disabledBg(BuildContext context) =>
      isDark(context) ? Colors.white12 : Colors.grey.shade200;

  static Color disabledFg(BuildContext context) =>
      isDark(context) ? Colors.white38 : Colors.grey;

  // ── loading indicator background ───────────────────────────────────────────
  static Color loadingOverlay(BuildContext context) =>
      isDark(context)
          ? Colors.black.withValues(alpha: 0.7)
          : Colors.black.withValues(alpha: 0.4);

  // ── shimmer / skeleton ─────────────────────────────────────────────────────
  static Color shimmerBase(BuildContext context) =>
      isDark(context)
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.grey.shade200;

  // ── back button / subtle containers on camera screens ──────────────────────
  /// Transparent-ish chip background used *on top of camera* – always dark
  static Color cameraOverlayBg = Colors.black.withValues(alpha: 0.35);
  static Color cameraOverlayBorder = Colors.white.withValues(alpha: 0.12);

  // ── special: alert dialog ──────────────────────────────────────────────────
  static Color dialogBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF1A1A2E) : Colors.white;

  static Color dialogText(BuildContext context) =>
      isDark(context) ? Colors.white : const Color(0xFF1A1A2E);
}
