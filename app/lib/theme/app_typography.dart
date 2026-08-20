import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Text style tokens built on the two Figma type families:
/// Quicksand for headings, Plus Jakarta Sans for body/labels/buttons.
class AppTypography {
  AppTypography._();

  static TextStyle heading1 = GoogleFonts.quicksand(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 36 / 28,
    color: AppColors.deepPurple,
  );

  static TextStyle heading2 = GoogleFonts.quicksand(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 32 / 24,
    color: AppColors.deepPurple,
  );

  static TextStyle heading2SemiBold = GoogleFonts.quicksand(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
    color: AppColors.headingText,
  );

  static TextStyle heading3 = GoogleFonts.quicksand(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
    color: AppColors.headingText,
  );

  static TextStyle heading4 = GoogleFonts.quicksand(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
    color: AppColors.headingText,
  );

  static TextStyle displayXl = GoogleFonts.quicksand(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 40 / 32,
    color: AppColors.deepPurple,
  );

  static TextStyle bodyLarge = GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 28 / 18,
    color: AppColors.bodyText,
  );

  static TextStyle body = GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    color: AppColors.bodyText,
  );

  static TextStyle cardTitle = GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 28 / 18,
    color: AppColors.headingText,
  );

  static TextStyle label = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 20 / 14,
    letterSpacing: 0.14,
    color: AppColors.headingText,
  );

  static TextStyle labelSmall = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
    color: AppColors.bodyText,
  );

  static TextStyle button = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 20 / 14,
    letterSpacing: 0.14,
    color: Colors.white,
  );

  static TextStyle buttonBold = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 20 / 14,
    letterSpacing: 0.14,
    color: Colors.white,
  );

  static TextStyle overline = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 20 / 14,
    letterSpacing: 0.7,
    color: AppColors.headingText,
  );
}
