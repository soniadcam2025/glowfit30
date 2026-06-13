import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

const Color _highlightColor = Color(0xFFFF146B);

class AppTypography {
  AppTypography._();

  // Display Styles (Large headlines)
  static TextStyle displayLarge() => GoogleFonts.poppins(
    fontSize: 48,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: -0.5,
  );

  static TextStyle displayMedium() => GoogleFonts.poppins(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.3,
  );

  // Headline Styles
  static TextStyle headlineXL() => GoogleFonts.poppins(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.3,
  );

  static TextStyle headlineLarge() => GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.2,
  );

  static TextStyle headlineMedium() => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );

  static TextStyle headlineSmall() => GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  // Title Styles
  static TextStyle titleLarge() => GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static TextStyle titleMedium() => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static TextStyle titleSmall() => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.43,
  );

  // Body Styles
  static TextStyle bodyLarge() => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle bodyMedium() => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.57,
  );

  static TextStyle bodySmall() => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.67,
  );

  // Label Styles
  static TextStyle labelLarge() => GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  static TextStyle labelMedium() => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.43,
  );

  static TextStyle labelSmall() => GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.45,
  );

  // Button Style
  static TextStyle button() => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // Caption Style
  static TextStyle caption() => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.33,
  );

  // ── Onboarding screen title styles ──────────────────────────────────────
  // Base: Poppins 32 medium, dark text
  static TextStyle onboardingTitle() => GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  // Highlight: Poppins 32 bold, brand pink
  static TextStyle onboardingHighlight() => GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: _highlightColor,
    height: 1.2,
  );

  // Card title: Poppins semibold 18, black — used inside selection cards
  static TextStyle cardTitle() => GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );

  // Card subtitle: Poppins medium 14, #707070 — used under card titles
  static TextStyle cardSubtitle() => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: const Color(0xFF707070),
  );

  // Subtitle: Poppins medium 16, #504F4F — used under screen titles
  static TextStyle onboardingSubtitle() => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: const Color(0xFF504F4F),
  );

  /// Builds the two-tone onboarding title used across all onboarding screens.
  ///
  /// [prefix]         — normal weight text before the highlight
  /// [highlight]      — bold pink text (#FF146B)
  /// [suffix]         — normal weight text after the highlight
  /// [inlineTrailing] — widget shown inline right after the highlight (e.g. an icon)
  static Widget screenTitle({
    String prefix = '',
    required String highlight,
    String suffix = '',
    Widget? inlineTrailing,
  }) {
    return RichText(
      text: TextSpan(
        style: onboardingTitle(),
        children: [
          if (prefix.isNotEmpty) TextSpan(text: prefix),
          TextSpan(
            text: highlight,
            style: onboardingHighlight().copyWith(
              fontFamily: GoogleFonts.poppins().fontFamily,
            ),
          ),
          if (inlineTrailing != null)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: inlineTrailing,
              ),
            ),
          if (suffix.isNotEmpty) TextSpan(text: suffix),
        ],
      ),
    );
  }

}
