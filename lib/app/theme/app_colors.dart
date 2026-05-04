import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── V3: NEUMORPHIC BLUE-GRAY PALETTE ─────────────────────────────────────

  // Backgrounds
  static const Color bg             = Color(0xFFE8ECF3);
  static const Color bg2            = Color(0xFFDFE4EE);
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F4FA);

  // Text
  static const Color text  = Color(0xFF1C2033);
  static const Color muted = Color(0xFF7B84A0);
  static const Color faint = Color(0xFFA8B0C8);

  // Borders
  static const Color border = Color(0xFFD4DBE8);

  // Único acento (electric blue)
  static const Color accent     = Color(0xFF2B4BFF);
  static const Color accentSoft = Color(0x142B4BFF);

  // Semantic (desaturados, silenciados)
  static const Color success     = Color(0xFF34C989);
  static const Color successSoft = Color(0x1234C989);
  static const Color warning     = Color(0xFFDC963C);
  static const Color warningSoft = Color(0x12DC963C);
  static const Color error       = Color(0xFFE05555);
  static const Color errorSoft   = Color(0x12E05555);

  // Shadows neumórficas
  static const Color shadowDark  = Color(0x8CAEB7CE);
  static const Color shadowLight = Color(0xE6FFFFFF);

  // ── BACKWARD COMPAT ALIASES ───────────────────────────────────────────────
  static const Color primary             = accent;
  static const Color primaryLight        = Color(0xFF5B75FF);
  static const Color primaryDark         = Color(0xFF1A2E99);
  static const Color primarySoft         = accentSoft;
  static const Color primaryBadge        = accentSoft;
  static const Color primaryContainer    = accentSoft;
  static const Color onPrimary           = Color(0xFFFFFFFF);
  static const Color textOnPrimary       = Color(0xFFFFFFFF);
  static const Color textPrimary         = text;
  static const Color textSecondary       = muted;
  static const Color textDisabled        = faint;
  static const Color background          = bg;
  static const Color outline             = border;
  static const Color divider             = Color(0xFFE8ECF3);
  static const Color shadow              = Color(0x0A1C2033);
  static const Color shadowTint          = Color(0x001C2033);
  static const Color secondary           = text;
  static const Color info                = accent;
  static const Color infoLight           = accentSoft;
  static const Color successLight        = successSoft;
  static const Color warningLight        = warningSoft;
  static const Color errorLight          = errorSoft;
  static const Color surfaceContainerLowest    = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow       = Color(0xFFF0F4FA);
  static const Color surfaceContainer          = Color(0xFFE4EBFA);
  static const Color surfaceContainerHigh      = surfaceVariant;
  static const Color surfaceContainerHighest   = Color(0xFFD4DBE8);

  // ── DARK MODE ─────────────────────────────────────────────────────────────
  static const Color darkBg             = Color(0xFF1C2033);
  static const Color darkSurface        = Color(0xFF252B40);
  static const Color darkSurfaceVariant = Color(0xFF2D3452);
  static const Color darkBorder         = Color(0xFF3D4566);
  static const Color darkDivider        = Color(0xFF2D3452);
  static const Color darkPrimary        = accent;
  static const Color darkTextPrimary    = Color(0xFFF0F2FA);
  static const Color darkTextSecondary  = Color(0xFFA8B0C8);
  static const Color darkTextDisabled   = Color(0xFF7B84A0);
}
