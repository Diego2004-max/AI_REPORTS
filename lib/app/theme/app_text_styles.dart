import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  // ── DISPLAY — Playfair Display (serif, italic) ─────────────────────────────
  static final TextStyle display1 = GoogleFonts.playfairDisplay(
    fontSize: 42, fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic, color: AppColors.text, height: 1.0,
  );
  static final TextStyle display2 = GoogleFonts.playfairDisplay(
    fontSize: 32, fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic, color: AppColors.text, height: 1.1,
  );
  static final TextStyle headline = GoogleFonts.playfairDisplay(
    fontSize: 24, fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic, color: AppColors.text, height: 1.2,
  );
  static final TextStyle titleDisplay = GoogleFonts.playfairDisplay(
    fontSize: 22, fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic, color: AppColors.text, height: 1.2,
  );

  // ── BODY — DM Sans (ultralight) ───────────────────────────────────────────
  static final TextStyle titleMd = GoogleFonts.dmSans(
    fontSize: 15, fontWeight: FontWeight.w400,
    color: AppColors.text, height: 1.35,
  );
  static final TextStyle bodyLg = GoogleFonts.dmSans(
    fontSize: 15, fontWeight: FontWeight.w300,
    color: AppColors.text, height: 1.6,
  );
  static final TextStyle bodyMd = GoogleFonts.dmSans(
    fontSize: 13, fontWeight: FontWeight.w300,
    color: AppColors.text, height: 1.6,
  );
  static final TextStyle bodySm = GoogleFonts.dmSans(
    fontSize: 12, fontWeight: FontWeight.w300,
    color: AppColors.muted, height: 1.55,
  );
  static final TextStyle labelLg = GoogleFonts.dmSans(
    fontSize: 13, fontWeight: FontWeight.w400,
    color: AppColors.text, letterSpacing: 0.2,
  );
  static final TextStyle labelMd = GoogleFonts.dmSans(
    fontSize: 11, fontWeight: FontWeight.w300,
    color: AppColors.muted, letterSpacing: 0.5,
  );
  static final TextStyle labelSm = GoogleFonts.dmSans(
    fontSize: 10, fontWeight: FontWeight.w300,
    color: AppColors.faint, letterSpacing: 0.3,
  );
  static final TextStyle caption = GoogleFonts.dmSans(
    fontSize: 11, fontWeight: FontWeight.w300,
    color: AppColors.faint, letterSpacing: 0.5, height: 1.4,
  );
  static final TextStyle overline = GoogleFonts.dmSans(
    fontSize: 10, fontWeight: FontWeight.w300,
    color: AppColors.faint, letterSpacing: 0.8,
  );
}
