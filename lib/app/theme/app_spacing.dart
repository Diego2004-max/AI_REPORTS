import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 12.0;
  static const double lg   = 16.0;
  static const double xl   = 24.0;
  static const double xxl  = 32.0;
  static const double xxxl = 40.0;
  static const double huge = 56.0;

  static const double screenH = 24.0;
  static const double screenV = 20.0;

  static const double radiusXs   = 8.0;
  static const double radiusSm   = 12.0;
  static const double radiusMd   = 16.0;
  static const double radiusLg   = 24.0;
  static const double radiusXl   = 32.0;
  static const double radiusXxl  = 40.0;
  static const double radiusFull = 100.0;

  static const double elevationNone = 0;
  static const double elevationSm   = 1;
  static const double elevationMd   = 2;
  static const double elevationLg   = 4;

  static const double iconSm = 16.0;
  static const double iconMd = 20.0;
  static const double iconLg = 24.0;
  static const double iconXl = 32.0;

  static const double buttonHeight    = 56.0;
  static const double inputHeight     = 56.0;
  static const double appBarHeight    = 60.0;
  static const double bottomNavHeight = 72.0;
  static const double brandLogoSize   = 68.0;
  static const double avatarSm        = 32.0;
  static const double avatarMd        = 44.0;
  static const double avatarLg        = 72.0;
}

// ── V3: BORDER RADIUS ────────────────────────────────────────────────────────
class AppRadius {
  AppRadius._();

  static const Radius sm   = Radius.circular(12);
  static const Radius md   = Radius.circular(16);
  static const Radius lg   = Radius.circular(24);
  static const Radius xl   = Radius.circular(28);
  static const Radius xxl  = Radius.circular(32);
  static const Radius full = Radius.circular(9999);

  static const BorderRadius borderSm   = BorderRadius.all(sm);
  static const BorderRadius borderMd   = BorderRadius.all(md);
  static const BorderRadius borderLg   = BorderRadius.all(lg);
  static const BorderRadius borderXl   = BorderRadius.all(xl);
  static const BorderRadius borderXxl  = BorderRadius.all(xxl);
  static const BorderRadius borderFull = BorderRadius.all(full);
}

// ── V3: NEUMORPHIC SHADOWS ────────────────────────────────────────────────────
class AppShadows {
  AppShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x8CAEB7CE), blurRadius: 20, offset: Offset(8, 8)),
    BoxShadow(color: Color(0xE6FFFFFF), blurRadius: 20, offset: Offset(-8, -8)),
  ];

  static const List<BoxShadow> soft = [
    BoxShadow(color: Color(0x70AEB7CE), blurRadius: 14, offset: Offset(5, 5)),
    BoxShadow(color: Color(0xE6FFFFFF), blurRadius: 14, offset: Offset(-5, -5)),
  ];

  static const List<BoxShadow> float = [
    BoxShadow(color: Color(0x8CAEB7CE), blurRadius: 26, offset: Offset(10, 10)),
    BoxShadow(color: Color(0xE6FFFFFF), blurRadius: 26, offset: Offset(-10, -10)),
  ];

  static const List<BoxShadow> accentGlow = [
    BoxShadow(color: Color(0x402B4BFF), blurRadius: 18, offset: Offset(0, 6)),
  ];
}

// ── V3: COMPONENT SIZES ───────────────────────────────────────────────────────
class AppSizes {
  AppSizes._();

  static const double buttonHeight    = 52.0;
  static const double inputHeight     = 52.0;
  static const double appBarHeight    = 60.0;
  static const double bottomNavHeight = 64.0;
  static const double fab             = 46.0;
  static const double brandMark       = 64.0;
}
