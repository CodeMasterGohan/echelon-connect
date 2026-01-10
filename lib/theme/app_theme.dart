/// App Theme - Modern dark theme with vibrant accents
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App color palette
class AppColors {
  // Primary colors - Deep dark theme
  static const Color background = Color(0xFF0D0D1A);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color surfaceLight = Color(0xFF252542);
  static const Color surfaceBorder = Color(0xFF3A3A5C);

  // Accent colors
  static const Color accent = Color(0xFF00D4FF);
  static const Color accentGlow = Color(0x4000D4FF);
  static const Color secondary = Color(0xFF7B61FF);
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFAB00);
  static const Color error = Color(0xFFFF5252);

  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0C0);
  static const Color textMuted = Color(0xFF6A6A8A);

  // Power zone colors
  static const Color zoneRecovery = Color(0xFF4CAF50);
  static const Color zoneEndurance = Color(0xFF8BC34A);
  static const Color zoneTempo = Color(0xFFFFEB3B);
  static const Color zoneThreshold = Color(0xFFFF9800);
  static const Color zoneVO2Max = Color(0xFFF44336);
  static const Color zoneAnaerobic = Color(0xFF9C27B0);

  // Heart rate zone colors
  static const List<Color> heartRateZones = [
    Color(0xFF64B5F6), // Zone 1 - Light
    Color(0xFF81C784), // Zone 2 - Moderate
    Color(0xFFFFD54F), // Zone 3 - Vigorous
    Color(0xFFFF8A65), // Zone 4 - Hard
    Color(0xFFE57373), // Zone 5 - Maximum
  ];

  /// Get power zone color based on FTP percentage
  static Color getPowerZoneColor(int watts, int ftp) {
    if (ftp <= 0) return accent;
    final pct = (watts / ftp * 100).round();
    
    if (pct < 56) return zoneRecovery;
    if (pct < 76) return zoneEndurance;
    if (pct < 91) return zoneTempo;
    if (pct < 106) return zoneThreshold;
    if (pct < 121) return zoneVO2Max;
    return zoneAnaerobic;
  }

  /// Get heart rate zone color
  static Color getHeartRateZoneColor(int hr, int maxHr) {
    if (maxHr <= 0) return accent;
    final pct = (hr / maxHr * 100).round();

    if (pct < 60) return heartRateZones[0];
    if (pct < 70) return heartRateZones[1];
    if (pct < 80) return heartRateZones[2];
    if (pct < 90) return heartRateZones[3];
    return heartRateZones[4];
  }
}

/// Light mode color palette
class AppColorsLight {
  // Primary colors - Clean light theme
  static const Color background = Color(0xFFF8F9FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF0F2F5);
  static const Color surfaceBorder = Color(0xFFE0E4EB);

  // Accent colors (slightly adjusted for light mode contrast)
  static const Color accent = Color(0xFF0099CC);
  static const Color accentGlow = Color(0x400099CC);
  static const Color secondary = Color(0xFF6B4EE6);
  static const Color success = Color(0xFF00B860);
  static const Color warning = Color(0xFFE69500);
  static const Color error = Color(0xFFE53935);

  // Text colors
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF4A4A6A);
  static const Color textMuted = Color(0xFF8A8AAA);

  // Power zone colors (same as dark mode)
  static const Color zoneRecovery = Color(0xFF4CAF50);
  static const Color zoneEndurance = Color(0xFF8BC34A);
  static const Color zoneTempo = Color(0xFFFFEB3B);
  static const Color zoneThreshold = Color(0xFFFF9800);
  static const Color zoneVO2Max = Color(0xFFF44336);
  static const Color zoneAnaerobic = Color(0xFF9C27B0);
}

/// App typography
class AppTypography {
  static TextStyle get displayLarge => GoogleFonts.inter(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -1,
      );

  static TextStyle get displayMedium => GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get headlineLarge => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineMedium => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleLarge => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleMedium => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 1.2,
      );

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
        letterSpacing: 1,
      );

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted, // Using textMuted as default for labels
        letterSpacing: 0.5,
      );

  /// Metric value style (large numbers)
  static TextStyle get metricValue => GoogleFonts.inter(
        fontSize: 42,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -1,
        height: 1,
      );

  /// Metric unit style
  static TextStyle get metricUnit => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
      );
}

/// App theme data
class AppTheme {
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.surfaceBorder, width: 1),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: AppTypography.titleLarge,
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.background,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: AppTypography.titleMedium.copyWith(
              color: AppColors.background,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accent,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            side: const BorderSide(color: AppColors.accent, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.accent,
          ),
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textSecondary,
          size: 24,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.surfaceBorder,
          thickness: 1,
        ),
      );

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColorsLight.background,
        colorScheme: const ColorScheme.light(
          primary: AppColorsLight.accent,
          secondary: AppColorsLight.secondary,
          surface: AppColorsLight.surface,
          error: AppColorsLight.error,
        ),
        cardTheme: CardThemeData(
          color: AppColorsLight.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColorsLight.surfaceBorder, width: 1),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColorsLight.background,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: AppTypography.titleLarge.copyWith(color: AppColorsLight.textPrimary),
          iconTheme: const IconThemeData(color: AppColorsLight.textPrimary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColorsLight.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: AppTypography.titleMedium.copyWith(
              color: Colors.white,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColorsLight.accent,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            side: const BorderSide(color: AppColorsLight.accent, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColorsLight.accent,
          ),
        ),
        iconTheme: const IconThemeData(
          color: AppColorsLight.textSecondary,
          size: 24,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColorsLight.surfaceBorder,
          thickness: 1,
        ),
      );
}
