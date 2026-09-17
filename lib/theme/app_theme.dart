import 'package:flutter/material.dart';

class AppColors {
  // Rich Warm Obsidian & Espresso palette
  static const Color background = Color(0xFF131211);
  static const Color surface = Color(0xFF1D1A17);
  static const Color surfaceElevated = Color(0xFF26231F);
  static const Color surfaceBorder = Color(0xFF38332C);
  static const Color surfaceHighlight = Color(0xFF484138);

  // Obsidian & Neutral Brand Tones (discarded orange)
  static const Color primary = Color(0xFF1E232A); // Deep Obsidian Slate
  static const Color primaryLight = Color(0xFF333A44);
  static const Color primaryDark = Color(0xFF111827);
  static const Color primaryContainer = Color(0xFFF5F2EB);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Harmonious Warm Accents
  static const Color accentGold = Color(0xFFD4A359);
  static const Color accentRose = Color(0xFF8A8F98);
  static const Color accentOlive = Color(0xFF81B29A);
  static const Color accentRed = Color(0xFFDC2626);

  // Warm Humanized Typography
  static const Color textPrimary = Color(0xFFFDFBF7); // Warm Ivory / Cream
  static const Color textSecondary = Color(0xFFB8B0A7); // Warm Stone Grey
  static const Color textMuted = Color(0xFF827A72); // Warm Subtle Grey

  // Warm Canvas & Sand Palette (from home.html & workout.html)
  static const Color canvas = Color(0xFFF7F4EE);
  static const Color sandCard = Color(0xFFFFFFFF);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color borderSubtle = Color(0xFFE5E1D8);
  static const Color inset = Color(0xFFF5F2EB);
  static const Color actionDark = Color(0xFF1E232A);
  static const Color carbon = Color(0xFF111827);
  static const Color stone = Color(0xFF57534E);
  static const Color trackRing = Color(0xFFEDE8DE);
  static const Color softCharcoal = Color(0xFF212529);
  static const Color darkButton = Color(0xFF181D23);
  static const Color mutedGray = Color(0xFF8A8F98);

  static const Color accentPeach = Color(0xFF1E232A);
  static const Color accentPeachLight = Color(0xFFF5F2EB);
  static const Color accentPeachText = Color(0xFF1E232A);

  static const Color accentSky = Color(0xFFBDDFEC);
  static const Color accentSkyDark = Color(0xFF3A7D99);
  static const Color accentSkyLight = Color(0xFFEAF4FA);
  static const Color accentSkyText = Color(0xFF2C7A9C);

  static const Color accentMint = Color(0xFFE4F4E8);
  static const Color accentMintText = Color(0xFF4CA467);
  static const Color accentMintCircle = Color(0xFF86EFAC);

  static const Color accentYellow = Color(0xFFFEF8E2);
  static const Color accentYellowText = Color(0xFFC99E25);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      fontFamily: 'Manrope',
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: AppColors.primary.withValues(alpha: 0.35),
        selectionHandleColor: AppColors.primary,
        cursorColor: AppColors.primary,
      ),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        secondary: AppColors.accentGold,
        error: AppColors.accentRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.surfaceBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.surfaceBorder, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        indicatorColor: AppColors.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 22);
          }
          return const IconThemeData(color: AppColors.textMuted, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            );
          }
          return const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 30,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
        titleMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 1.45,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w400,
          height: 1.45,
        ),
        labelLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
